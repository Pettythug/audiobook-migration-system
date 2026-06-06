#!/usr/bin/env python3
"""
Migration Validation & Reporter
Author: Brian Wance
Description: Reads the source (pCloud) manifest and target (Google Drive) manifest,
             compares folders based on normalized relative paths and total sizes,
             identifies failed copies, size mismatches, duplicates, or pre-existing folders,
             and outputs a CSV report and terminal summary.
"""

import os
import sys
import csv
import argparse


def normalize_path(path_str):
    """
    Normalizes path by standardizing slashes, removing drive letters, and stripping
    common parent folder names to extract the relative audiobook directory structure.
    """
    if not path_str:
        return ""
    
    # Replace backslashes with forward slashes, strip whitespace, and convert to lowercase
    p = path_str.replace('\\', '/').strip().lower()
    
    # Strip drive letters (e.g. "p:", "g:")
    if len(p) >= 2 and p[1] == ':':
        p = p[2:]
    p = p.strip('/')
    
    # Known root/prefix parts to strip from the beginning of the path
    prefixes = [
        'my drive/pcloud',
        'my drive',
        'pcloud',
        'drive e/books',
        'drive e',
        'drive g',
        'drive i',
        'renamed/not on phone',
        'renamed'
    ]
    
    changed = True
    while changed:
        changed = False
        for prefix in prefixes:
            if p.startswith(prefix + '/'):
                p = p[len(prefix) + 1:]
                changed = True
            elif p == prefix and prefix in ('my drive/pcloud', 'my drive', 'pcloud'):
                p = ""
                changed = True
                
    return p


def read_manifest(file_path):
    """
    Reads a manifest CSV file, returning a list of dicts.
    Handles potential file errors defensively.
    """
    rows = []
    if not os.path.exists(file_path):
        print(f"Warning: Manifest file '{file_path}' does not exist.", file=sys.stderr)
        return rows
        
    try:
        with open(file_path, mode='r', encoding='utf-8', newline='') as f:
            reader = csv.DictReader(f)
            # Ensure the required headers exist
            if not reader.fieldnames:
                return rows
            required = {'highest_common_parent', 'file_count', 'total_size_bytes'}
            if not required.issubset(set(reader.fieldnames)):
                print(f"Warning: Manifest '{file_path}' is missing required headers: {required - set(reader.fieldnames)}", file=sys.stderr)
                return rows
                
            for row in reader:
                rows.append({
                    'highest_common_parent': row.get('highest_common_parent', '').strip(),
                    'file_count': int(row.get('file_count', 0) or 0),
                    'total_size_bytes': int(row.get('total_size_bytes', 0) or 0),
                    'migration_decision': row.get('migration_decision', '').strip()
                })
    except Exception as e:
        print(f"Error reading manifest '{file_path}': {e}", file=sys.stderr)
        
    return rows


def get_default_path(filename):
    """
    Defensively resolves the path for default files, checking both current working
    directory and project root.
    """
    if os.path.exists(filename):
        return filename
    # Check one level up (if running from src/ or tests/)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    parent_path = os.path.abspath(os.path.join(script_dir, "..", filename))
    if os.path.exists(parent_path):
        return parent_path
    return filename


def validate_migration(source_manifest_path, target_manifest_path):
    """
    Performs the core comparison between source and target manifests.
    """
    source_rows = read_manifest(source_manifest_path)
    target_rows = read_manifest(target_manifest_path)
    
    # Group target entries by normalized path
    target_by_norm = {}
    for row in target_rows:
        norm = normalize_path(row['highest_common_parent'])
        target_by_norm.setdefault(norm, []).append(row)
        
    report_records = []
    
    # Keep track of target entries that matched a source entry
    matched_target_indices = set()
    
    # 1. Check source entries
    for s_row in source_rows:
        s_path = s_row['highest_common_parent']
        s_norm = normalize_path(s_path)
        s_size = s_row['total_size_bytes']
        s_files = s_row['file_count']
        
        t_matches = target_by_norm.get(s_norm, [])
        
        if not t_matches:
            # Failed to copy
            report_records.append({
                'source_path': s_path,
                'target_path': '',
                'normalized_path': s_norm,
                'status': 'MISSING',
                'source_size_bytes': s_size,
                'target_size_bytes': 0,
                'source_files': s_files,
                'target_files': 0,
                'details': 'Folder failed to copy: not found in Google Drive manifest.'
            })
        elif len(t_matches) == 1:
            t_row = t_matches[0]
            t_path = t_row['highest_common_parent']
            t_size = t_row['total_size_bytes']
            t_files = t_row['file_count']
            
            # Record match index/key to identify pre-existing/extra target folders later
            matched_target_indices.add(id(t_row))
            
            if s_size == t_size:
                report_records.append({
                    'source_path': s_path,
                    'target_path': t_path,
                    'normalized_path': s_norm,
                    'status': 'OK',
                    'source_size_bytes': s_size,
                    'target_size_bytes': t_size,
                    'source_files': s_files,
                    'target_files': t_files,
                    'details': 'Successfully migrated. Paths and sizes match.'
                })
            else:
                report_records.append({
                    'source_path': s_path,
                    'target_path': t_path,
                    'normalized_path': s_norm,
                    'status': 'SIZE_MISMATCH',
                    'source_size_bytes': s_size,
                    'target_size_bytes': t_size,
                    'source_files': s_files,
                    'target_files': t_files,
                    'details': f'Size mismatch: Source has {s_size} bytes ({s_files} files), Target has {t_size} bytes ({t_files} files).'
                })
        else:
            # Duplicate matches in target
            t_paths = [r['highest_common_parent'] for r in t_matches]
            details = f"Duplicate copies found in target locations: {', '.join(t_paths)}"
            
            for t_row in t_matches:
                matched_target_indices.add(id(t_row))
                
            report_records.append({
                'source_path': s_path,
                'target_path': t_matches[0]['highest_common_parent'],  # record primary
                'normalized_path': s_norm,
                'status': 'DUPLICATE',
                'source_size_bytes': s_size,
                'target_size_bytes': sum(r['total_size_bytes'] for r in t_matches),
                'source_files': s_files,
                'target_files': sum(r['file_count'] for r in t_matches),
                'details': details
            })
            
    # 2. Check for target entries that were not matched to any source entry (pre-existing / extra)
    for t_row in target_rows:
        if id(t_row) not in matched_target_indices:
            t_path = t_row['highest_common_parent']
            t_norm = normalize_path(t_path)
            t_size = t_row['total_size_bytes']
            t_files = t_row['file_count']
            
            report_records.append({
                'source_path': '',
                'target_path': t_path,
                'normalized_path': t_norm,
                'status': 'PRE_EXISTING',
                'source_size_bytes': 0,
                'target_size_bytes': t_size,
                'source_files': 0,
                'target_files': t_files,
                'details': 'Folder exists on target but is not present in source manifest.'
            })
            
    return report_records


