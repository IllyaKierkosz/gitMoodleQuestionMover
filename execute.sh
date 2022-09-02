#! usr/bin/bash

cd ./Code/
perl ./questionMaker.pl
cd ../
#executing question processing code


mkdir ZippedQuestions
#making a directory to put zipped questions in


for lesson in ./Code/Questions/*/
do
	for qfolder in "$lesson"*/
	do
		question=$(echo "$qfolder" | awk -F'/' '{print $5}')
		rm "$qfolder"oldOrig
		rm "$qfolder"content/oldOrig
		cd "$qfolder"
		zip -rXDq "$question".h5p *
		cd ../../../../
		mv "$qfolder""$question".h5p ./ZippedQuestions/
	done
done
#cleaning each question package, zipping them up, then moving them to the zipped questions directory


mv ./Code/FlaggedQuestions.txt ./ZippedQuestions/
#moving the flagged question log file to the zipped questions directory

		
rm -r ./Code/Questions   #if you want the question packages before they've been zipped, delete this line
rm -r ./Code/QPhase{1,2} #if you want the intermediate processing stages, delete this line



