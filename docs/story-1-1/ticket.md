This is ticket number one point one for the scanner developer. The task is to build a python script named manifest_scanner.py under the src folder. This script must run on the Gemini 3.5 Flash (High) model.

The script must recursively traverse a source directory, which you will provide as a path command argument. It needs to check every single folder down to the leaf node, even if some parents look empty. It must find all audio files.

To categorize these files, the script will use four buckets: Audiobooks, Music, System/Other, and Unknown. You will check file extensions, where .m4b is an audiobook. You will check duration, where anything over forty-five minutes is likely an audiobook. You will inspect file paths for keywords like music, playlist, and artist for the music bucket, and words like assets or help for system audio. You will read the ID3 metadata tags for genre and narrator information.

If a folder contains mostly files classified as audiobooks, the script must classify the remaining files in that same folder as audiobooks too so the whole folder stays together.

The output must be a CSV file called pcloud_manifest.csv. This CSV needs to list the highest common parent folder path that contains the audiobooks, the number of files inside, the total size, and the recommended migration decision. The script must default to a dry-run mode that prints out what folders it found without writing any files unless you explicitly tell it to output the CSV. The developer must write tests in the tests directory using mock folders to verify this traversal and classification logic before showing the code for review.
