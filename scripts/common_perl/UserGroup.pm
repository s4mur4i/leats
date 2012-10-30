package UserGroup;
### This Module are common subroutines used in the script.
#This file is part of Leats.
#
#Leats is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#Leats is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with Leats.  If not, see <http://www.gnu.org/licenses/>.
use strict;
use warnings;
use Term::ANSIColor;
use Data::Dumper;
use POSIX qw(ceil);
use Switch;

BEGIN {
	use Exporter;

	@UserGroup::ISA         = qw(Exporter);
	@UserGroup::EXPORT      = qw( &userExist &groupExist &getUserAttribute &checkUserAttribute &checkUserPassword &checkUserGroupMembership &checkUserSecondaryGroupMembership &checkUserPrimaryGroup &checkGroupNameAndID &checkUserChageAttribute);
	@UserGroup::EXPORT_OK   = qw( $verbose $topic $author $version $hint $problem $name $exercise_number $exercise_success);
}
use vars qw ($verbose $topic $author $version $hint $problem $name);

#Check if user exist
#1. Paramter: username (not ID!)
sub userExist($) 
{
	my $User = $_[0];
	my $line;
	my $ssh=Framework::ssh_connect;
        my $output=$ssh->capture("cat /etc/passwd");
	my @lines = split("\n",$output);
	foreach $line (@lines)
	{
		 if ($line =~ m/^$User:.*$/) {  return 0; }
	}
	#if User not exist in passwd
	return 1;
}

#Check if group exist
#1. Parameter: groupname (not ID!)
sub groupExist($)
{
	my $Group = $_[0];
	my $line;

	my $ssh=Framework::ssh_connect;
        my $output=$ssh->capture("cat /etc/group");
        my @lines = split("\n",$output);
	foreach $line (@lines)
        {
		 if ($line =~ m/^$Group:.*$/) { return 0; }  
	}
	#if Group not exist in /etc/group
	return 1;
}

#Return the attribute of the user from passwd
#Example from /etc/passwd: 	ftp:x:14:50:FTP User:/var/ftp:/sbin/nologin
#1. Parameter: Username
#2. Parameter:
#	UID - User ID
#	GID - Primary Group ID
#	DESC - Description of the user
#	HOME - Home of the user
#	SHELL - Shell of the user
sub getUserAttribute($$)
{
	my $User = $_[0];
	my $P = uc($_[1]);

	if (userExist($User) != 0 ) { $verbose && print "\nUser $User not exist!\n"; exit 1; 
					}
	if (($P ne "UID" ) && ($P ne "GID" ) && ($P ne "DESC" ) && ($P ne "HOME" ) && ($P ne "SHELL" )) 
	{ 
		$verbose && print "\nInvalid Attribute: $P!\n"; exit 1;  
		return undef;
	}

	my @A=();
	my $line;

        my $ssh=Framework::ssh_connect;
        my $output=$ssh->capture("cat /etc/passwd");
        my @lines = split("\n",$output);
        foreach $line (@lines)
        {
		if (@A = $line =~ m/^$User:[^:]*:(\d+):(\d+):([^:]*):([^:]+):([^:]+)$/) 
		{ 
			switch ($P) {
				case "UID" { return $A[0]; }
				case "GID" { return $A[1]; }
				case "DESC" { return $A[2]; }
				case "HOME" { return $A[3]; }
				case "SHELL" { chomp($A[4]); return $A[4]; }
			}
		} 
	}

#	If parameter could not be found
	$verbose && print "\nThe $P of User $User could not be found!\n";
	return 1;
}

#Check users Attribute
#
#Return values:
#0: Correct
#1: Not correct
#
#1.Parameter: Username (not ID!)
#2.Parameter:
#       UID - User ID
#       GID - Primary Group ID
#       DESC - Description of the user
#       HOME - Home of the user
#       SHELL - Shell of the user
#3.Parameter: Value of the Attribute
#example:  checkUserAttribute("john","UID","688")
sub checkUserAttribute($$$)
{
	my $User = $_[0];
	my $P = $_[1];
	my $Value = $_[2];
	my $AttributeValue = getUserAttribute($User,$P);

	if (($P eq "HOME")) 
	{
		$Value = "${Value}/"; $Value=~s@/+@/@g; 
		$AttributeValue = "${AttributeValue}/"; $AttributeValue=~s@/+@/@g;;
	} 

	(($Value eq $AttributeValue) && return 0) || return 1;
}

#Check users password
#
#1.Parameter: Username (not ID!)
#2.Parameter: Password
#
#Example: checkUserPassword("john","secretPassword");
sub checkUserPassword($$)
{
	my $User = $_[0];
	my $P = $_[1];

	my $line;
	my @A;


        my $ssh=Framework::ssh_connect;
        my $output=$ssh->capture("cat /etc/shadow");
        my @lines = split("\n",$output);
        foreach $line (@lines)
        {
		if (@A = $line =~ m/^$User:\$(\d+)\$([^:]+)\$([^:]*):.*$/)
		{
                                if ("\$${A[0]}\$${A[1]}\$${A[2]}" eq crypt("$P", "\$$A[0]\$" . "$A[1]")) { return 0; }
                                else { return 1; }
		}
	}	

	return 1;
}

