#!/usr/bin/env python3
"""
Multi-Heuristic pCloud Scanner
Author: Brian Wance
Description: Recursively scans a source folder to identify and classify audio files into
             Audiobooks, Music, System/Other, and Unknown categories using multiple heuristics,
             folder majority rules, and parent folder rollups.
"""

import os
import sys
import csv
import argparse
import wave

# Supported audio extensions
AUDIO_EXTENSIONS = {'.mp3', '.m4a', '.m4b', '.wav', '.flac', '.ogg', '.aac', '.wma'}


def decode_text(data, encoding):
    """
    Decodes binary data using the specified ID3 encoding byte.
    """
    try:
        if encoding == 0:
            return data.decode("latin1", errors="replace").strip()
        elif encoding == 1:
            return data.decode("utf-16", errors="replace").strip()
        elif encoding == 2:
            return data.decode("utf-16-be", errors="replace").strip()
        elif encoding == 3:
            return data.decode("utf-8", errors="replace").strip()
    except Exception:
        pass
    return data.decode("utf-8", errors="replace").strip()


def decode_text_frame(frame_data):
    """
    Decodes a standard ID3v2 text frame.
    """
    if not frame_data:
        return None
    encoding = frame_data[0]
    return decode_text(frame_data[1:], encoding)


def parse_id3_metadata(file_path):
    """
    Defensively parses ID3v2 tags from an MP3 file to extract genre and narrator.
    """
    metadata = {"genre": None, "narrator": None}
    try:
        if not os.path.exists(file_path) or os.path.getsize(file_path) == 0:
            return metadata

        with open(file_path, "rb") as f:
            header = f.read(10)
            if len(header) < 10 or header[:3] != b"ID3":
                return metadata
            
            version_major = header[3]
            size_bytes = header[6:10]
            tag_size = ((size_bytes[0] & 0x7f) << 21) | \
                       ((size_bytes[1] & 0x7f) << 14) | \
                       ((size_bytes[2] & 0x7f) << 7) | \
                       (size_bytes[3] & 0x7f)
            
            body = f.read(tag_size)
            offset = 0
            
            # Support ID3v2.3 and ID3v2.4 frame parsing (4-byte frame ID, 4-byte size, 2-byte flags)
            if version_major in (3, 4):
                while offset + 10 <= len(body):
                    frame_id = body[offset:offset+4]
                    if frame_id[0] == 0:  # Padding hit
                        break
                    
                    try:
                        frame_id_str = frame_id.decode('ascii', errors='ignore')
                    except Exception:
                        break
                    
                    fs_bytes = body[offset+4:offset+8]
                    if version_major == 3:
                        frame_size = int.from_bytes(fs_bytes, 'big')
                    else:  # ID3v2.4 synchsafe frame size
                        frame_size = ((fs_bytes[0] & 0x7f) << 21) | \
                                     ((fs_bytes[1] & 0x7f) << 14) | \
                                     ((fs_bytes[2] & 0x7f) << 7) | \
                                     (fs_bytes[3] & 0x7f)
                    
                    frame_data = body[offset+10 : offset+10+frame_size]
                    offset += 10 + frame_size
                    
                    if len(frame_data) < frame_size:
                        break
                    
                    if frame_id_str == "TCON":
                        genre = decode_text_frame(frame_data)
                        if genre:
                            metadata["genre"] = genre
                    elif frame_id_str == "TXXX":
                        if len(frame_data) > 1:
                            encoding = frame_data[0]
                            parts = frame_data[1:].split(b'\x00', 1)
                            if len(parts) == 2:
                                desc = decode_text(parts[0], encoding)
                                val = decode_text(parts[1], encoding)
                                if desc.lower() == "narrator":
                                    metadata["narrator"] = val
    except Exception as e:
        print(f"Warning: Failed to parse ID3 tags for {file_path}: {e}", file=sys.stderr)
    return metadata


