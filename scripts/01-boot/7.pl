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
our $problem="7";
our $description="We need to downgrade our kernel to previous kernel version.\nRemove the new kernel since it has security errors in it.\n";
our $hint="You have to boot the previous kernel to be able to remove the new kernel.\nAfterwards its just a simple erase command.\n";
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
use File::Copy;
use Sys::Virt;
use File::Basename;
our $name=basename($0);
use Net::OpenSSH;
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

	Framework::umount;
	Framework::start;
	print "Your task: $description\n";
}

sub grade() {
	print "Grade has been selected.\n";
	my $ssh=Framework::ssh_connect;
        my $output=$ssh->capture("uname -r");
        chomp $output;
	print "Kernel version:";
	if ( "$output" eq "2.6.32-279.el6.x86_64" ) {
                Framework::grade(0);
        } else {
                Framework::grade(1);
        }
	print "Number of yum repos:";
        $output=$ssh->capture("grep \\\\[ /etc/yum.repos.d/*.repo |wc -l");
        chomp $output;
        $verbose and print "Repo number is:'$output'\n";
        if ( "$output" == 2 ) {
                Framework::grade(0);
        } else {
                Framework::grade(1);
        }
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
