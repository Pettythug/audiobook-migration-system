This is ticket number one point three for the safe cleanup developer. The task is to build a python script named safe_cleanup.py under the src folder. This script must run on the Gemini 3.1 Pro (High) model.

The cleanup script is a highly sensitive and destructive tool. It is strictly forbidden from running until the migration validation report shows one hundred percent copy success and the user has explicitly signed off.

The script must read the migration_report.csv and the original pcloud_manifest.csv. It must target only the pCloud parent folders that have been flagged as successfully migrated with matching sizes on Google Drive.

By default, the script must run in dry-run mode, printing every single file and folder it plans to delete from pCloud without actually deleting anything. It must require an explicit command-line confirmation flag to execute the deletions. Under no circumstances should the script delete any folders or files classified as music, system audio, or unverified files. The developer must write extensive tests using a mock pCloud setup to guarantee that the script never deletes unapproved files or folders.