def parse_mp4_duration(file_path):
    """
    Defensively searches for the 'mvhd' atom in an MP4/M4A/M4B file to extract duration.
    """
    try:
        if not os.path.exists(file_path) or os.path.getsize(file_path) == 0:
            return 0

        with open(file_path, "rb") as f:
            # Read first 10MB chunk for scanning mvhd
            data = f.read(10 * 1024 * 1024)
            idx = data.find(b"mvhd")
            if idx == -1:
                return 0
            
            # version is 1 byte at idx+4
            version = data[idx+4]
            if version == 0:
                timescale_offset = idx + 16
                timescale = int.from_bytes(data[timescale_offset : timescale_offset+4], "big")
                duration = int.from_bytes(data[timescale_offset+4 : timescale_offset+8], "big")
            elif version == 1:
                timescale_offset = idx + 24
                timescale = int.from_bytes(data[timescale_offset : timescale_offset+4], "big")
                duration = int.from_bytes(data[timescale_offset+4 : timescale_offset+12], "big")
            else:
                return 0
            
            if timescale > 0:
                return duration / timescale
    except Exception as e:
        print(f"Warning: Failed to parse MP4 duration for {file_path}: {e}", file=sys.stderr)
    return 0


def parse_mp3_duration(file_path):
    """
    Defensively parses MP3 headers, handling ID3 tags, Xing/Info/VBRI headers, and CBR estimation.
    """
    try:
        if not os.path.exists(file_path) or os.path.getsize(file_path) == 0:
            return 0

        file_size = os.path.getsize(file_path)
        with open(file_path, "rb") as f:
            header = f.read(10)
            id3_size = 0
            if len(header) == 10 and header[:3] == b"ID3":
                size_bytes = header[6:10]
                id3_size = ((size_bytes[0] & 0x7f) << 21) | \
                           ((size_bytes[1] & 0x7f) << 14) | \
                           ((size_bytes[2] & 0x7f) << 7) | \
                           (size_bytes[3] & 0x7f)
                f.seek(10 + id3_size)
            else:
                f.seek(0)
            
            buffer = f.read(64 * 1024)
            offset = 0
            while offset + 4 <= len(buffer):
                if buffer[offset] == 0xFF and (buffer[offset+1] & 0xE0) == 0xE0:
                    header_int = int.from_bytes(buffer[offset : offset+4], "big")
                    version_bits = (header_int >> 19) & 3
                    layer_bits = (header_int >> 17) & 3
                    bitrate_bits = (header_int >> 12) & 15
                    sr_bits = (header_int >> 10) & 3
                    
                    if version_bits == 3:
                        version = 1
                    elif version_bits == 2:
                        version = 2
                    elif version_bits == 0:
                        version = 2.5
                    else:
                        offset += 1
                        continue
                    
                    if layer_bits == 1:
                        layer = 3
                    else:
                        offset += 1
                        continue
                    
                    bitrates_v1_l3 = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0]
                    bitrates_v2_l3 = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0]
                    
                    if version == 1:
                        bitrate = bitrates_v1_l3[bitrate_bits] * 1000
                    else:
                        bitrate = bitrates_v2_l3[bitrate_bits] * 1000
                        
                    sr_v1 = [44100, 48000, 32000, 0]
                    sr_v2 = [22050, 24000, 16000, 0]
                    sr_v25 = [11025, 12000, 8000, 0]
                    
                    if version == 1:
                        sample_rate = sr_v1[sr_bits]
                    elif version == 2:
                        sample_rate = sr_v2[sr_bits]
                    else:
                        sample_rate = sr_v25[sr_bits]
                        
                    if bitrate == 0 or sample_rate == 0:
                        offset += 1
                        continue
                        
                    frame_data = buffer[offset : offset + 200]
                    xing_idx = frame_data.find(b"Xing")
                    if xing_idx == -1:
                        xing_idx = frame_data.find(b"Info")
                    
                    if xing_idx != -1:
                        flags_offset = xing_idx + 4
                        if flags_offset + 8 <= len(frame_data):
                            flags = int.from_bytes(frame_data[flags_offset : flags_offset+4], "big")
                            if flags & 1:
                                num_frames = int.from_bytes(frame_data[flags_offset+4 : flags_offset+8], "big")
                                samples_per_frame = 1152 if version == 1 else 576
                                return num_frames * samples_per_frame / sample_rate
                                
                    vbri_idx = frame_data.find(b"VBRI")
                    if vbri_idx != -1:
                        frames_offset = vbri_idx + 14
                        if frames_offset + 4 <= len(frame_data):
                            num_frames = int.from_bytes(frame_data[frames_offset : frames_offset+4], "big")
                            return num_frames * 1152 / sample_rate
                    
                    remaining_bytes = file_size - (10 + id3_size)
                    return remaining_bytes * 8 / bitrate
                offset += 1
    except Exception as e:
        print(f"Warning: Failed to parse MP3 duration for {file_path}: {e}", file=sys.stderr)
    return 0


