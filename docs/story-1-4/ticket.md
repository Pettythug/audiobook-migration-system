This is ticket number one point four for the final destructive cleanup script. The task is to build a python script named destructive_cleanup.py under the src folder. This script must run on the Gemini 3.1 Pro (High) model.

The script will permanently delete the staged audiobook folders that were moved to the staging directories during story one point three. It will take command-line arguments for the staging paths to target.

Because this operation is destructive and irreversible, the script must implement an extreme safety gate. It must run in dry-run mode by default, simply listing what it is about to delete. To actually perform the deletion, it must require two explicit flags: --execute and --confirm-destructive.

The script must write a final JSON log detailing the exact paths of everything it deleted, along with the timestamp, so we have a permanent audit record of the cleanup.

The developer must write comprehensive mock tests in the tests directory to prove the dry-run safety gates and deletion logic work flawlessly on fake zero-byte files before touching any real data.
