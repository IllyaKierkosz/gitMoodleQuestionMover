#!/usr/bin/perl;
use warnings;
use strict;
use File::Copy;
use File::Copy::Recursive qw(dircopy); 

QP1(); #phase 1 processing: scans through lessons to collect all text relating to multiple choice questions
QP2(); # phase 2 processing: cleans each question of all extraneous information, and arranges in a workable format
my %ImLookup = ImLookup(); #generating a "dictionary" for the images, matching filename to the moodle hash code in order to make finding and moving images easier
Qmake(); #phase 3 processing: for each question, generates an h5p question package, extracts necessary text from moodle formatting, and inserts into h5p formatting

sub QP1{
	mkdir("QPhase1") or die "Could not make Phase 1 Question processing directory: $!"; 
	#Making processing phase 1 directory. Output from phase 1 goes here
	opendir(ACTIVITIES, "../InputFiles/activities") or die "Could not open Input Files directory: $!";
	my @inputContents = readdir(ACTIVITIES);
	my @lessonDirectories = grep(m{lesson}, @inputContents);
	closedir(ACTIVITIES);
	#Generating a list of lesson sub-directories.
	
	#print "Lessons in this backup:\n";
	#print "@lessonDirectories\n";
	

	foreach(@lessonDirectories){
		my $currentLesson = $_;
		#print "Working on $currentLesson\n";
		open(my $intext, "<","../InputFiles/activities/$currentLesson/lesson.xml") or die "Couldn't open lesson file for $currentLesson: $!\n";
		open(my $outext, ">", "QPhase1/Questions-$currentLesson.txt") or die "Couldn't create output file for $currentLesson: $!";
			my $target = "<qtype>3</qtype>"; my $targetClose = "</page>"; #target "phrases" selecting for question blocks.
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
								$workingText[$i] =~ s{\&lt\;}{<}g; #cleaning formatting error
								$workingText[$i] =~ s{\&gt\;}{>}g; #cleaning formatting error
								print $outext "$workingText[$i] "; #printing on same line as previous to put like data in same place
								$i++;
							}
						} 
						$workingText[$i] =~ s{\&lt\;}{<}g; #cleaning formatting error
						$workingText[$i] =~ s{\&gt\;}{>}g; #cleaning formatting error
						print $outext "$workingText[$i]\n"; #printing with a new line
						$i++;
					} while($workingText[$i] !~ m{$targetClose});
					print $outext "$workingText[$i]\n"; 
					print $outext "Q-END\n";
					print $outext "\n";
				}
				$i++;
		
			}
			#Searches each line of the working text array for the target phrases, and prints the contents between to the output file. Similar data spread over multiple lines are put onto the same line. This makes future processing easier.
		close($outext);
		close($intext);
	}
}

