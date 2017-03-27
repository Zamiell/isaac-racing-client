# Imports
use strict;
use warnings;

my $subdirectory = "collectibles";
#my $subdirectory = "trinkets";

for (`ls $subdirectory`) {
	if (/(\d+).png/) {
		system "cp base.anm2 \"$subdirectory/$1.anm2\"";
		system "perl -pi.bak -e \"s/base\\.png/$1\\.png/g\" \"$subdirectory/$1\.anm2\"";
		system "rm \"$subdirectory/$1\.anm2.bak\"";
	} else {
		die "Failed to parse the file name.\n";
	}
}