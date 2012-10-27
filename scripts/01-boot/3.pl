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
#my $author="Richard Gruber <richard.gruber@it-services.hu>";
our $version="v0.1";
our $topic="boot";
our $problem="3";
our $description="Server isn't booting. Persistently solve the problem.\n";
our $hint="Server has problems booting. We should inspect\nthe boot parameters. Is the root parameter list correct?\n";
#
#
#
#############
our $verbose=0;
my $help=0;
my $break=0;
my $grade=0;
my $hint=0;
use strict;
use warnings;
use Getopt::Long;
use Sys::Virt;
use File::Copy;
use File::Basename;
our $name=basename($0);
use lib '/scripts/common_perl/';
use Framework qw($verbose $topic $author $version $hint $problem $name);
######
###Options
###
GetOptions("help|?|h" => \$help,
           "verbose|v" => \$verbose,
	   "b|break" => \$break,
	   "g|grade" => \$grade,
	   "hint" => \$hint,
        );
#####
# Subs
#
sub break() {
	print "Break has been selected.\n";
	&pre();
	$verbose and print "Pre complete breaking\n";
	Framework::mount;
	### Here comes the break
	open my $grub, "/mentes/boot/grub/grub.conf";
	open my $tgrub, ">/mentes/boot/grub/grub.bkup";
	while ( my $line=<$grub> ) {
		chomp $line;
		$line=~s/^(\s*\w*\s*)\(hd0,0\)(.*)$/$1\(hd1,1\)$2/;
		print $tgrub "$line\n";
	}
	close $tgrub;
	close $grub;
	if ( unlink("/mentes/boot/grub/grub.conf") == 0 ) {
    		$verbose and print "File deleted successfully.\n";
	} else {
		$verbose and print "File was not deleted.\n";
	}
	move("/mentes/boot/grub/grub.bkup", "/mentes/boot/grub/grub.conf");
	Framework::umount;
	Framework::start;
	print "Your task: $description\n";
}

sub grade() {
	print "Grade has been selected.\n";
	Framework::restart;
	print "Test can take up to 1 minutes.\n";
	print "Server booted succesfully:";
	Framework::grade(Framework::timedconTo("60"));
	## Running post
	&post();
}

sub pre() {
	### Prepare the machine 
	$verbose and print "Running pre section\n";
	### Shut down guest
	$verbose and print "Shutting down guest to break\n";
	Framework::shutdown;
	### Check if mount point is already a mount point.
	Framework::umount;
}

sub post() {
	### Cleanup after succeful grade
	$verbose and print "Succesful grade, doing some cleanup.\n";
}

#####
# Main
if ( $help ) {
	Framework::useage;
}

if ( $hint ) {
	Framework::hint;
}
if ( $grade and $break ) {
	print "Break and grade cannot be requested at one time.\n";
	Framework::useage;
}

if ( $break ) {
	&break;
} elsif ( $grade ) {
	&grade;
} else {
	print "Nothing has been selected. Please select one option.\n";
	Framework::useage;
}
