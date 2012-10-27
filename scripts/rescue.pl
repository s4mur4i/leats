#!/usr/bin/perl
# Changelog
# =======================================
# v1.0 Krisztian Banhidy initial release
#
#This file is part of Leats.
##
##Leats is free software: you can redistribute it and/or modify
##it under the terms of the GNU General Public License as published by
##the Free Software Foundation, either version 3 of the License, or
##(at your option) any later version.
##
##Leats is distributed in the hope that it will be useful,
##but WITHOUT ANY WARRANTY; without even the implied warranty of
##MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##GNU General Public License for more details.
##
##You should have received a copy of the GNU General Public License
##along with Leats.  If not, see <http://www.gnu.org/licenses/>.
#############
our $author='Krisztian Banhidy <krisztian@banhidy.hu>';
#our $author='Richard Gruber <richard.gruber@it-services.hu>';
our $version="v0.1";
#
#
#
#############
our $verbose=0;
my $help=0;
my $mount=0;
my $umount=0;
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
our $name=basename($0);
use Sys::Virt;
use Sys::Virt;
use lib '/scripts/common_perl/';
use Framework qw($verbose $author $version $name);
#use Disk qw($verbose $topic $author $version $hint $problem $name);
use Disk qw($verbose $author $version $name);
######
###Options
###
GetOptions("help|?|h" => \$help,
           "verbose|v" => \$verbose,
	   "mount|m" => \$mount,
	   "umount|u" => \$umount
        );
if ( $help ) {
	print "$name usage: $0 -v -h -m|-mount -u|-umount\n";
	print "-h\t\thelp\n";
	print "-v\t\tverbose\n";
	print "-m|-mount\tmount the rescue cd\n";
	print "-u|-umount\tumount the rescue cd\n";
	exit 0;
}
if ( $mount ) {
	print "Mount has been selected.\n";
	Framework::shutdown;
} elsif ( $umount ) {
	print "Umount has been selected.\n";
	Framework::shutdown;
} else {
        print "Nothing has been selected. Please select one option.\n";
	exit 1;
}

