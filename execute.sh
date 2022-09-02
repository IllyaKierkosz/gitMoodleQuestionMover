#! usr/bin/bash

perl questionMaker.pl

mkdir ZippedQuestions

for lesson in ./Code/Questions/*/
do
	for qfolder in "$lesson"*/
	do
		question=$(echo "$qfolder" | awk -F'/' '{print $4}')
		rm "$qfolder"oldOrig
		rm "$qfolder"content/oldOrig
		zip -X -D -r -q "$question".h5p "$qfolder"
		mv "$question".h5p ./ZippedQuestions/
		mv ./Code/FlaggedQuestions ./
		
		rm -r ./Code/Questions
		rm -r ./Code/QPhase{1,2}
	done
done



