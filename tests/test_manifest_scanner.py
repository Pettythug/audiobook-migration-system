#!/usr/bin/env python3
"""
Unit Tests for Multi-Heuristic pCloud Scanner
Verifies traversal, heuristics, folder-level majority rules, parent rollup,
and parser robustness (0-byte files, corrupted headers, missing headers).
"""

import os
import shutil
import tempfile
import unittest
from unittest.mock import patch

from src.manifest_scanner import (
    parse_id3_metadata,
    parse_mp3_duration,
    parse_mp4_duration,
    parse_wav_duration,
    classify_file,
    scan_directory,
    compute_rollup_manifest
)


class TestParserEdgeCases(unittest.TestCase):
    """
    Test edge cases for binary parsers to ensure robustness and no crashes.
    """

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def test_0_byte_file_parsers(self):
        """0-byte files should return 0 duration / empty metadata without crashing."""
        empty_file = os.path.join(self.temp_dir, "empty.mp3")
        with open(empty_file, "wb") as f:
            pass

        self.assertEqual(parse_mp3_duration(empty_file), 0)
        self.assertEqual(parse_mp4_duration(empty_file), 0)
        self.assertEqual(parse_wav_duration(empty_file), 0)
        self.assertEqual(parse_id3_metadata(empty_file), {"genre": None, "narrator": None})

    def test_corrupted_bytes_parsers(self):
        """Corrupted/random files should return 0 duration / empty metadata without crashing."""
        corrupt_file = os.path.join(self.temp_dir, "corrupt.mp3")
        with open(corrupt_file, "wb") as f:
            f.write(os.urandom(1024))  # 1 KB of random noise

        self.assertEqual(parse_mp3_duration(corrupt_file), 0)
        self.assertEqual(parse_mp4_duration(corrupt_file), 0)
        self.assertEqual(parse_wav_duration(corrupt_file), 0)
        self.assertEqual(parse_id3_metadata(corrupt_file), {"genre": None, "narrator": None})

    def test_missing_headers_parsers(self):
        """Files missing expected signatures/headers should return 0 duration / empty metadata."""
        no_header_file = os.path.join(self.temp_dir, "no_header.mp3")
        with open(no_header_file, "wb") as f:
            f.write(b"This is just normal text file content, not audio headers.")

        self.assertEqual(parse_mp3_duration(no_header_file), 0)
        self.assertEqual(parse_mp4_duration(no_header_file), 0)
        self.assertEqual(parse_wav_duration(no_header_file), 0)
        self.assertEqual(parse_id3_metadata(no_header_file), {"genre": None, "narrator": None})

    def test_valid_mocked_mp4_duration(self):
        """Valid MP4 mvhd atom structure should be parsed correctly."""
        mp4_file = os.path.join(self.temp_dir, "valid.m4b")
        # Construct raw bytes containing a version 0 mvhd atom
        # mvhd signature = b'mvhd'
        # version = 0 (1 byte)
        # flags = 3 bytes (0, 0, 0)
        # creation time = 4 bytes
        # modification time = 4 bytes
        # timescale = 1000 (4 bytes -> \x00\x00\x03\xe8)
        # duration = 5000 (4 bytes -> \x00\x00\x13\x88) -> 5 seconds
        timescale = (1000).to_bytes(4, 'big')
        duration = (5000).to_bytes(4, 'big')
        mvhd_payload = b"mvhd" + b"\x00" + b"\x00\x00\x00" + os.urandom(8) + timescale + duration
        
        with open(mp4_file, "wb") as f:
            f.write(os.urandom(100) + mvhd_payload + os.urandom(100))

        calculated_duration = parse_mp4_duration(mp4_file)
        self.assertEqual(calculated_duration, 5.0)


