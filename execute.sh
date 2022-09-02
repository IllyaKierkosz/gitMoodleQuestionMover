#! usr/bin/bash

cd ./Code/
perl ./questionMaker.pl
cd ../
mkdir ZippedQuestions
for lesson in ./Code/Questions/*/
do
	for qfolder in "$lesson"*/
	do
		question=$(echo "$qfolder" | awk -F'/' '{print $5}')
		rm "$qfolder"oldOrig
		rm "$qfolder"content/oldOrig
		cd "$qfolder"
		zip -rXDq "$question".h5p *
		cd -
		mv "$qfolder""$question".h5p ./ZippedQuestions/
	done
done
mv ./Code/FlaggedQuestions.txt ./ZippedQuestions/
		
rm -r ./Code/Questions
rm -r ./Code/QPhase{1,2}