sub QP2{
	mkdir("QPhase2") or die "Could not make Phase 2 Question processing directory: $!";
	#Making processing phase 2 directory. Output from phase 2 goes here
	opendir(QPhase1, "QPhase1") or die "Could not open Questions directory: $!";
	my @inputContents = readdir(QPhase1);
	my @questionFiles = grep(m{lesson}, @inputContents);
	closedir(QPhase1);
	#Going into phase 1 outputs and gathering question files
	
	#print "Question Files to be worked on:\n";
	#print "@questionFiles\n";
	
	foreach(@questionFiles){
		my $currentFile = $_;
		$currentFile =~ s{.txt}{}g;
		#print "Working on $currentFile\n";
		open(my $intext, "<","QPhase1/$currentFile.txt") or die "Couldn't open lesson file for $currentFile: $!\n";
		open(my $outext, ">", "QPhase2/$currentFile.txt") or die "Couldn't create output file for $currentFile: $!";
		open(my $flagQs, ">>", "FlaggedQuestions.txt") or die "Couldn't create flag file: $!";
		my @workingText;
		while(my $comptext = <$intext>){
			chomp $comptext;
			push(@workingText, $comptext);
		}
		#moving contents of the current question file into a working text array.
		my $index = @workingText-1;
		my $i = 0;
		while($i<=$index){
			if($workingText[$i] =~ m{-Question (\d*):}){
				my $qNum = $1;
				my $qName = "$currentFile-Question $qNum";
				print $outext "$workingText[$i]\n";
				my @images;
				my $imageNum=0;
				#Initializing current question name and image processing variables
				do{
					if($workingText[$i] =~ m{<title>|<contents>|<score>|<answer_text>|<response>}){
						#looking for relevant text
						while ($workingText[$i] =~ m{(<img src=.*?/>)}g){
							my $image = $1;
							push(@images, $image);
							$imageNum++;
						}
						#Finding any images that might be in the text and collecting data. This data will be removed from the text and printed at the end of the question
						$workingText[$i] =~ s{<img src=.*?/>}{}g; #cleaning image code from text 
						$workingText[$i] =~ s{<\/p>\s*?<p>}{}g; #cleaning formatting
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
				} #if more than one image found, flags the question
				print $outext "Image count: $imageNum.\n";
				foreach (@images){
					print $outext "$_\n";
				}
				print $outext "Q-END\n";
				print $outext "\n";
				#printing conclusion text for each question, including all image data found
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
	while($i<=$index){
		if($workingText[$i] =~ m{<contenthash>(.*?)</contenthash>}){
			my $currentHash = $1; #collects internal moodle image-file hash
			do{
				$i++;
			} while($workingText[$i] !~ m{<filename>}); #skips ahead until filename is found
			if($workingText[$i] !~ m{<filename>\.</filename>}){
				$workingText[$i] =~ m{<filename>(.*?)</filename>};
				my $currentKey = $1;
				$ImLookup{$currentKey} = $currentHash;
			} #loading data into "dictionary". The moodle hash is the key, and the filename is the value
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
	#Going into phase 2 outputs and gathering question files
	mkdir("Questions") or die "Could not make Questions directory: $!";
	chdir("Questions") or die "Could not move to Questions directory: $!";
	#print "Question Files to be worked on:\n";
	#print "@questionFiles\n";
	foreach(@questionFiles){
		my $currentLesson = $_;
		$currentLesson =~ s{Questions-}{}g;
		$currentLesson =~ s{.txt}{}g;
		#print "Working on $currentLesson\n";
		mkdir("$currentLesson") or die "Could not make $currentLesson Questions directory: $!";
		open(my $intext, "<","../QPhase2/Questions-$currentLesson.txt") or die "Couldn't open lesson file for $currentLesson: $!\n";
		my $target = "$currentLesson-Question"; my $targetClose = "Q-END";
		my @workingText;
		while(my $compText = <$intext>){
			chomp $compText;
			push(@workingText, $compText);
		}
		#moving contents of the current question file into a working text array.
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
					#initializing fields to be entered into h5p, and other stuff
					$i++;
					if($workingText[$i] =~m{<title>(.*?)<\/title>\s+<contents>(.*?)<\/contents>}g){
						$title = $1; 
						$title =~ s{\\}{\\\\}g; $title =~ s{/}{\/}g; $title =~ s{"}{\\"}g; #cleaning illegal characters in h5p. backslash, forwardslash, and quotation marks need to be escaped
						$contents = $2; 
						$contents =~ s{\\}{\\\\}g; $contents =~ s{/}{\/}g; $contents =~ s{"}{\\"}g; #cleaning illegal characters in h5p
					} else{
						print "Error moving $qName: title/content not in expected location.";
					}
					#reading line for title and contents data, and storing in respective variables
					$i++;
					while($workingText[$i] =~m{<score>(\d*)</score>\s+<answer_text>(.*?)</answer_text>\s+<response>(.*?)</response>}g){
						push(@score, $1); 
						my $AT = $2; 
						$AT =~ s{\\}{\\\\}g; $AT =~ s{/}{\/}g; $AT =~ s{"}{\\"}g;  #cleaning illegal characters in h5p
						push(@answerText, $2);
						my $R = $3; 
						$R =~ s{\\}{\\\\}g; $R =~ s{"}{\\"}g;  #cleaning illegal characters in h5p
						push(@response, $3);
						$answerNumber++;
						$i++;
					}
					#reading lines for answer data, and storing in score, answer, and response arrays. Arrays are used since there are an unknown number of answers
					if($workingText[$i] =~m{Image count: (\d*).}g){
						$imageCount = $1;
						my $imageIndex = 0;
						$i++;
						while($imageIndex < $imageCount){
							push(@images,$workingText[$i]);
							$imageIndex++;
							$i++;
						}
						#reading image data into an array
					} else{
						print "Error moving $qName: Image count not in expected location.";
					}
					my @imFile;
					my @width;
					my @height;
					my @altText;
					my @imName;
					#initializing image data variables
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
							my $imAT = $1;
							$imAT =~ s{\\}{\\\\}g; $imAT =~ s{/}{\/}g; $imAT =~ s{"}{\\"}g;  #cleaning illegal characters in h5p
							push(@altText, $imAT);
						} else{
							print "Error matching image alt text in $qName";
						}
					} #reading data into respective variables
					foreach(@imFile){
						my $imageName = $_;
						if ($imageName =~ m{(.*?).png}){
							push(@imName,$1);
						} elsif($imageName =~ m{(.*?).jpg}){
							push(@imName,$1);
						} else{
							print "Error with image name (likely not .png) in $qName";
						}
					} #cleaning extension from image filenames and storing in another variable
					chdir("$currentLesson") or die "Could not move to $currentLesson Questions directory: $!";
					dircopy("../../QuestionTemplate", "$qName");
					#making h5p question package to be filled with collected data
					chdir("$qName") or die "Could not move to $qName directory: $!";
						open(OLD, "<", "h5p.json") or die "can't open h5p cover file: $!"; 
						open(NEW, ">", "new.json") or die "can't open temporary cover file: $!"; 
						while (my $compText = <OLD>) { 
							$compText =~ s{_TITLE_}{$title}g;
							print NEW "$compText";
						} 
						close(OLD) or die "can't close h5p cover file: $!"; 
						close(NEW) or die "can't close temporary cover file: $!"; 
						#creating new cover file, and entering the question title into the title field
						rename("h5p.json", "oldOrig") or die "can't rename old h5p cover file: $!"; 
						rename("new.json", "h5p.json") or die "can't rename new h5p cover file: $!"; 
						#swapping old and new cover file names. Old file will be deleted in bash
						chdir("content") or die "Could not move to $qName content directory: $!";
							open(OLD, "<", "content.json") or die "can't open content file: $!"; 
							open(NEW, ">", "new.json") or die "can't open temporary content file: $!"; 
							#creating new content file
							while (my $compText = <OLD>) {
								$compText =~ s{_QTEXT_}{$contents}g; #filling contents field
								my $answerIndex = 0;
								do {
									my $answer = '{"correct":_SCORE_,"tipsAndFeedback":{"chosenFeedback":"<div>_RESPONSE_<\/div>\n"},"text":"<div>_ATEXT_<\/div>\n"}'; #template answer group
									if ($score[$answerIndex]==1){
										$answer =~ s{_SCORE_}{true}g; 
									} elsif ($score[$answerIndex]==0) {
										$answer =~ s{_SCORE_}{false}g;
									} else {
										print "Issue with answer $answerIndex in $qName\n";
									} #filling score field
									$answer =~ s{_RESPONSE_}{$response[$answerIndex]}g; $answer =~ s{_ATEXT_}{$answerText[$answerIndex]}g; #filling answer and response fields
									$answerIndex++;
									if($answerIndex==$answerNumber){
										$compText =~ s{_ANSWER_}{$answer}g;
									}else{
										$compText =~ s{_ANSWER_}{$answer,_ANSWER_}g;
									} #printing answer group into content file, providing an answer field for subsequent answers. If no further answers, extra answer field is omitted
								} while ($answerIndex < $answerNumber);
								my $image = '"media":{"type":{"params":{"contentName":"Image","alt":"_ALTEXT_","title":"_IMNAME_","file":{"path":"images\/_FILENAME_","mime":"image\/png","copyright":{"license":"U"},"width":_WIDTH_,"height":_HEIGHT_}},"library":"H5P.Image 1.1","subContentId":"327a808f-1a51-493b-80d1-4c5af6b31c15","metadata":{"contentType":"Image","license":"U","title":"Untitled Image"}},"disableImageZooming":false},'; #template image group
								if ($imageCount == 1){
									$image =~ s{_ALTEXT_}{$altText[0]}g;$image =~ s{_IMNAME_}{$imName[0]}g;$image =~ s{_FILENAME_}{$imFile[0]}g;$image =~ s{_WIDTH_}{$width[0]}g;$image =~ s{_HEIGHT_}{$height[0]}g;
									$compText =~ s{_IMAGE_}{$image}g;
									my $imHash = $ImLookup{$imFile[0]};
									$imHash =~ m{(^\w{2})}g;
									my $imHashFolder = $1;
									copy("../../../../../InputFiles/files/$imHashFolder/$imHash","images/$imFile[0]") or die "Could not transfer image file for $qName: $!";
								} else{
									$compText =~ s{_IMAGE_}{}g;
								}#populating image group with collected data and filling image group into image field if and only if there was only one image in the question. 
								print NEW "$compText";
							}
							close(OLD) or die "can't close content file: $!"; 
							close(NEW) or die "can't close temporary contnt file: $!"; 
							rename("content.json", "oldOrig") or die "can't rename old content file: $!"; 
							rename("new.json", "content.json") or die "can't rename new content file: $!"; 
							#swapping old and new content file names. Old file will be deleted in bash
						chdir("..");
					chdir("..");
					chdir("..");
				}
				$i++;
			}
	}
	chdir("..");
}