#
# Returns the groupname of the ID you give as 1.Parameter
#
# 1.Parameter: GroupID
#
sub getGroupName($)
{
	my $GroupID = $_[0];
        my $line;
        my @M;

	my $ssh=Framework::ssh_connect;
        my $output=$ssh->capture("cat /etc/group");
        my @lines = split("\n",$output);
        foreach $line (@lines)
        {
		if (@M = $line =~ m/^([^:]+):x:$GroupID:.*$/){ return $M[0];  }
	}
	return undef;
}

#
#Check the group ID of the group
#
#1. Parameter: Groupname
#2. Parameter: GroupID
#
#Return value is 0 if the groupID related to the groupname 
sub checkGroupNameAndID($$)
{
	my $GroupName = $_[0];
        my $GroupID = $_[1];
        my $line;
        my @M;

        my $ssh=Framework::ssh_connect;
        my $output=$ssh->capture("cat /etc/group");
        my @lines = split("\n",$output);
        foreach $line (@lines)
        {
                if (@M = $line =~ m/^$GroupName:x:$GroupID:.*$/){ return 0;  }
        }
        return 1;
}




#Check if User is member of the group
#It checks only the secondary groups
#
#1.Parameter: Username (not ID!)
#2.Parameter: Groupname (not ID!)
#
#Example: checkUserSecondaryGroupMembership("john","admins");
sub checkUserSecondaryGroupMembership($$)
{
	my $User = $_[0];
	my $Group = $_[1];
	my $line;
	my @M;

        my $ssh=Framework::ssh_connect;
        my $output=$ssh->capture("cat /etc/group");
        my @lines = split("\n",$output);
        foreach $line (@lines)
        {
		if (@M = $line =~ m/^$Group:x:\d+:([^:]*)$/) 
		{ 	
			chomp($M[0]);
			my @Members = split(",",$M[0]);
			my $Member;
			foreach $Member (@Members) { ($User eq $Member) && return 0; }		
		}
	}
	return 1;
}

#Check users primary group 
#
#1.Parameter: Username (not ID!)
#2.Parameter: Groupname (not ID!)
#
sub checkUserPrimaryGroup($$)
{
	my $User = $_[0];
	my $Group = $_[1];

	if ($Group eq getGroupName(UserGroup::getUserAttribute("$User","GID"))) { return 0; }
	else {	return 1; }
}

#Check users group memberships
#If checks primary and secondary groups also
#
#Return value is 0 if user is member of the group else 1
#
#1.Parameter: Username (not ID!)
#2.Parameter: Groupname (not ID!)
#
sub checkUserGroupMembership($$)
{
	my $User = $_[0];
	my $Group = $_[1];
	if ((checkUserPrimaryGroup($User,$Group)==0) || (checkUserSecondaryGroupMembership($User,$Group)==0)) { return 0 ; }
	else { return 1; }
}

#Check the Users user password expiry information
#
#EXPIRE_DATE - Account expires (date format: YYYY-MM-DD)                         
#INACTIVE - Password inactive
#MIN_DAYS - Minimum number of days between password change
#MAX_DAYS - Maximum number of days between password change   
#WARN_DAYS - Number of days of warning before password expires
#
#
#Examples: 
#1. The User tom's account should expire in 2025-12-10:
#checkUserChageAttribute("tom","EXPIRE_DATE","2025-12-10");
#
#2. The warning days should be 12 before the password expires:
#checkUserChageAttribute("tom","WARN_DAYS","12");
#
#Return Value is 0 when the Attribute is correct, else it returns with 1.
#
sub checkUserChageAttribute($$$)
{
        my $User = $_[0];
        my $P = $_[1];
        my $Value = lc($_[2]);

	if (($P eq "EXPIRE_DATE") && ($Value =~ m@\d{4}-\d{2}-\d{2}@)){ $Value=`date +%s -d "$Value"`; $Value=ceil($Value/86400);  }
	elsif ($Value eq "never") { $Value=""; }
	
	my $line;
	my @A;
	my $ssh=Framework::ssh_connect;
	my $output=$ssh->capture("cat /etc/shadow");
	my @lines = split("\n",$output);
	foreach $line (@lines)
	{  
		if (@A = $line =~ m/^$User:[^:]*:([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):.*$/)
		{
			switch ($P) 
			{
				case "EXPIRE_DATE" { ((${A[5]} eq $Value) && return 0) || return 1;  }
				case "INACTIVE" { ((${A[4]} eq $Value) && return 0) || return 1; 	}
				case "MIN_DAYS" { ((${A[1]} eq $Value) && return 0) || return 1; }
				case "MAX_DAYS" { ((${A[2]} eq $Value) && return 0) || return 1;}
				case "WARN_DAYS" { ((${A[3]} eq $Value) && return 0) || return 1;}
			}
		}
	}	
	return 1;
}

#We need to end with success
1
