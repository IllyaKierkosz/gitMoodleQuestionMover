#!/usr/bin/perl;
use warnings;
use strict;
use File::Copy::Recursive qw(dircopy); 

Qmake();

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
					
					chdir("$currentLesson") or die "Could not move to $currentLesson Questions directory: $!";
					dircopy("../../QuestionTemplate", "$qName");
					chdir("$qName") or die "Could not move to $qName directory: $!";
						open(OLD, "<", "h5p.json") or die "can't open h5p cover file: $!"; 
						open(NEW, ">", "new.json") or die "can't open temporary cover file: $!"; 
						while (my $compText = <OLD>) { 
							$compText =~ s/_TITLE/$title/;
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
								print NEW "$compText";
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