def parse_wav_duration(file_path):
    """
    Defensively parses WAV duration using the standard library wave module.
    """
    try:
        if not os.path.exists(file_path) or os.path.getsize(file_path) == 0:
            return 0
        with wave.open(file_path, 'rb') as w:
            frames = w.getnframes()
            rate = w.getframerate()
            if rate > 0:
                return frames / rate
    except Exception as e:
        print(f"Warning: Failed to parse WAV duration for {file_path}: {e}", file=sys.stderr)
    return 0


def get_audio_info(file_path):
    """
    Retrieves duration and metadata for an audio file.
    """
    ext = os.path.splitext(file_path)[1].lower()
    duration = 0
    metadata = {"genre": None, "narrator": None}
    
    if ext == ".mp3":
        metadata = parse_id3_metadata(file_path)
        duration = parse_mp3_duration(file_path)
    elif ext in (".m4a", ".m4b"):
        metadata = parse_id3_metadata(file_path)  # Try ID3 anyway
        duration = parse_mp4_duration(file_path)
    elif ext == ".wav":
        duration = parse_wav_duration(file_path)
        
    return duration, metadata


def classify_file(file_path, duration, metadata):
    """
    Classifies a single file based on multi-heuristic rules in a specific precedence order.
    """
    ext = os.path.splitext(file_path)[1].lower()
    path_lower = file_path.lower()
    
    genre = metadata.get("genre")
    genre_lower = genre.lower() if genre else ""
    narrator = metadata.get("narrator")
    
    # 1. System/Other Heuristic (highest precedence)
    system_path_keywords = {"assets", "help", "system"}
    system_genre_keywords = {"system", "alert", "notification"}
    
    if any(kw in path_lower for kw in system_path_keywords) or any(kw in genre_lower for kw in system_genre_keywords):
        return "System/Other"
        
    # 2. Audiobook Heuristic
    is_audiobook = False
    if ext == ".m4b":
        is_audiobook = True
    elif duration > 2700:  # > 45 minutes
        is_audiobook = True
    elif "audiobook" in genre_lower or "audio book" in genre_lower:
        is_audiobook = True
    elif narrator and narrator.strip():
        is_audiobook = True
        
    if is_audiobook:
        return "Audiobooks"
        
    # 3. Music Heuristic
    music_path_keywords = {"music", "playlist", "artist"}
    music_genre_keywords = {"music", "pop", "rock", "jazz", "classical", "soundtrack", "metal", "rap", "hip hop", "r&b"}
    
    if any(kw in path_lower for kw in music_path_keywords) or any(kw in genre_lower for kw in music_genre_keywords):
        return "Music"
        
    # 4. Unknown
    return "Unknown"


def scan_directory(source_path):
    """
    Traverses the directory, collects audio files, classifies them, and applies majority rules.
    """
    scanned_files = {}
    
    # 1. Recursive Traversal
    for root, _, files in os.walk(source_path):
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in AUDIO_EXTENSIONS:
                full_path = os.path.join(root, file)
                try:
                    size = os.path.getsize(full_path)
                except Exception:
                    size = 0
                
                duration, metadata = get_audio_info(full_path)
                initial_class = classify_file(full_path, duration, metadata)
                
                scanned_files[full_path] = {
                    "size": size,
                    "duration": duration,
                    "genre": metadata.get("genre"),
                    "narrator": metadata.get("narrator"),
                    "initial_class": initial_class,
                    "final_class": initial_class
                }
                
    # 2. Group by folder for folder-level majority rules
    folders = {}
    for file_path, info in scanned_files.items():
        folder = os.path.dirname(file_path)
        folders.setdefault(folder, []).append(file_path)
        
    for folder, file_paths in folders.items():
        total_audio = len(file_paths)
        audiobook_count = sum(1 for fp in file_paths if scanned_files[fp]["initial_class"] == "Audiobooks")
        
        if total_audio > 0 and audiobook_count > (total_audio / 2.0):
            # Override all files in this folder to Audiobook
            for fp in file_paths:
                scanned_files[fp]["final_class"] = "Audiobooks"
                
    return scanned_files


