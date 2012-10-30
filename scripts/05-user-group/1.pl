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
#our $author='Krisztian Banhidy <krisztian@banhidy.hu>';
our $author='Richard Gruber <richard.gruber@it-services.hu>';
our $version="v0.9";
our $topic="Users and groups";
our $problem="1";
our $description="
- create the following users: john, mary and thomas
- create a group named tadmins with GID 885
- john's UID is 2342, his home directory is /home/john.
- mary's UID is 5556 and her default shell is /bin/bash.
- thomas should not have access to any shell
- the users john and mary are members of the group tadmins.
- thomas should not be in the group tadmins.
- change all users password to kuka002
- john's account will expire on 2012-12-12";
our $hint="";
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
use Term::ANSIColor;
use File::Basename;
our $name=basename($0);
use lib '/scripts/common_perl/';
use Framework qw($verbose $topic $author $version $hint $problem $name $exercise_number $exercise_success $debug);
use UserGroup qw(userExist groupExist getUserAttribute checkUserAttribute checkUserPassword &checkUserGroupMembership &checkUserSecondaryGroupMembership &checkUserPrimaryGroup &checkGroupNameAndID &checkUserChageAttribute);
######
###Options
###
GetOptions("help|?|h" => \$help,
           "verbose|v" => \$verbose,
	   "debug" => \$debug,
	   "b|break" => \$break,
	   "g|grade" => \$grade,
	   "hint" => \$hint,
        );

$debug and $verbose=1;

#####
# Subs
#
sub break() {
	print "Break has been selected.\n";
	&pre();
	$verbose and print "Pre complete breaking\n";
	print "Your task: $description\n";
}

sub grade() {
	print "Grade has been selected.\n";
	$verbose and system("clear");
	$exercise_number = 0;
	$exercise_success = 0;
	
	$verbose && print "=============================================================\n";
	$verbose && print "$problem.\n";
	$verbose && print "\n$description\n\n";
	$verbose && print "=============================================================\n\n";

	$verbose && print "User mary exist\t\t\t\t\t";
	Framework::grade(UserGroup::userExist("mary"));
        $verbose && print "User john exist\t\t\t\t\t";
        Framework::grade(UserGroup::userExist("john"));
        $verbose && print "User thomas exist\t\t\t\t";
        Framework::grade(UserGroup::userExist("thomas"));

        $verbose && print "Group tadmins exist\t\t\t\t";
        Framework::grade(UserGroup::groupExist("tadmins"));
	
	$verbose && print "Group tadmins with GID 885\t\t\t";
	Framework::grade(checkGroupNameAndID("tadmins","885"));

	$verbose && print "John's UID is 2342:\t\t\t\t";
	Framework::grade(UserGroup::checkUserAttribute("john","UID","2342"));

	$verbose && print "john's home directory is /home/john:\t\t";
	Framework::grade(UserGroup::checkUserAttribute("john","HOME","/home/john"));

        $verbose && print "Mary's UID is 5556:\t\t\t\t";
        Framework::grade(UserGroup::checkUserAttribute("mary","UID","5556"));

	$verbose && print "Mary's default shell is /bin/bash:\t\t";
	Framework::grade(UserGroup::checkUserAttribute("mary","SHELL","/bin/bash"));
	
        $verbose && print "Thomas should not have access to any shell:\t";
        Framework::grade(UserGroup::checkUserAttribute("thomas","SHELL","/sbin/nologin"));

        $verbose &&  print "User john is in Group tadmins:\t\t\t";
        Framework::grade(checkUserGroupMembership("john","tadmins"));	

        $verbose &&  print "User mary is in Group tadmins:\t\t\t";
        Framework::grade(checkUserGroupMembership("mary","tadmins"));

	$verbose &&  print "User thomas isn't in Group tadmins:\t\t";
        Framework::grade(!(checkUserGroupMembership("thomas","tadmins")));

	$verbose &&  print "John's password is kuka002\t\t\t";
	Framework::grade(checkUserPassword("john","kuka002"));

        $verbose &&  print "Mary's password is kuka002\t\t\t";
        Framework::grade(checkUserPassword("mary","kuka002"));

        $verbose &&  print "Thomas's password is kuka002\t\t\t";
        Framework::grade(checkUserPassword("thomas","kuka002"));
	
        $verbose && print "john's account will expire on 2012-12-12\t";
        Framework::grade(checkUserChageAttribute("john","EXPIRE_DATE","2012-12-12"));

	## Running post
	&post();

	(($exercise_number == $exercise_success) && exit 0) || exit 1;
}

sub pre() {
	### Prepare the machine 
	$verbose and print "Running pre section\n";
}

sub post() {
	### Cleanup after succeful grade
	$verbose and print "\n=============================================================\n";
	$verbose and print "\n\tNumber of exercises: \t$exercise_number\n";
	$verbose and print "\n\tSuccessful: \t\t$exercise_success\n";
	if ($exercise_number == $exercise_success) {
	$verbose and print color 'bold green' and print "\n\n\tSuccessful grade.\n\n"  and print color 'reset';
	}
	else
	{
	$verbose and print color 'bold red' and print "\n\n\tUnsuccessful grade. Please try it again!\n\n"  and print color 'reset';
	}
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
