#! /usr/bin/perl

# $Header:$

use strict;
use warnings;

use File::Basename;
use FileHandle;
use Getopt::Long;
use IO::File;
use POSIX;

my %stop_apps = (
	"firefox" => {},
	"chrome" => {},
	"torrent" => {},
	);

#######################################################################
#   Command line switches.					      #
#######################################################################
my %opts = (
	sleep => 2,
	);

my $last_t = 0;
sub do_stop_apps
{
	my $wins = `xwininfo -root -tree`;
	foreach my $app (sort(keys(%stop_apps))) {
		my $xwin_id = get_xwin_id($wins, $app);
		next if $stop_apps{$app}->{num} == 0;

		if ($stop_apps{$app}->{hidden} == $stop_apps{$app}->{num}) {
			if (!$stop_apps{$app}->{stopped}) {
				$stop_apps{$app}->{stopped} = 1;
				kill("STOP", keys(%{$stop_apps{$app}->{pids}}));
			}
		} else {
			if ($stop_apps{$app}->{stopped}) {
				$stop_apps{$app}->{stopped} = 0;
				kill("CONT", keys(%{$stop_apps{$app}->{pids}}));
			}
		}

		my $s = sprintf("%s %-12s %-7s %s\n",
			$stop_apps{$app}->{stopped} ? "S" : "R",
			$app, 
			$stop_apps{$app}->{hidden} == $stop_apps{$app}->{num} ? "hidden" : "open",
			join(" ", sort(keys(%{$stop_apps{$app}->{pids}}))),
			);
		if (time() > $last_t + 180 ||
		    $s ne ($stop_apps{$app}->{line} || '')) {
			print time_string() . $s;
			$stop_apps{$app}->{line} = $s;
			$last_t = time();
		}
		#print "$stop_apps{$app}->{num} $stop_apps{$app}->{hidden}\n";
	}
}

sub get_xwin_id
{	my $wins = shift;
	my $name = shift;

	$stop_apps{$name}->{running} = 0;
	delete($stop_apps{$name}->{pids});
	delete($stop_apps{$name}->{xids});
	$stop_apps{$name}->{hidden} = 0;
	$stop_apps{$name}->{num} = 0;

	foreach my $ln (split("\n", $wins)) {
		next if $ln !~ /$name/i;

		my $id = (split(" ", $ln))[0];
		$stop_apps{$name}->{xids}{$id} = 1;
		if ($id !~ /^0x[0-9a-f]/) {
			#print "bogus id ($id): $ln\n";
			next;
		}
#print "try $name $id\n";
		my $state = `xprop -id $id | grep _NET_WM_STATE`;
		chomp($state);
		if ($state) {
#			print time_string() . "$name: $id $state\n";
			if ($state =~ /HIDDEN/) {
				$stop_apps{$name}->{hidden}++;
			}
			$stop_apps{$name}->{num}++;
		}
	}

	my $fh = new FileHandle("ps -leaf |");
	while (<$fh>) {
		next if !/$name/i;
		next if /psg $name/;
		chomp;
		my $pid = (split(" ", $_))[3];
		next if $pid eq $$;
		$stop_apps{$name}->{pids}{$pid} = 1;
	}
}

sub main
{
	Getopt::Long::Configure('require_order');
	Getopt::Long::Configure('no_ignore_case');
	usage() unless GetOptions(\%opts,
		'help',
		'sleep=s',
		);

	usage(0) if $opts{help};

	if (@ARGV) {
		%stop_apps = ();
		$stop_apps{$_} = {} foreach @ARGV;
	}

	while (1) {
		do_stop_apps();
		sleep($opts{sleep});
	}
}

sub time_string
{
	return strftime("%Y%m%d %H:%M:%S ", localtime());
}

#######################################################################
#   Print out command line usage.				      #
#######################################################################
sub usage
{	my $ret = shift;
	my $msg = shift;

	print $msg if $msg;

	print <<EOF;
silent.pl - utility to stop processes when iconized
Usage: silent.pl [app1 app2]

  This tool was created to help reduce fan noise on an old laptop.
  Having apps like Firefox running, even when in the background,
  consumes CPU, generates heat, and makes the fan spin.

  Detecting if all the windows of the application are minimized, means
  we can send a SIGSTOP to the process, and drop CPU to zero. Hopefully
  even reducing thermals and fan noise.

  The script polls the listed applications, and sends a SIGSTOP if
  all the processes of the app are iconized, and sends SIGCONT, when
  any are uniconised.

  By default, the list of apps to check include firefox, chrome, bittorrent.
  But you can put the process names on the command line to customize.
  (The process names should be something that matches both "ps", and
  "xwininfo" output - typically the basename of the application is
  sufficient).

Example:

  Status is logged periodically, or when a process state changes.

  \$ silent.pl
  silent.pl
  20201217 10:12:24 S firefox      hidden  12593 29700 29904 29948 29979 30023
  20201217 10:12:24 S torrent      hidden  5695
  20201217 10:12:28 R firefox      open    12593 29700 29904 29948 29979 30023
  20201217 10:12:37 S firefox      hidden  12593 29700 29904 29948 29979 30023

  Here we see "S" for "stopped" ("R" for running). The numbers after "hidden"
  are the PID's of the processes. (Firefox/chrome will use a number of
  process slots, to support the tabbed mode of operation - this tool will
  stop all of these).

Switches:

Author:

  paul.d.fox\@gmail.com
  https://github.com/dtrace4linux/silent

EOF

	exit(defined($ret) ? $ret : 1);
}

main();
0;