def compute_rollup_manifest(scanned_files, source_path):
    """
    Identifies the highest common parent folder for each audiobook cluster.
    """
    # Find all directories containing at least one audiobook
    audiobook_folders = set()
    for file_path, info in scanned_files.items():
        if info["final_class"] == "Audiobooks":
            audiobook_folders.add(os.path.dirname(file_path))
            
    # For each folder, find the highest parent that contains no Music/System files
    folder_to_rollup = {}
    for folder in audiobook_folders:
        p = folder
        while p != source_path:
            parent = os.path.dirname(p)
            if parent == p or not parent.startswith(source_path):
                break
            
            # Check if parent contains any Music/System files under its tree
            has_mixed_content = False
            for fp, info in scanned_files.items():
                if info["final_class"] in ("Music", "System/Other") and fp.startswith(parent):
                    has_mixed_content = True
                    break
            
            if has_mixed_content:
                break
            p = parent
        folder_to_rollup[folder] = p
        
    # Group audiobook files by their rollup folder
    rollup_groups = {}
    for file_path, info in scanned_files.items():
        if info["final_class"] == "Audiobooks":
            orig_folder = os.path.dirname(file_path)
            rollup_p = folder_to_rollup[orig_folder]
            rollup_groups.setdefault(rollup_p, []).append(file_path)
            
    # Formulate rows
    manifest_rows = []
    for rollup_path, file_paths in rollup_groups.items():
        file_count = len(file_paths)
        total_size = sum(scanned_files[fp]["size"] for fp in file_paths)
        
        # Decide migration status: "Review" if there are any non-audiobook audio files under this rollup path
        has_other_audio = False
        for fp, info in scanned_files.items():
            if info["final_class"] != "Audiobooks" and fp.startswith(rollup_path):
                has_other_audio = True
                break
                
        decision = "Review" if has_other_audio else "Migrate"
        
        # Get relative path for clean reporting
        rel_rollup_path = os.path.relpath(rollup_path, source_path)
        if rel_rollup_path == ".":
            rel_rollup_path = rollup_path
            
        manifest_rows.append({
            "highest_common_parent": rel_rollup_path,
            "file_count": file_count,
            "total_size_bytes": total_size,
            "migration_decision": decision
        })
        
    return manifest_rows


def main():
    parser = argparse.ArgumentParser(description="Multi-Heuristic pCloud Scanner")
    parser.add_argument("--source-path", required=True, help="Standard local path to scan")
    parser.add_argument("--output-csv", help="Optional output path to export the CSV manifest")
    args = parser.parse_args()
    
    source = os.path.abspath(args.source_path)
    if not os.path.isdir(source):
        print(f"Error: Source directory '{source}' does not exist or is not a directory.", file=sys.stderr)
        sys.exit(1)
        
    print(f"Scanning source path: {source}...")
    scanned = scan_directory(source)
    
    # Calculate rollup manifest
    manifest = compute_rollup_manifest(scanned, source)
    
    # Always display candidates in console
    print("\n--- Candidate Audiobook Folders ---")
    if not manifest:
        print("No audiobook folders detected.")
    else:
        for item in manifest:
            print(f"Folder: {item['highest_common_parent']}")
            print(f"  Files: {item['file_count']}")
            print(f"  Size: {item['total_size_bytes']} bytes")
            print(f"  Decision: {item['migration_decision']}")
            print("-" * 40)
            
    # Write CSV if requested
    if args.output_csv:
        output_file = args.output_csv
        try:
            with open(output_file, "w", newline="", encoding="utf-8") as csvfile:
                fieldnames = ["highest_common_parent", "file_count", "total_size_bytes", "migration_decision"]
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                for row in manifest:
                    writer.writerow(row)
            print(f"\nManifest successfully written to: {output_file}")
        except Exception as e:
            print(f"Error writing CSV file: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print("\nDry-run mode complete. No files written. Use --output-csv to save results.")


if __name__ == "__main__":
    main()
