package Disk;
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
use Sys::Virt;
use Term::ANSIColor;
use Linux::LVM;
use XML::Simple;
use Data::Dumper;
BEGIN {
	use Exporter;

    	@Disk::ISA         = qw(Exporter);
    	@Disk::EXPORT      = qw( &lvm_free &lv_count &base &lv_remove &lv_create &xml_parse );
    	@Disk::EXPORT_OK   = qw( $verbose $topic $author $version $hint $problem $name);
	## We need to colse STDERR since Linux::LVM prints information to STDERR that is not relevant.
	close(STDERR);
}
use vars qw ($verbose $topic $author $version $hint $problem $name);

sub lvm_free() {
	## How much free space is on local vg
	my %vg_server= get_volume_group_information("vg_desktop");
	my $pe_size=$vg_server{'pe_size'};
	my $pe_free=$vg_server{'free_pe'};
	my $sum=$pe_size*$pe_free;
	return $sum;
}

sub lv_count() {
	my %lv=get_logical_volume_information("vg_desktop");
	$verbose and print "Our current lvs are: ";
	my $count=0;
	foreach my $lvname (sort keys %lv) {
		$verbose and print "$lvname ";
		$count+=1;
	}
	$verbose and print "\n";
	$verbose and print "Count is:$count\n";
	return $count;
}

sub base() {
	## Restore base setup for lvm setup on desktop
	$verbose and print "Base has been invoked.\n";
	print "Do you want me to restore base lvm number? [y/n] :";
	my $input = <STDIN>;
	chomp $input;
	outer: 
	while (1) { 
		if ( $input == "y" ) {
			$verbose and print "Yes selected. restoreing default state.\n";
			my %lv=get_logical_volume_information("vg_desktop");
			foreach my $lvname (sort keys %lv) {
				if ( $lvname == "LogVol00" or ($lvname == "LogVol01" or ($lvname == "server" or $lvname == "web") ) ) {
					$verbose and print "This is a base lv. Leaving.\n";
				} else {
					print "$lvname is a non base lv. We should delete it.\n";
					print "Is $lvname unused on internal server and can be deleted? [y/n] ";
					my $confirm = <STDIN>;
					chomp $confirm;
					inner:
					while (1) {
						if ( $confirm == "y" ) {
							$verbose and print "\nDeleting $lvname lv.\n";
							my $ret=&lv_remove("$lvname");
							if ( $ret eq 0) {
								print "$lvname was deleted succesfully.\n";
								last inner;
							} else {
								print "There was some problem deleting $lvname lv.\n";
								last inner;
							}
						} elsif ( $confirm == "n" ) {
							print "\nNot doing anything as requested.\n";
							last inner;
						} else {
							print "\n $confirm incorrect. Please answer y or n : ";
						}
					}
				}
			}
		last outer;
		} elsif ( $input == "n" ) {
			$verbose and print "\nNot restoring.\n";
			last outer;
		} else {
			print "\n $input incorrect. Please answer y or n : ";
		}
	}
}

sub lv_remove($) {
	## Removes lv
	my ($lvname)=@_;
	$lvname="/dev/mapper/vg_desktop-$lvname";
	$verbose and print "Removing $lvname.\n";
	my $xml=&xml_parse;
	$verbose and print "I got information.\n";
	$verbose and print Dumper($xml->{devices}->{disk});
	if ( ref($xml->{devices}->{disk}) eq "ARRAY" ) {
		$verbose and print "Referencing array.\n";
		my $length= @{$xml->{devices}->{disk}};
        	$verbose and print "My length is:$length\n";
        	for ( my $i=0; $i < $length; $i++ ) {
			$verbose and print "working on: ";
			print Dumper($xml->{devices}->{disk}->[$i]);
			if ( $lvname eq $xml->{devices}->{disk}->[$i]->{source}{dev} ) {
				$verbose and print "Found match.\n";
				my $target = $xml->{devices}->{disk}->[$i]->{target}{dev};
				$verbose and print "My target is:$target\n";
				system("virsh","detach-disk","server","$target");
			}
        	}
	} elsif ( ref($xml->{devices}->{disk}) eq "HASH" ) {
		$verbose and print "Referencing hash.\n";
		if ( $lvname eq $xml->{devices}->{disk}->{source}{dev} ) {
			my $target = $xml->{devices}->{disk}->{target}{dev};
			$verbose and print "My target is:$target\n";
			system("virsh","detach-disk","server","$target");
		}
	} else {
		$verbose and print "Unknown reference. Something has gone wrong.\n";
		exit 1;
	} 
	### After clearing the attachment, we can delete lv.
	my $return=`lvremove -t -f $lvname >/dev/null 2>\&1 ; echo \$?`;
	chomp $return;
	$verbose and print "My return for lvremove test is:$return\n";
	if ( $return eq 0 ) {
		$verbose and print "Lvremove test was succesful. Doing real remove.\n";
		my $ret=`lvremove -f $lvname >/dev/null 2>\&1 ; echo \$?`;
		if ( $ret eq 0 ) {
			$verbose and print "Removal was succesful.\n";
			return 0;
		} else {
			$verbose and print "There were errors during removal.\n";
			return 1;
		}
	} else {
		$verbose and print "Lvremove not succesful. We should investigate why.\n";
		return 1;
	}
}

sub lv_create($) {
	## Create lv
	## Size should be accoring to PE size.
	my ($lvname,$size)=@_;
	## Pre tests
	my $lv=get_lv_info("/dev/mapper/vg_desktop-$lvname");
	$verbose and print Dumper();
	my $free= &lvm_free;
	$verbose and print "Free space: $free\n";
	if ( $free lt $size ) {
		$verbose and print "I dont have enough free space. We should free up some space.\n";
		return 1;
	} else {
		$verbose and print "We have enough space.\n";
	}
	my %vg_server= get_volume_group_information("vg_desktop");
	my $unit=$vg_server{pe_size_unit};
	$verbose and print "My PE size unit:$unit\n";
	system();
}

sub xml_parse() {
	## Lets parse our server xml
	my $info=`virsh dumpxml server`;
	my $xml= new XML::Simple;
	my $data=$xml->XMLin( $info );
	#print Dumper($data->{devices}->{disk});
	#print "$#{$data->{devices}->{disk}}\n";
	return $data;
}

#### We need to end with success
1
