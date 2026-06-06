This is ticket number one point three for the safe staging and rollback developer. The task is to build a python script named safe_move.py under the src folder. This script must run on the Gemini 3.1 Pro (High) model.

The staging script is a highly sensitive tool. It is strictly forbidden from running on any production directories until the migration validation report shows one hundred percent copy success and the user has explicitly signed off.

The script must read the migration_report.csv file from the sandbox root. It must target only the folders that have been flagged with the status OK indicating successful copy and size match.

By default, the script must run in dry-run mode, printing every single file and folder it plans to move without making any changes. It must require an explicit command-line confirmation flag to execute the moves.

The script must move the verified audiobook folders from their source path to a staging path, which will both be passed as command-line arguments. Under no circumstances should the script move any folders or files classified as missing, size mismatch, or pre-existing.

If the script encounters a folder that is empty, or if moving files leaves a folder empty, it must move that empty folder structure into a separate staging path for empty folders, also passed as a command-line argument.

The script must implement a transactional rollback feature. Every time a move operation is executed, the script must write the original path and the new path of every file and folder to a json log file in the sandbox. If the script is run with a rollback flag and a log file path, it must read that log and move all files and folders back to their exact original locations. This rollback operation must also support dry-run mode.

The developer must write extensive unit tests using mock folders and fake zero-byte files under the tests folder to guarantee that the move, empty folder isolation, and rollback logic work perfectly without accessing any live cloud drives.
