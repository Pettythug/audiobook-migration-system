This is the backlog for our audiobook migration project. We are setting this up so we can organize the work for our developers and keep everything structured.

Our epic is called Safe Cloud Audiobook Migration and Verification. We want to catalog, migrate, verify, and clean up audiobooks from pCloud to Google Drive without losing any files or mixing in any music or app audio.

Our first story is the multi-heuristic pCloud scanner. The goal is to write a script that traverses a mounted pCloud drive and indexes all audio files. This task should be done using the Gemini 3.5 Flash (High) model because it is fast and perfect for this kind of file indexing logic. The script needs to use rules like duration thresholds, file extensions, folder path words, and metadata tags to sort files into audiobooks, music, app audio, or unknown categories. It should also use folder-level majority rules to make sure all files in a folder get grouped together. The script must output a CSV file that lists the highest common parent folders to make the migration easier.

Our second story is the migration validation and reporter. A developer will write a script to compare the files on pCloud with the files copied to Google Drive to make sure sizes and structures match exactly. This script will run on the Gemini 3.5 Flash (High) model. It will check file sizes and relative paths and write out a detailed report of any missing files or duplicates.

Our third story is the verified destructive cleanup. A senior developer using the Gemini 3.1 Pro (High) model will write a script to safely delete the migrated folders from pCloud. This script is highly sensitive and is only allowed to run after the validation report shows that all audiobooks are 100% safe on Google Drive and you have approved the cleanup manifest.

I am writing separate ticket files in the tickets directory with more specific instructions for each task so you can share them with the developers.
