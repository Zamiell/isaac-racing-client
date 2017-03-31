# Imports
use strict;
use warnings;
use POSIX qw/ceil/;
use Image::Size;

if (scalar @ARGV != 1) {
	die "You must provide the name of the png file.\n";
}
my $png = $ARGV[0];
$png =~ /(.+)\.png$/;
my $pngName = $1;

if (-e $png) {
	# Do nothing
} else {
	die "The PNG file does not exist.\n";
}

my ($width, $height) = imgsize($png);
my $xpivot = ceil($width / 2);
my $ypivot = ceil($height / 2);

system "cp base.anm2 \"$pngName.anm2\"";
system "perl -pi.bak -e \"s/base\\.png/$pngName\\.png/g\" \"$pngName.anm2\"";
system "rm \"$pngName.anm2.bak\"";
system "perl -pi.bak -e \"s/__Width__/$width/g\" \"$pngName.anm2\"";
system "rm \"$pngName.anm2.bak\"";
system "perl -pi.bak -e \"s/__Height__/$height/g\" \"$pngName.anm2\"";
system "rm \"$pngName.anm2.bak\"";
system "perl -pi.bak -e \"s/__XPivot__/$xpivot/g\" \"$pngName.anm2\"";
system "rm \"$pngName.anm2.bak\"";
system "perl -pi.bak -e \"s/__YPivot__/$ypivot/g\" \"$pngName.anm2\"";
system "rm \"$pngName.anm2.bak\"";
exit;
