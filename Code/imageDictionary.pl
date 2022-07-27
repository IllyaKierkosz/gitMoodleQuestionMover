#!/usr/bin/perl;
use warnings;
use strict;

my %ImLookup = ImLookup();

while ( (my $k,my $v) = each %ImLookup) {
    print "$k => $v\n";
    
sub ImLookup{
	my %ImLookup;
	#init lookup hash
	open(my $imagefiles, "<", "InputFiles/files.xml") or die "Couldn't open files.xml: $!";
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
			print $currentHash;
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
}

