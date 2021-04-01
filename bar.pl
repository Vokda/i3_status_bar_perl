#!/usr/bin/perl

use warnings;
use strict;

my @sections;
$| = 1;

print "{ \"version\": 1 }\n" or die;

print "[\n";

print "[],\n";

while(1)
{
	print '[';

	add_section('keyboard_layout', 'KBD [' . sh('setxkbmap -query | sed -En "s/layout:\s+(..)/\1/p"') . ']');

	add_section('loadavg', sh('cat /proc/loadavg | awk \'{print $1}\' '));

	my $date_time = `date +'%Y-%m-%d %H:%M:%S'`;
	chomp $date_time;
	add_section('id_time', $date_time);

	print(join(',', @sections));
	@sections = ();

	print '],';
	sleep 1;
}

sub add_section
{
	my ($name, $full_text) = @_;
	push(@sections, "{\"name\": \"$name\", \"full_text\":\"$full_text\"}");
}

sub sh
{
	my ($cmd) = @_;
	my $shell_out = `$cmd`;
	chomp $shell_out;
	return $shell_out;
}

#use Timer::Simple();
#my $long_wait;
sub get_weather
{
	my $time = localtime;
	#if ($time > 
}
