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
our $problem="1";
our $description="Additional disk has been added to your server. Initialize it, \ncreate a 100 MB (+-10%) ext3 partition on it and persistently mount it on /mnt/das.\n";
our $hint="Find the device with fdisk, create a partition, \nthen create a filesystem and create entry in fstab\n";
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
	print "Break has been selected.\n";
	&pre();
	$verbose and print "Pre complete breaking\n";
	my $ret=Disk::lv_create("vdb","200","vdb");
	if ( $ret == 1 ) {
		$verbose and print "Trying to repair.\n";
		Disk::lv_remove("vdb");
		Disk::lv_create("vdb","200","vdb");
	} else {
		print "Disk attached to server. Local disk is vdb\n";
	}
	print "Your task: $description\n";
}

sub grade() {
	print "Grade has been selected.\n";
	print "rebooting server:";
	Framework::restart;
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
	if ( ( $output[1] > 90 ) and ( $output[1] < 110 ) ) {
		Framework::grade(0);
	} else {
		Framework::grade(1);
		exit 1;
	}
	## Check filesystem type
	$output=$ssh->capture("grep /mnt/das /proc/mounts | grep -q ext3; echo -n $?");
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
	## Running post
	&post();
}

sub pre() {
	### Prepare the machine 
	$verbose and print "Running pre section\n";
	my $free=Disk::lvm_free;
	$verbose and print "Free space :$free\n";
	if ( $free > 300 ) {
		$verbose and print "We have enough space to continue.\n";
	} else {
		print "Not enough space on server. We need to free up some space.";
		if ( Disk::lv_count ne 4 ) {
			print "You have " . Disk::lv_count . " lv-s on the server instead of 4. We should restore default settings.\n";
			Disk::base;
		} else {
			print "Count is ok. Dev should investigate problem.\n";
			exit 1;
		}
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
