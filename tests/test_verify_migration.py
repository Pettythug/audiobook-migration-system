#!/usr/bin/env python3
"""
Unit Tests for Migration Validation & Reporter
Verifies path normalization, manifest parsing, size matching, status flagging,
and CSV report generation.
"""

import os
import csv
import shutil
import tempfile
import unittest
from unittest.mock import patch

from src.verify_migration import (
    normalize_path,
    read_manifest,
    validate_migration,
    write_report,
    main
)


class TestPathNormalization(unittest.TestCase):
    """
    Tests the path normalization helper to ensure diverse directory formats map
    consistently across platforms.
    """

    def test_basic_normalization(self):
        self.assertEqual(normalize_path("P:\\Audio Books"), "audio books")
        self.assertEqual(normalize_path("Audio Books"), "audio books")
        self.assertEqual(normalize_path("Audio Books/"), "audio books")
        self.assertEqual(normalize_path("G:\\My Drive\\pcloud\\Audio Books"), "audio books")
        self.assertEqual(normalize_path("G:\\My Drive\\Audio Books"), "audio books")

    def test_nested_normalization(self):
        self.assertEqual(
            normalize_path("P:\\Audio Books\\Sci-Fi\\Dune"),
            "audio books/sci-fi/dune"
        )
        self.assertEqual(
            normalize_path("G:\\My Drive\\pcloud\\Audio Books\\Sci-Fi\\Dune"),
            "audio books/sci-fi/dune"
        )

    def test_renamed_prefixes(self):
        self.assertEqual(
            normalize_path("renamed\\Not On Phone\\Drew Hayes"),
            "drew hayes"
        )
        self.assertEqual(
            normalize_path("renamed\\Drew Hayes"),
            "drew hayes"
        )
        self.assertEqual(
            normalize_path("Drive E\\Books\\Books"),
            "books"
        )

    def test_drive_level_paths(self):
        # Should retain drive name if it's the only path part
        self.assertEqual(normalize_path("Drive G"), "drive g")
        self.assertEqual(normalize_path("Drive I"), "drive i")


