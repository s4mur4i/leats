#!/usr/bin/perl
#
use strict;
use warnings;
use Getopt::Long;
use Switch;
use File::Basename;
use Sys::Virt;
use Net::Ping;
#use Sys::Virt::Domain;
######
#Options
#
our ($topic, $author, $version, $hint, $problem, $name);
our $verbose=0;
our $help=0;
my $install=0;
my $reinstall=0;
use lib '/scripts/common_perl/';
use Framework qw($verbose $topic $author $version $hint $problem $name);


GetOptions("help|?" => \$help,
           "verbose|v" => \$verbose,
	   "i|install" => \$install,
	    "r|reinstall" => \$reinstall,
	);

sub useage() {
	print "Provisioning the guest\n";
	print "$0 \$options \n";
	print "i|install	Install the guest\n";
	print "r|reinstall	Reinstall the guest\n";
	};

if ( $help) {
	&useage;
}

sub install () {
	$verbose and print "Doing an install\n";
	my $args = "-n server" .
		   " --description \"Troubleshooting server \"".
		   " -r 512".
		   " --vcpus 1".
		   " -l http://desktop/".
		   " --os-type=linux".
		   " --os-variant=rhel6".
		   " --disk /dev/mapper/vg_desktop-server".
		   " --network bridge=br0,model=e1000".
		   " --network bridge=br0,model=e1000".
		   " --noautoconsole".
		   " --autostart".
		   " -x \"console=tty0".
		   " console=ttyS0,115200n8".
		   " ks=http://desktop/ks.cfg".
		   " ksdevice=link".
		   " ip=dhcp".
		   " method=http://desktop/".
		   "\"";
	$args .= " >/dev/null 2>&1" if (!$verbose);
	system("virt-install $args");
}

sub clean($) {
	my $con= Sys::Virt-> new (address=> "qemu:///system" ) ;
	my @doms=`virsh list --all | tail -n+3 | awk -F" " '(NF>0 ) {print \$2}'`;
        foreach my $dom (@doms) {
                $verbose and print "Found domain: $dom\n";
		chomp($dom);
                $verbose and print "Lets Destroy all domains before we continue.\n";
                $dom=$con->get_domain_by_name("$dom");
		if ( $dom->is_active() ) {
			$verbose and print "Domain is running, destroyin, and undefining.\n";
                	$dom->destroy();
                	$dom->undefine();
		} else {
			$verbose and print "Domain is not running, undefining.\n";
                	$dom->undefine();

		}
        }
}
if ( $install ) {
	&clean();
	print "Running install, May take up to 15 minutes.\n";
	my $time=0;
	&install;
	my $con= Sys::Virt-> new (address=> "qemu:///system" ) ;
	my $server= $con->get_domain_by_name("server");
	while ( $server->is_active() ) {
		sleep 15;
		$time +=15;
		print "Install still running..$time\\900 seconds\n";
		if ( $time > 901 ) {
			last;
		}
	};
	if ( $server->is_active() ) {
		print "Install is still active, or some error has happened. Please contact developers.\n";
		exit 10;
	};
	print "Install compeleted Succesfully in $time seconds.\n";
	print "Performing post test.\n";
	Framework::start;
	## Ping test if host is alive.
	my $p = Net::Ping->new();
	$time=0;
	my $succes=1;
	while ( $time < 46 ) {
		print "Testing if server is ready... $time\\45 seconds\n";
		$time += +5;
		if ( $p->ping("server") ) {
			$verbose and print "Server is up\n";
			$succes=0;
			last;
		} else {
			$verbose and print "Server is not up yet....\n";
			sleep 5;
		}
	}
	$p->close();
	if ( $succes ) {
		print "Post test Not complete. Maye Computer is only slow....\n";
	} else {
		print "Post test Complete.\n";
	}
} elsif ( $reinstall ) {
	&clean();
	print "Reinstall started....but it is just a plain install...\n";
		
}
