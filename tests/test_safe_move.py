import os
import unittest
import json
import shutil
import tempfile
import sys
from io import StringIO

# Add src to sys.path so we can import safe_move
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))
import safe_move

class TestSafeMove(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.source_dir = os.path.join(self.test_dir, "source")
        self.staging_dir = os.path.join(self.test_dir, "staging")
        self.empty_dir = os.path.join(self.test_dir, "empty")
        self.report_path = os.path.join(self.test_dir, "migration_report.csv")
        self.log_path = os.path.join(self.test_dir, "migration_rollback_log.json")
        
        os.makedirs(self.source_dir)
        
        # Create some mock folders and files
        self.ok_folder = os.path.join(self.source_dir, "Author", "Book_OK")
        os.makedirs(self.ok_folder)
        open(os.path.join(self.ok_folder, "part1.mp3"), "w").close()
        
        self.empty_ok_folder = os.path.join(self.source_dir, "Author", "Empty_Book")
        os.makedirs(self.empty_ok_folder)
        
        self.fail_folder = os.path.join(self.source_dir, "Author", "Book_FAIL")
        os.makedirs(self.fail_folder)
        open(os.path.join(self.fail_folder, "part2.mp3"), "w").close()
        
        # Write mock report
        with open(self.report_path, "w", newline="", encoding="utf-8") as f:
            f.write("source_path,status\n")
            f.write("Author/Book_OK,OK\n")
            f.write("Author/Empty_Book,OK\n")
            f.write("Author/Book_FAIL,SIZE_MISMATCH\n")
            
        # Suppress prints during test
        self.held_stdout = sys.stdout
        sys.stdout = StringIO()
        
    def tearDown(self):
        sys.stdout = self.held_stdout
        shutil.rmtree(self.test_dir)

    def test_dry_run_mode(self):
        paths = safe_move.read_migration_report(self.report_path)
        safe_move.stage_verified_folders(
            self.source_dir, self.staging_dir, self.empty_dir, paths, dry_run=True, log_file=self.log_path
        )
        # Verify nothing moved
        self.assertTrue(os.path.exists(os.path.join(self.ok_folder, "part1.mp3")))
        self.assertFalse(os.path.exists(self.staging_dir))
        self.assertFalse(os.path.exists(self.empty_dir))
        self.assertFalse(os.path.exists(self.log_path))

    def test_execute_verified_move_and_empty_folder_isolation(self):
        paths = safe_move.read_migration_report(self.report_path)
        safe_move.stage_verified_folders(
            self.source_dir, self.staging_dir, self.empty_dir, paths, dry_run=False, log_file=self.log_path
        )
        
        # Verify file moved to staging
        self.assertTrue(os.path.exists(os.path.join(self.staging_dir, "Author", "Book_OK", "part1.mp3")))
        self.assertFalse(os.path.exists(os.path.join(self.ok_folder, "part1.mp3")))
        
        # Verify empty folders moved to empty_dir
        self.assertTrue(os.path.exists(os.path.join(self.empty_dir, "Author", "Book_OK")))
        self.assertTrue(os.path.exists(os.path.join(self.empty_dir, "Author", "Empty_Book")))
        
        # Verify fail_folder is untouched
        self.assertTrue(os.path.exists(os.path.join(self.fail_folder, "part2.mp3")))

    def test_ignore_non_ok_folders(self):
        paths = safe_move.read_migration_report(self.report_path)
        self.assertIn("Author/Book_OK", paths)
        self.assertIn("Author/Empty_Book", paths)
        self.assertNotIn("Author/Book_FAIL", paths)

    def test_transaction_log_creation(self):
        paths = safe_move.read_migration_report(self.report_path)
        safe_move.stage_verified_folders(
            self.source_dir, self.staging_dir, self.empty_dir, paths, dry_run=False, log_file=self.log_path
        )
        
        self.assertTrue(os.path.exists(self.log_path))
        with open(self.log_path, "r", encoding="utf-8") as f:
            log = json.load(f)
            
        self.assertEqual(len(log), 3) # 1 file + 2 empty folders
        types = [op["type"] for op in log]
        self.assertEqual(types.count("file"), 1)
        self.assertEqual(types.count("empty_folder"), 2)

    def test_rollback_execution(self):
        paths = safe_move.read_migration_report(self.report_path)
        safe_move.stage_verified_folders(
            self.source_dir, self.staging_dir, self.empty_dir, paths, dry_run=False, log_file=self.log_path
        )
        
        # Now rollback
        safe_move.rollback_transaction(self.log_path, dry_run=False)
        
        # Verify files and folders are back
        self.assertTrue(os.path.exists(os.path.join(self.ok_folder, "part1.mp3")))
        self.assertTrue(os.path.exists(self.empty_ok_folder))
        
        # Staging and empty_dir should have been cleaned up
        self.assertFalse(os.path.exists(os.path.join(self.staging_dir, "Author")))
        self.assertFalse(os.path.exists(os.path.join(self.empty_dir, "Author")))

    def test_rollback_dry_run(self):
        paths = safe_move.read_migration_report(self.report_path)
        safe_move.stage_verified_folders(
            self.source_dir, self.staging_dir, self.empty_dir, paths, dry_run=False, log_file=self.log_path
        )
        
        # Dry-run rollback
        safe_move.rollback_transaction(self.log_path, dry_run=True)
        
        # Verify files are NOT back
        self.assertFalse(os.path.exists(os.path.join(self.ok_folder, "part1.mp3")))
        self.assertTrue(os.path.exists(os.path.join(self.staging_dir, "Author", "Book_OK", "part1.mp3")))

if __name__ == "__main__":
    unittest.main()