class TestClassificationHeuristics(unittest.TestCase):
    """
    Test file-level classification rules and priority.
    """

    def test_system_other_precedence(self):
        """System/Other path keywords take highest priority."""
        # Even if extension is .m4b and duration > 45 mins, if path has 'help' or 'assets', classify as System/Other
        res = classify_file("C:/Audio/assets/book.m4b", 5000, {"genre": "Audiobook", "narrator": "John"})
        self.assertEqual(res, "System/Other")

        # System genre keyword
        res = classify_file("C:/Audio/book.mp3", 50, {"genre": "System Alert", "narrator": None})
        self.assertEqual(res, "System/Other")

    def test_audiobook_heuristics(self):
        """Audiobook heuristics identify .m4b, long duration, and metadata tags."""
        # .m4b extension
        self.assertEqual(classify_file("book.m4b", 100, {}), "Audiobooks")
        # Duration > 45 mins (2700s)
        self.assertEqual(classify_file("book.mp3", 2701, {}), "Audiobooks")
        # Genre tag contains "audiobook"
        self.assertEqual(classify_file("book.mp3", 100, {"genre": "Audiobook"}), "Audiobooks")
        self.assertEqual(classify_file("book.mp3", 100, {"genre": "SF Audio Book"}), "Audiobooks")
        # Narrator metadata present
        self.assertEqual(classify_file("book.mp3", 100, {"narrator": "Jim Dale"}), "Audiobooks")

    def test_music_heuristics(self):
        """Music heuristics match path keywords and genre tags."""
        # Path containing music keyword
        self.assertEqual(classify_file("C:/Music/song.mp3", 100, {}), "Music")
        # Path containing playlist keyword
        self.assertEqual(classify_file("C:/MyPlaylists/song.mp3", 100, {}), "Music")
        # Genre tag is music-related
        self.assertEqual(classify_file("song.mp3", 100, {"genre": "Rock"}), "Music")
        self.assertEqual(classify_file("song.mp3", 100, {"genre": "Synthpop"}), "Music")

    def test_unknown_classification(self):
        """Standard file not matching any specific heuristic is Unknown."""
        self.assertEqual(classify_file("track.mp3", 100, {}), "Unknown")


