This is ticket number one point two for the migration validation developer. The task is to build a python script named verify_migration.py under the src folder. This script must run on the Gemini 3.5 Flash (High) model.

The script must compare two generated CSV manifests: the original pcloud_manifest.csv and a new gdrive_manifest.csv which will be created by running the scanning script on the Google Drive target folder.

The validation script needs to verify that every audiobook folder marked for migration in the pCloud manifest exists in the Google Drive manifest. It must check that the relative path, directory structure, and total file sizes match exactly.

The script must output a report called migration_report.csv. This report should clearly flag any folder that failed to copy, any files that had size mismatches, and any duplicate folders that already existed on Google Drive. The script must output a clean summary to the terminal. The developer must write mock verification tests in the tests directory to prove the comparison logic works accurately under test conditions.
