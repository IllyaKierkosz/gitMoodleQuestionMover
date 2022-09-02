To use this transcribe tool:

1. Download your moodle backup, and unzip it.

2. Rename the unzipped directory to "InputFiles", and place in this directory (the same directory this README is in).

3. Open a terminal, and enter and run the following command: "which bash". if the output is not "usr/bin/bash", you may need to modify the shebang at the top of execute.sh

4. Open a terminal in this directory, and enter and run the following command: "bash execute.sh"

    4.1. Several warnings may pop up while the code is running. This should have no impact on tool performance.

5. Once code has finished running, zipped question files should be in the ZippedQuestions directory. Additionally, a flag log called "FlaggedQuestions.txt" should be there as well; this contains a list of questions that had more than one image.
