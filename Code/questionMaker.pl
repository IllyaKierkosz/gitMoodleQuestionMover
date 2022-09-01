#!/usr/bin/perl;
use warnings;
use strict;
use File::Copy;
use File::Copy::Recursive qw(dircopy); 

QP1();
QP2();
my %ImLookup = ImLookup();
Qmake();

sub QP1{
	mkdir("QPhase1") or die "Could not make Phase 1 Question processing directory: $!";
	#Make the directory where the harvested questions go.
	opendir(ACTIVITIES, "../InputFiles/activities") or die "Could not open Input Files directory: $!";
	my @inputContents = readdir(ACTIVITIES);
	my @lessonDirectories = grep(m{lesson}, @inputContents);
	closedir(ACTIVITIES);
	print "Lessons in this backup:\n";
	print "@lessonDirectories\n";
	#Generating a list of lesson sub-directories.

	foreach(@lessonDirectories){
		my $currentLesson = $_;
		print "Working on $currentLesson\n";
		open(my $intext, "<","../InputFiles/activities/$currentLesson/lesson.xml") or die "Couldn't open lesson file for $currentLesson: $!\n";
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

sub QP2{
	mkdir("QPhase2") or die "Could not make Phase 2 Question processing directory: $!";
	opendir(QPhase1, "QPhase1") or die "Could not open Questions directory: $!";
	my @inputContents = readdir(QPhase1);
	my @questionFiles = grep(m{lesson}, @inputContents);
	closedir(QPhase1);
	print "Question Files to be worked on:\n";
	print "@questionFiles\n";
	
	foreach(@questionFiles){
		my $currentFile = $_;
		$currentFile =~ s/.txt//;
		print "Working on $currentFile\n";
		open(my $intext, "<","QPhase1/$currentFile.txt") or die "Couldn't open lesson file for $currentFile: $!\n";
		open(my $outext, ">", "QPhase2/$currentFile.txt") or die "Couldn't create output file for $currentFile: $!";
		open(my $flagQs, ">>", "FlaggedQuestions.txt") or die "Couldn't create flag file: $!";
		my @workingText;
		while(my $comptext = <$intext>){
			chomp $comptext;
			push(@workingText, $comptext);
		}
		my $index = @workingText-1;
		my $i = 0;
		while($i<=$index){
			if($workingText[$i] =~ m{-Question (\d*):}){
				my $qNum = $1;
				my $qName = "$currentFile-Question $qNum";
				print $outext "$workingText[$i]\n";
				my @images;
				my $imageNum=0;
				do{
					if($workingText[$i] =~ m{<title>|<contents>|<score>|<answer_text>|<response>}){
						while ($workingText[$i] =~ m{(<img src=.*?/>)}g){
							my $image = $1;
							push(@images, $image);
							$workingText[$i] =~ s/$image//;
							$imageNum++;
						}
						$workingText[$i] =~ s/<\/p>\s*?<p>//g;
						if($workingText[$i] !~ m{<score>}){
						print $outext "$workingText[$i]";
						} else {
							print $outext "\n$workingText[$i]";
						}
					}
					$i++;
				} while($workingText[$i] !~ m{Q-END});
				print $outext "\n";
				if($imageNum>1){
					print $flagQs "$qName\n";
				}
				print $outext "Image count: $imageNum.\n";
				foreach (@images){
					print $outext "$_\n";
				}
				print $outext "Q-END\n";
				print $outext "\n";
			}
			$i++;
		}
		close($outext);
		close($intext);
		close($flagQs);
	}
}

sub ImLookup{
	my %ImLookup;
	#init lookup hash
	open(my $imagefiles, "<", "../InputFiles/files.xml") or die "Couldn't open files.xml: $!";
	#opening the moodle backup image lookup file
	my @workingText;
	while(my $text = <$imagefiles>){
		chomp $text;
		push(@workingText, $text);
	}
	#putting file text into a working array
	my $index = @workingText-1;
	my $i = 0;
	#initializing indeces
	while($i<=$index){
		if($workingText[$i] =~ m{<contenthash>(.*?)</contenthash>}){
			my $currentHash = $1;
			do{
				$i++;
			} while($workingText[$i] !~ m{<filename>});
			if($workingText[$i] !~ m{<filename>\.</filename>}){
				$workingText[$i] =~ m{<filename>(.*?)</filename>};
				my $currentKey = $1;
				$ImLookup{$currentKey} = $currentHash;
			}
		}
		$i++;
	}
	close($imagefiles);
	return %ImLookup
	}
	

sub Qmake{
	opendir(QPhase2, "QPhase2") or die "Could not open Questions directory: $!";
	my @inputFiles = readdir(QPhase2);
	my @questionFiles = grep(m{lesson}, @inputFiles);
	closedir(QPhase2);
	mkdir("Questions") or die "Could not make Questions directory: $!";
	chdir("Questions") or die "Could not move to Questions directory: $!";
	print "Question Files to be worked on:\n";
	print "@questionFiles\n";
	foreach(@questionFiles){
		my $currentLesson = $_;
		$currentLesson =~ s/Questions-//;
		$currentLesson =~ s/.txt//;
		print "Working on $currentLesson\n";
		
		mkdir("$currentLesson") or die "Could not make $currentLesson Questions directory: $!";
		open(my $intext, "<","../QPhase2/Questions-$currentLesson.txt") or die "Couldn't open lesson file for $currentLesson: $!\n";
		my $target = "$currentLesson-Question"; my $targetClose = "Q-END";
		my @workingText;
		while(my $compText = <$intext>){
			chomp $compText;
			push(@workingText, $compText);
		}
		my $index = @workingText-1;
		my $i = 0;
		
		while($i<=$index){
				if($workingText[$i] =~ m{-Question (\d*):}){
					my $title;
					my $contents;
					my @score;
					my @answerText;
					my @response;
					my $answerNumber=0;
					my $imageCount;
					my @images;
					my $qNum = $1;
					my $qName = "$currentLesson-Question$qNum";
					$i++;
					if($workingText[$i] =~m{<title>(.*?)<\/title>\s+<contents>(.*?)<\/contents>}g){
						$title = $1; $contents = $2;
					} else{
						print "Error moving $qName: title/content not in expected location.";
					}
					$i++;
					while($workingText[$i] =~m{<score>(\d*)</score>\s+<answer_text>(.*?)</answer_text>\s+<response>(.*?)</response>}g){
						push(@score, $1);
						push(@answerText, $2);
						push(@response, $3);
						$answerNumber++;
						$i++;
					}
					if($workingText[$i] =~m{Image count: (\d*).}g){
						$imageCount = $1;
						my $imageIndex = 0;
						$i++;
						while($imageIndex < $imageCount){
							push(@images,$workingText[$i]);
							$imageIndex++;
							$i++;
						}
					} else{
						print "Error moving $qName: Image count not in expected location.";
					}
					my @imFile;
					my @width;
					my @height;
					my @altText;
					my @imName;
					foreach(@images){
						my $currentIm = $_;
						if ($currentIm =~ m{<img src="@\@PLUGINFILE@@\/(.*?)"}){
							push(@imFile, $1);
						} else{
							print "Error matching image filename in $qName";
						}
						if ($currentIm =~ m{width="(\d*?)"}){
							push(@width, $1);
						} else{
							print "Error matching image width in $qName";
						}
						if ($currentIm =~ m{height="(\d*?)"}){
							push(@height, $1);
						} else{
							print "Error matching image height in $qName";
						}
						if ($currentIm =~ m{alt="(.*?)"}){
							push(@altText, $1);
						} else{
							print "Error matching image alt text in $qName";
						}
					}
					foreach(@imFile){
						my $imageName = $_;
						if ($imageName =~ m{(.*?).png}){
							push(@imName,$1);
						} elsif($imageName =~ m{(.*?).jpg}){
							push(@imName,$1);
						} else{
							print "Error with image name (likely not .png) in $qName";
						}
					}
					chdir("$currentLesson") or die "Could not move to $currentLesson Questions directory: $!";
					dircopy("../../QuestionTemplate", "$qName");
					chdir("$qName") or die "Could not move to $qName directory: $!";
						open(OLD, "<", "h5p.json") or die "can't open h5p cover file: $!"; 
						open(NEW, ">", "new.json") or die "can't open temporary cover file: $!"; 
						while (my $compText = <OLD>) { 
							$compText =~ s/_TITLE_/$title/;
							print NEW "$compText";
						} 
						close(OLD) or die "can't close h5p cover file: $!"; 
						close(NEW) or die "can't close temporary cover file: $!"; 
						rename("h5p.json", "oldOrig") or die "can't rename old h5p cover file: $!"; 
						rename("new.json", "h5p.json") or die "can't rename new h5p cover file: $!"; 
						chdir("content") or die "Could not move to $qName content directory: $!";
							open(OLD, "<", "content.json") or die "can't open content file: $!"; 
							open(NEW, ">", "new.json") or die "can't open temporary content file: $!"; 
							while (my $compText = <OLD>) {
								$compText =~ s/_QTEXT_/$contents/;
								my $answerIndex = 0;
								do {
									my $answer = '{"correct":_SCORE_,"tipsAndFeedback":{"chosenFeedback":"<div>_RESPONSE_<\/div>\n"},"text":"<div>_ATEXT_<\/div>\n"}';
									if ($score[$answerIndex]==1){
										$answer =~ s/_SCORE_/true/;
									} elsif ($score[$answerIndex]==0) {
										$answer =~ s/_SCORE_/false/;
									} else {
										print "Issue with answer $answerIndex in $qName\n";
									}
									$answer =~ s/_RESPONSE_/$response[$answerIndex]/; $answer =~ s/_ATEXT_/$answerText[$answerIndex]/;
									$answerIndex++;
									if($answerIndex==$answerNumber){
										$compText =~ s/_ANSWER_/$answer/;
									}else{
										$compText =~ s/_ANSWER_/$answer,_ANSWER_/;
									}
								} while ($answerIndex < $answerNumber);
								my $image = '"media":{"type":{"params":{"contentName":"Image","alt":"_ALTEXT_","title":"_IMNAME_","file":{"path":"images\/_FILENAME_","mime":"image\/png","copyright":{"license":"U"},"width":_WIDTH_,"height":_HEIGHT_}},"library":"H5P.Image 1.1","subContentId":"327a808f-1a51-493b-80d1-4c5af6b31c15","metadata":{"contentType":"Image","license":"U","title":"Untitled Image"}},"disableImageZooming":false},';
								if ($imageCount == 1){
									$image =~ s/_ALTEXT_/$altText[0]/;$image =~ s/_IMNAME_/$imName[0]/;$image =~ s/_FILENAME_/$imFile[0]/;$image =~ s/_WIDTH_/$width[0]/;$image =~ s/_HEIGHT_/$height[0]/;
									$compText =~ s/_IMAGE_/$image/;
									my $imHash = $ImLookup{$imFile[0]};
									$imHash =~ m{(^\w{2})}g;
									my $imHashFolder = $1;
									copy("../../../../../InputFiles/files/$imHashFolder/$imHash","images/$imFile[0]") or die "Could not transfer image file for $qName: $!";
								} else{
									$compText =~ s/_IMAGE_//;
								}print NEW "$compText";
							}
							close(OLD) or die "can't close content file: $!"; 
							close(NEW) or die "can't close temporary contnt file: $!"; 
							rename("content.json", "oldOrig") or die "can't rename old content file: $!"; 
							rename("new.json", "content.json") or die "can't rename new content file: $!"; 
						chdir("..");
					chdir("..");
					chdir("..");
				}
				$i++;
			}
	}
	chdir("..");
}


