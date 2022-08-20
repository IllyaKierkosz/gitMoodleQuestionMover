#!/usr/bin/perl;
use warnings;
use strict;

QP2();




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
		open(my $flagQs, ">", "FlaggedQuestions.txt") or die "Couldn't create flag file: $!";
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