class TestManifestReader(unittest.TestCase):
    """
    Tests manifest reading, checking for correct headers, type casting,
    and missing/empty files.
    """

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def test_valid_manifest_reading(self):
        manifest_path = os.path.join(self.temp_dir, "manifest.csv")
        with open(manifest_path, "w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["highest_common_parent", "file_count", "total_size_bytes", "migration_decision"])
            writer.writerow(["P:\\Audio Books\\Dune", "12", "12345678", "Migrate"])
            writer.writerow(["P:\\Audio Books\\Hobbit", "1", "987654", "Review"])

        rows = read_manifest(manifest_path)
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]["highest_common_parent"], "P:\\Audio Books\\Dune")
        self.assertEqual(rows[0]["file_count"], 12)
        self.assertEqual(rows[0]["total_size_bytes"], 12345678)
        self.assertEqual(rows[0]["migration_decision"], "Migrate")

    def test_invalid_headers(self):
        manifest_path = os.path.join(self.temp_dir, "bad_manifest.csv")
        with open(manifest_path, "w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["incorrect_header1", "incorrect_header2"])
            writer.writerow(["some_val1", "some_val2"])

        rows = read_manifest(manifest_path)
        self.assertEqual(len(rows), 0)

    def test_missing_file(self):
        rows = read_manifest(os.path.join(self.temp_dir, "nonexistent.csv"))
        self.assertEqual(len(rows), 0)


class TestValidationEngine(unittest.TestCase):
    """
    Tests the validation matching logic under all copy outcomes (OK, MISSING, SIZE_MISMATCH, DUPLICATE, PRE_EXISTING).
    """

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.source_path = os.path.join(self.temp_dir, "source.csv")
        self.target_path = os.path.join(self.temp_dir, "target.csv")

    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def write_csv(self, path, rows):
        with open(path, "w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["highest_common_parent", "file_count", "total_size_bytes", "migration_decision"])
            for row in rows:
                writer.writerow(row)

    def test_validation_outcomes(self):
        # 1. Source Manifest:
        # - Dune: Perfect match expected (OK)
        # - Hobbit: Size mismatch expected (SIZE_MISMATCH)
        # - Foundation: Missing expected (MISSING)
        # - Drew Hayes: Duplicate expected (DUPLICATE)
        source_data = [
            ["P:\\Audio Books\\Dune", 10, 1000, "Migrate"],
            ["P:\\Audio Books\\Hobbit", 1, 500, "Migrate"],
            ["P:\\Audio Books\\Foundation", 5, 2500, "Review"],
            ["P:\\Drew Hayes", 20, 2000, "Migrate"]
        ]
        
        # 2. Target Manifest:
        # - Dune: Size matches
        # - Hobbit: Size differs
        # - Drew Hayes: Exists in duplicate locations
        # - Extra Book: Not in source (PRE_EXISTING)
        target_data = [
            ["G:\\My Drive\\pcloud\\Audio Books\\Dune", 10, 1000, "Migrate"],
            ["G:\\My Drive\\pcloud\\Audio Books\\Hobbit", 1, 400, "Migrate"],
            ["renamed\\Drew Hayes", 20, 2000, "Migrate"],
            ["renamed\\Not On Phone\\Drew Hayes", 20, 2000, "Migrate"],
            ["Drive G\\Extra Book", 5, 800, "Migrate"]
        ]
        
        self.write_csv(self.source_path, source_data)
        self.write_csv(self.target_path, target_data)

        report = validate_migration(self.source_path, self.target_path)
        
        # We expect 5 total entries in the report (4 source entries + 1 pre-existing target entry)
        self.assertEqual(len(report), 5)
        
        # Index status and details mapping
        status_map = {r["normalized_path"]: r for r in report}
        
        # Dune should be OK
        self.assertIn("audio books/dune", status_map)
        self.assertEqual(status_map["audio books/dune"]["status"], "OK")
        self.assertEqual(status_map["audio books/dune"]["source_size_bytes"], 1000)
        self.assertEqual(status_map["audio books/dune"]["target_size_bytes"], 1000)
        
        # Hobbit should be SIZE_MISMATCH
        self.assertIn("audio books/hobbit", status_map)
        self.assertEqual(status_map["audio books/hobbit"]["status"], "SIZE_MISMATCH")
        self.assertEqual(status_map["audio books/hobbit"]["source_size_bytes"], 500)
        self.assertEqual(status_map["audio books/hobbit"]["target_size_bytes"], 400)
        
        # Foundation should be MISSING
        self.assertIn("audio books/foundation", status_map)
        self.assertEqual(status_map["audio books/foundation"]["status"], "MISSING")
        self.assertEqual(status_map["audio books/foundation"]["source_size_bytes"], 2500)
        self.assertEqual(status_map["audio books/foundation"]["target_size_bytes"], 0)

        # Drew Hayes should be DUPLICATE
        self.assertIn("drew hayes", status_map)
        self.assertEqual(status_map["drew hayes"]["status"], "DUPLICATE")
        
        # Extra Book should be PRE_EXISTING
        # "Drive G\\Extra Book" -> normalized to "extra book" because "drive g" is stripped
        self.assertIn("extra book", status_map)
        self.assertEqual(status_map["extra book"]["status"], "PRE_EXISTING")
        self.assertEqual(status_map["extra book"]["source_size_bytes"], 0)
        self.assertEqual(status_map["extra book"]["target_size_bytes"], 800)


class TestReportWriter(unittest.TestCase):
    """
    Tests generating the CSV verification report file correctly.
    """

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def test_write_report(self):
        report_path = os.path.join(self.temp_dir, "migration_report.csv")
        records = [{
            'source_path': 'P:\\Audio Books\\Dune',
            'target_path': 'G:\\My Drive\\pcloud\\Audio Books\\Dune',
            'normalized_path': 'audio books/dune',
            'status': 'OK',
            'source_size_bytes': 1000,
            'target_size_bytes': 1000,
            'source_files': 10,
            'target_files': 10,
            'details': 'Match'
        }]

        success = write_report(records, report_path)
        self.assertTrue(success)
        self.assertTrue(os.path.exists(report_path))

        # Read back and verify
        with open(report_path, mode='r', encoding='utf-8', newline='') as f:
            reader = csv.DictReader(f)
            rows = list(reader)
            self.assertEqual(len(rows), 1)
            self.assertEqual(rows[0]['status'], 'OK')
            self.assertEqual(rows[0]['normalized_path'], 'audio books/dune')


class TestCLIIntegration(unittest.TestCase):
    """
    End-to-end test of the verify_migration script CLI using patched arguments.
    """

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.source_path = os.path.join(self.temp_dir, "source.csv")
        self.target_path = os.path.join(self.temp_dir, "target.csv")
        self.report_path = os.path.join(self.temp_dir, "report.csv")

        # Create basic manifests
        with open(self.source_path, "w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["highest_common_parent", "file_count", "total_size_bytes", "migration_decision"])
            writer.writerow(["P:\\Audio Books\\Dune", "10", "1000", "Migrate"])
            
        with open(self.target_path, "w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["highest_common_parent", "file_count", "total_size_bytes", "migration_decision"])
            writer.writerow(["G:\\My Drive\\pcloud\\Audio Books\\Dune", "10", "1000", "Migrate"])

    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def test_cli_execution(self):
        test_args = [
            "verify_migration.py",
            "--source", self.source_path,
            "--target", self.target_path,
            "--output", self.report_path
        ]
        with patch('sys.argv', test_args):
            try:
                main()
            except SystemExit as e:
                self.assertEqual(e.code, 0)
        self.assertTrue(os.path.exists(self.report_path))


if __name__ == "__main__":
    unittest.main()
