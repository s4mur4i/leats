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
our $topic="Physical disk management";
our $problem="2";
our $description="Shrink the filesystem to 40 MB (+-10%) and convert it to ext4.\n";
our $hint="To shrink a filesystem you have to convert it to ext2.\nThen resize it to the required size and convert it to ext4.\n";
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
use File::Basename;
our $name=basename($0);
#use Sys::Virt;
use lib '/scripts/common_perl/';
use Framework qw($verbose $topic $author $version $hint $problem $name);
use Disk qw($verbose $topic $author $version $hint $problem $name);
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
	print "Running Dependency check. This may take some time.\n";
	&pre();
	print "Break has been selected.\n";
	my $ssh=Framework::ssh_connect;
	my $ret=$ssh->capture("rm -f /mnt/das/scully >/dev/null 2>\&1;echo `date +%s` > /mnt/das/scully 2>/dev/null; echo \$?");
	if ( $ret == 0 ) {
		print "Your task: $description\n";
	} else {
		print "Could no create data on server.\n";
		exit 1;
	}
}

sub grade() {
	print "Grade has been selected.\n";
	print "rebooting server:";
	#Framework::restart;
	Framework::grade(Framework::timedconTo("60"));
	## Checking if mounted
        my $ssh=Framework::ssh_connect;
	my $output=$ssh->capture("grep /mnt/das /proc/mounts | grep -q vdb; echo -n \$?");
	print "Checking mount:";
	Framework::grade($output);
	## Checking size
	$output=$ssh->capture("df -P -B M /mnt/das | tail -1");
	my @output=split(/\s+/,$output);
	$output[1] =~ s/(\d+)\w*/$1/;
	$verbose and print "Size is: '$output[1]'\n";
	print "Checking size:";
	if ( ( $output[1] > 35 ) and ( $output[1] < 45 ) ) {
		Framework::grade(0);
	} else {
		Framework::grade(1);
		exit 1;
	}
	## Check filesystem type
        $output=$ssh->capture("grep /mnt/das /proc/mounts | grep -q ext4; echo -n \$?");
	$verbose and print "Filesystem type output: $output\n";
        print "Checking filesystem type:";
        if ( $output ) {
                Framework::grade(1);
                exit 1;
        } else {
                Framework::grade(0);
        }
	## Creating test file on filesystem.
	$output=$ssh->capture("rm -f /mnt/das/test >/dev/null 2>\&1;touch /mnt/das/test;echo -n \$?; rm -f /mnt/das/test >/dev/null 2>\&1");
	$verbose and print "Test file output is: '$output'\n";
	print "Creating test file:";
	if ( $output ) {
		Framework::grade(1);
		exit 1;
	} else {
		Framework::grade(0);
	}
	Framework::mount("/mentes","vdb");
	my @info=stat("/mentes/scully");
	$verbose and print "Ctime is: $info[10]\n";
	open my $fh, "<", "/mentes/scully" or (print "Missing file on disk." and exit 1);
	my $time=do { local $/; <$fh> };
	chomp $time;
	$verbose and print "Time in file is: $time\n";
	print "Data integrity:";
	if ( $info[10] eq $time ) {
		Framework::grade(0);
	} else {
		Framework::grade(1);
		exit 1;
	}
	unlink("/mentes/scully");
	Framework::umount("/mentes"."vdb");;
	## Running post
	&post();
}

sub pre() {
	### Prepare the machine 
	$verbose and print "Running dependency check:\n";
	open my $command, "/scripts/02-physical_disk/2.pl -g|" or (print "Couldn't execute test.\n" and exit 1);
	while (<$command>) {
		print;
	}
	close $command;
	if ( ${^CHILD_ERROR_NATIVE} != 0 ) {
		print "Previous task not yet completed.\n";
		exit 1;
	}
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