def write_report(report_records, output_path):
    """
    Writes the validation report to a CSV file.
    """
    fieldnames = [
        'source_path',
        'target_path',
        'normalized_path',
        'status',
        'source_size_bytes',
        'target_size_bytes',
        'source_files',
        'target_files',
        'details'
    ]
    try:
        with open(output_path, mode='w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for record in report_records:
                writer.writerow(record)
        return True
    except Exception as e:
        print(f"Error writing report to '{output_path}': {e}", file=sys.stderr)
        return False


def print_summary(report_records, source_manifest, target_manifest, output_report_path):
    """
    Prints a clean, human-readable summary of validation results.
    """
    # Count statuses
    counts = {
        'OK': 0,
        'MISSING': 0,
        'SIZE_MISMATCH': 0,
        'DUPLICATE': 0,
        'PRE_EXISTING': 0
    }
    
    issues = []
    
    for r in report_records:
        status = r['status']
        if status in counts:
            counts[status] += 1
        if status != 'OK' and status != 'PRE_EXISTING':
            issues.append(r)
            
    print("\n" + "=" * 60)
    print("MIGRATION VALIDATION SUMMARY")
    print("=" * 60)
    print(f"Source Manifest: {source_manifest}")
    print(f"Target Manifest: {target_manifest}")
    print("-" * 60)
    print(f"Total Source Folders: {sum(1 for r in report_records if r['source_path'])}")
    print(f"Total Target Folders: {sum(1 for r in report_records if r['target_path'])}")
    print("-" * 60)
    print("Validation Status Breakdown:")
    print(f"  - OK (Matched):        {counts['OK']}")
    print(f"  - MISSING (Failed):    {counts['MISSING']}")
    print(f"  - SIZE_MISMATCH:       {counts['SIZE_MISMATCH']}")
    print(f"  - DUPLICATE (Target):  {counts['DUPLICATE']}")
    print(f"  - PRE_EXISTING (Extra):{counts['PRE_EXISTING']}")
    print("-" * 60)
    
    if issues:
        print("Issues Flagged:")
        for r in issues:
            path = r['source_path'] or r['target_path']
            print(f"  [{r['status']}] {path}")
            print(f"    Reason: {r['details']}")
        print("-" * 60)
        
    print(f"Report generated: {output_report_path}")
    print("=" * 60 + "\n")


def main():
    parser = argparse.ArgumentParser(description="Migration Validation & Reporter")
    parser.add_argument("--source", help="Path to source manifest CSV (default: pcloud_manifest.csv)")
    parser.add_argument("--target", help="Path to target manifest CSV (default: gdrive_pcloud_manifest.csv)")
    parser.add_argument("--output", help="Path to write the verification CSV report (default: migration_report.csv)")
    
    args = parser.parse_args()
    
    # Resolve default paths
    source_manifest = args.source or get_default_path("pcloud_manifest.csv")
    target_manifest = args.target or get_default_path("gdrive_pcloud_manifest.csv")
    output_report_path = args.output or "migration_report.csv"
    
    print(f"Reading source manifest: {source_manifest}")
    print(f"Reading target manifest: {target_manifest}")
    
    if not os.path.exists(source_manifest):
        print(f"Error: Source manifest file '{source_manifest}' does not exist.", file=sys.stderr)
        sys.exit(1)
        
    if not os.path.exists(target_manifest):
        print(f"Error: Target manifest file '{target_manifest}' does not exist.", file=sys.stderr)
        sys.exit(1)
        
    report = validate_migration(source_manifest, target_manifest)
    success = write_report(report, output_report_path)
    
    if success:
        print_summary(report, source_manifest, target_manifest, output_report_path)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
