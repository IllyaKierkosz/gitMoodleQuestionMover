#!/usr/bin/perl;
use warnings;
use strict;

QP1();




sub QP1{
	mkdir("QPhase1") or die "Could not make Phase 1 Question processing directory: $!";
	#Make the directory where the harvested questions go.
	opendir(ACTIVITIES, "InputFiles/activities") or die "Could not open Input Files directory: $!";
	my @inputContents = readdir(ACTIVITIES);
	my @lessonDirectories = grep(m{lesson}, @inputContents);
	closedir(ACTIVITIES);
	print "Lessons in this backup:\n";
	print "@lessonDirectories\n";
	#Generating a list of lesson sub-directories.

	foreach(@lessonDirectories){
		my $currentLesson = $_;
		print "Working on $currentLesson\n";
		open(my $intext, "<","InputFiles/activities/$currentLesson/lesson.xml") or die "Couldn't open lesson file for $currentLesson: $!\n";
		open(my $outext, ">", "QPhase1/Questions-$currentLesson.txt") or die "Couldn't create output file for $currentLesson: $!";
			my $target = "<qtype>3</qtype>"; my $targetClose = "</page>";
			#target "phrases" selecting for question blocks.
			my @workingText;
			while(my $comptext = <$intext>){
				chomp $comptext;
				push(@workingText, $comptext);
			}
			#moving contents of the lesson file into a working text array.
			my $index = @workingText-1;
			my $i = 0;
			my $questionIndex = 0;
			while($i<=$index){
				if($workingText[$i] =~ m{$target}){
					$questionIndex++;
					print $outext "$currentLesson-Question $questionIndex:\n";
					do{
						if($workingText[$i] =~ m{<contents>} || $workingText[$i] =~ m{<response>}){
							until($workingText[$i] =~ m{</contents>} || $workingText[$i] =~ m{</response>}){
								$workingText[$i] =~ s/\&lt\;/</g;
								$workingText[$i] =~ s/\&gt\;/>/g;
								print $outext "$workingText[$i] ";
								$i++;
							}
						} 
						$workingText[$i] =~ s/\&lt\;/</g;
						$workingText[$i] =~ s/\&gt\;/>/g;
						print $outext "$workingText[$i]\n";
						$i++;
					} while($workingText[$i] !~ m{$targetClose});
					print $outext "$workingText[$i]\n"; 
					print $outext "Q-END\n";
					print $outext "\n";
				}
				$i++;
		
			}
			#Searches each line of the working text array for the target phrases, and prints the contents between to the output file.
		close($outext);
		close($intext);
	}
}
