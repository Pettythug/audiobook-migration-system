#!/usr/bin/env python3
"""
Verified Audiobook Staging & Rollback
Author: Brian Wance
Description: Safely moves verified audiobook folders to a staging area with full transactional rollback support.
"""

import os
import sys
import csv
import json
import argparse
import shutil

def get_default_path(filename):
    if os.path.exists(filename):
        return filename
    script_dir = os.path.dirname(os.path.abspath(__file__))
    parent_path = os.path.abspath(os.path.join(script_dir, "..", filename))
    if os.path.exists(parent_path):
        return parent_path
    return filename

def read_migration_report(report_path):
    ok_paths = set()
    if not os.path.exists(report_path):
        print(f"Warning: Manifest file '{report_path}' does not exist.", file=sys.stderr)
        return ok_paths
    
    try:
        with open(report_path, mode='r', encoding='utf-8', newline='') as f:
            reader = csv.DictReader(f)
            if not reader.fieldnames:
                return ok_paths
            required = {'source_path', 'status'}
            if not required.issubset(set(reader.fieldnames)):
                print(f"Warning: Manifest '{report_path}' is missing required headers.", file=sys.stderr)
                return ok_paths
                
            for row in reader:
                if row.get('status', '').strip() == 'OK':
                    path = row.get('source_path', '').strip()
                    if path:
                        ok_paths.add(path)
    except Exception as e:
        print(f"Error reading manifest '{report_path}': {e}", file=sys.stderr)
        
    return ok_paths

def is_folder_empty(folder_path):
    if not os.path.isdir(folder_path):
        return False
    return len(os.listdir(folder_path)) == 0

def safe_print(msg):
    try:
        print(msg.encode(sys.stdout.encoding or 'utf-8', errors='replace').decode(sys.stdout.encoding or 'utf-8'), flush=True)
    except Exception:
        print(msg, flush=True)

def stage_verified_folders(source_dir, staging_dir, empty_dir, verified_paths, dry_run, log_file):
    transaction_log = []
    
    if not dry_run:
        os.makedirs(staging_dir, exist_ok=True)
        os.makedirs(empty_dir, exist_ok=True)
    
    for rel_path in verified_paths:
        src_path = os.path.join(source_dir, rel_path)
        
        if not os.path.exists(src_path):
            safe_print(f"Warning: Verified path '{src_path}' does not exist. Skipping.")
            continue
            
        if os.path.isfile(src_path):
            dst_path = os.path.join(staging_dir, rel_path)
            if dry_run:
                safe_print(f"[DRY-RUN] Move File: {src_path} -> {dst_path}")
            else:
                os.makedirs(os.path.dirname(dst_path), exist_ok=True)
                shutil.move(src_path, dst_path)
                transaction_log.append({"type": "file", "src": src_path, "dst": dst_path})
                safe_print(f"Moved File: {src_path} -> {dst_path}")
        else:
            for root, dirs, files in os.walk(src_path, topdown=False):
                for file in files:
                    f_src = os.path.join(root, file)
                    rel_f = os.path.relpath(f_src, source_dir)
                    f_dst = os.path.join(staging_dir, rel_f)
                    
                    if dry_run:
                        safe_print(f"[DRY-RUN] Move File: {f_src} -> {f_dst}")
                    else:
                        os.makedirs(os.path.dirname(f_dst), exist_ok=True)
                        shutil.move(f_src, f_dst)
                        transaction_log.append({"type": "file", "src": f_src, "dst": f_dst})
                        safe_print(f"Moved File: {f_src} -> {f_dst}")
                        
                # After moving files, check if root is empty
                is_empty = dry_run or is_folder_empty(root)
                if is_empty:
                    rel_root = os.path.relpath(root, source_dir)
                    root_dst = os.path.join(empty_dir, rel_root)
                    if dry_run:
                        safe_print(f"[DRY-RUN] Move Empty Folder: {root} -> {root_dst}")
                    else:
                        os.makedirs(os.path.dirname(root_dst), exist_ok=True)
                        shutil.move(root, root_dst)
                        transaction_log.append({"type": "empty_folder", "src": root, "dst": root_dst})
                        safe_print(f"Moved Empty Folder: {root} -> {root_dst}")

    if not dry_run and transaction_log:
        try:
            with open(log_file, "w", encoding="utf-8") as f:
                json.dump(transaction_log, f, indent=4)
            safe_print(f"\nTransaction log saved to: {log_file}")
        except Exception as e:
            print(f"Error saving transaction log to '{log_file}': {e}", file=sys.stderr)