class TestFolderMajorityRulesAndRollup(unittest.TestCase):
    """
    Test traversal, majority-rule folder overrides, and rollup logic.
    """

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        
        # Set up a mock directory structure:
        # temp_dir/
        #   Author1/
        #     Book1/
        #       chapter1.mp3  (Audiobook)
        #       chapter2.mp3  (Audiobook)
        #       cover.jpg     (Non-audio: ignored)
        #       track.mp3     (Unknown - should be converted to Audiobook by majority rule)
        #     Book2/
        #       CD1/
        #         part1.m4a   (Audiobook)
        #       CD2/
        #         part2.m4a   (Audiobook)
        #   MusicFolder/
        #     song1.mp3       (Music)
        #     song2.mp3       (Music)
        
        self.paths = {
            "chapter1": os.path.join(self.temp_dir, "Author1", "Book1", "chapter1.mp3"),
            "chapter2": os.path.join(self.temp_dir, "Author1", "Book1", "chapter2.mp3"),
            "track": os.path.join(self.temp_dir, "Author1", "Book1", "track.mp3"),
            "cover": os.path.join(self.temp_dir, "Author1", "Book1", "cover.jpg"),
            "part1": os.path.join(self.temp_dir, "Author1", "Book2", "CD1", "part1.m4a"),
            "part2": os.path.join(self.temp_dir, "Author1", "Book2", "CD2", "part2.m4a"),
            "song1": os.path.join(self.temp_dir, "MusicFolder", "song1.mp3"),
            "song2": os.path.join(self.temp_dir, "MusicFolder", "song2.mp3"),
        }
        
        # Create directories and mock 0-byte files
        for name, path in self.paths.items():
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "wb") as f:
                pass

    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    @patch("src.manifest_scanner.get_audio_info")
    def test_scan_directory_and_rollup(self, mock_get_info):
        """Verify traversal, folder-level majority overrides, and parent rollup logic."""
        
        # Mock get_audio_info to simulate durations and metadata
        def side_effect(file_path):
            norm_path = os.path.normpath(file_path)
            # Chapter 1 & 2 are Audiobooks (> 45 min)
            if "chapter1.mp3" in norm_path or "chapter2.mp3" in norm_path:
                return 3000, {"genre": None, "narrator": None}
            # Track is Unknown (short, no metadata)
            if "track.mp3" in norm_path:
                return 120, {"genre": None, "narrator": None}
            # Part 1 & 2 are Audiobooks (genre metadata)
            if "part1.m4a" in norm_path or "part2.m4a" in norm_path:
                return 100, {"genre": "Audiobook", "narrator": None}
            # Song 1 & 2 are Music
            if "song1.mp3" in norm_path or "song2.mp3" in norm_path:
                return 180, {"genre": "Pop", "narrator": None}
            return 0, {}
            
        mock_get_info.side_effect = side_effect

        # 1. Test scan_directory
        scanned = scan_directory(self.temp_dir)
        
        # Check that cover.jpg is NOT in scanned (non-audio file extension)
        self.assertNotIn(self.paths["cover"], scanned)
        
        # Check initial and final classifications of Book1 files
        # chapter1 & chapter2 are audiobook. track is unknown.
        # But in Book1 folder, 2 out of 3 audio files are audiobook (>50%).
        # Therefore, track should be overridden to Audiobook.
        self.assertEqual(scanned[self.paths["chapter1"]]["initial_class"], "Audiobooks")
        self.assertEqual(scanned[self.paths["chapter2"]]["initial_class"], "Audiobooks")
        self.assertEqual(scanned[self.paths["track"]]["initial_class"], "Unknown")
        
        self.assertEqual(scanned[self.paths["chapter1"]]["final_class"], "Audiobooks")
        self.assertEqual(scanned[self.paths["chapter2"]]["final_class"], "Audiobooks")
        self.assertEqual(scanned[self.paths["track"]]["final_class"], "Audiobooks")
        
        # Book2 CD1/CD2 files are audiobooks
        self.assertEqual(scanned[self.paths["part1"]]["final_class"], "Audiobooks")
        self.assertEqual(scanned[self.paths["part2"]]["final_class"], "Audiobooks")
        
        # MusicFolder files are music
        self.assertEqual(scanned[self.paths["song1"]]["final_class"], "Music")
        
        # 2. Test parent rollup manifest
        manifest = compute_rollup_manifest(scanned, self.temp_dir)
        
        # Let's inspect the manifest content
        # We expect:
        # - Book1 should roll up to Author1/Book1 (or Author1 since all descendants are Audiobooks)
        # - Book2 CD1 and CD2 should roll up to Author1/Book2 (since both contain audiobooks, and parent is Book2)
        # Wait, since Author1 contains only audiobook subdirectories, does Book1 and Book2 roll up to Author1?
        # Let's trace rollup for Book1 parent: Author1.
        # Author1 contains: Book1 (only Audiobooks), Book2 (only Audiobooks).
        # Does Author1 contain any Music or System/Other files? No.
        # So Book1 and Book2 will roll up all the way to Author1!
        # Thus, we should have a single rollup folder: Author1.
        # Total files under Author1: chapter1, chapter2, track, part1, part2 = 5 files.
        # Let's verify if Author1 is the highest common parent.
        
        # Wait, let's see if the music folder prevents rollup to the source_path.
        # Yes! The root directory contains MusicFolder (which has Music files), so rollup stops at Author1!
        # This is exactly the rollup logic we designed.
        
        self.assertEqual(len(manifest), 1)
        item = manifest[0]
        self.assertEqual(item["highest_common_parent"], os.path.join("Author1"))
        self.assertEqual(item["file_count"], 5)
        self.assertEqual(item["migration_decision"], "Migrate")


if __name__ == "__main__":
    unittest.main()
