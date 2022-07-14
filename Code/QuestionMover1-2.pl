#!/usr/bin/perl;
use warnings;
use strict;

Qmove();




sub Qmove{
my $Dir = "InputFiles";
#Need an "InputFiles" directory. This is where the moodle lessons to be searched go.

mkdir("Questions") or die "couldn't make Question directory: $!";
opendir(DIR, $Dir) or die "Couldn't open input file directory: $!";
while (my $file = readdir(DIR)) {
	my $filetarget = "lesson";
	if ($file =~ /\Q$filetarget\E/){
	print "Working on $file\n";
	open(my $read, "<","$Dir/$file") or die "Couldn't open input file $file: $!\n";
	open(my $outext, ">", "Questions/Questions-$file") or die "Couldn't create output file for $file: $!";
		my $target = "<qtype>3</qtype>"; my $targetClose = "</page>";
		my @workingText;
		while(my $comptext = <$read>){
			chomp $comptext;
			push(@workingText, $comptext);
		}
		my $index = @workingText-1;
		my $i = 0;
		my $questionIndex = 0;
		while($i<=$index){
			if($workingText[$i] =~ /\Q$target\E/){
				$questionIndex++;
				print $outext "Question $questionIndex:\n";
				do{
					print $outext "$workingText[$i]\n";
					$i++;
				} while($workingText[$i] !~ /\Q$targetClose\E/);
				print $outext "$workingText[$i]\n";
				print $outext "\n";
			}
			$i++;
		
		}
	close($outext);
	close($read);
	}
}
closedir(DIR);
}