def rollback_transaction(log_path, dry_run):
    if not os.path.exists(log_path):
        print(f"Error: Rollback log file '{log_path}' not found.", file=sys.stderr)
        return
        
    try:
        with open(log_path, "r", encoding="utf-8") as f:
            transaction_log = json.load(f)
    except Exception as e:
        print(f"Error reading rollback log '{log_path}': {e}", file=sys.stderr)
        return
        
    dirs_to_clean = set()
    
    for op in reversed(transaction_log):
        src = op.get("src")
        dst = op.get("dst")
        
        if not src or not dst:
            continue
            
        if not os.path.exists(dst):
            safe_print(f"Warning: Item to rollback '{dst}' not found. Skipping.")
            continue
            
        if dry_run:
            safe_print(f"[DRY-RUN] Rollback: {dst} -> {src}")
        else:
            os.makedirs(os.path.dirname(src), exist_ok=True)
            shutil.move(dst, src)
            safe_print(f"Rollback: {dst} -> {src}")
            dirs_to_clean.add(os.path.dirname(dst))

    if not dry_run:
        # Sort directories by length descending to process deepest directories first
        sorted_dirs = sorted(list(dirs_to_clean), key=len, reverse=True)
        for d in sorted_dirs:
            curr = d
            while curr and os.path.isdir(curr) and is_folder_empty(curr):
                try:
                    os.rmdir(curr)
                    curr = os.path.dirname(curr)
                except OSError:
                    break

def main():
    parser = argparse.ArgumentParser(description="Verified Audiobook Staging & Rollback")
    parser.add_argument("--report", help="Path to migration_report.csv")
    parser.add_argument("--source-dir", help="Base path of the source directory")
    parser.add_argument("--staging-dir", help="Base path where verified folders will be staged")
    parser.add_argument("--empty-dir", help="Base path where empty folders will be isolated")
    parser.add_argument("--execute", action="store_true", help="Execute the move operations (default is dry-run)")
    parser.add_argument("--rollback", help="Path to a JSON log file to perform a rollback")
    parser.add_argument("--log-file", help="Path to save the transaction log (default: migration_rollback_log.json)")
    
    args = parser.parse_args()
    
    dry_run = not args.execute
    
    if args.rollback:
        safe_print(f"Starting Rollback using log: {args.rollback}")
        if dry_run:
            safe_print("=== DRY-RUN MODE (No files will be moved) ===")
        rollback_transaction(args.rollback, dry_run)
        return
        
    if not args.source_dir or not args.staging_dir or not args.empty_dir:
        print("Error: --source-dir, --staging-dir, and --empty-dir are required for staging.", file=sys.stderr)
        sys.exit(1)
        
    report_path = args.report or get_default_path("migration_report.csv")
    log_file = args.log_file or get_default_path("migration_rollback_log.json")
    
    verified_paths = read_migration_report(report_path)
    if not verified_paths:
        safe_print("No verified 'OK' paths found in the report.")
        return
        
    safe_print(f"Starting Staging from {args.source_dir} to {args.staging_dir}")
    if dry_run:
        safe_print("=== DRY-RUN MODE (No files will be moved) ===")
        
    stage_verified_folders(args.source_dir, args.staging_dir, args.empty_dir, verified_paths, dry_run, log_file)

if __name__ == "__main__":
    main()
