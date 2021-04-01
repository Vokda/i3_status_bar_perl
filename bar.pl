#!/usr/bin/perl

use warnings;
use strict;

# should be in the structure of
# section_name => {full_text, update_time}
my %sections;

add_section('keyboard_layout', 'setxkbmap -query | sed -En "s/layout:\s+(..)/\1/p"', 4);
#add_section('keyboard_layout', 'KBD [' . 'setxkbmap -query | sed -En "s/layout:\s+(..)/\1/p"' . ']', 10);
add_section('loadavg', 'cat /proc/loadavg | awk \'{print $1}\' ', 5);

add_section('id_time', "date +'%Y-%m-%d %H:%M:%S'");

# don't buffer output. Print outs are messed with if sleep is used.
$| = 1;

# beginning of json
print "{ \"version\": 1 }\n" or die;
print "[\n";
print "[],\n";

while(1)
{
	print '[';

	update();

	to_json(qw(keyboard_layout loadavg id_time));

	print '],';
	sleep 1;
}

sub update
{
	for my $k (keys %sections)
	{
		my $update_time = $sections{$k}->{update_time};
		my $time_since_update = $sections{$k}->{time_since_update};
		if($update_time == 1 or $time_since_update > $update_time) 
		{
			my $cmd = $sections{$k}->{cmd};
			if($sections{$k}->{is_sh})
			{
				$sections{$k}->{full_text} = sh($cmd);
				$sections{$k}->{time_since_update} = 0;
				warn "updating $k";
			}
			else
			{
				die "non shell commands not supported yet!";
			}
		}
		else
		{
			warn "not updating $k: $time_since_update <= $update_time";
			$sections{$k}->{time_since_update}++;
		}
	}
}

sub to_json
{
	my $secs = [];
	for my $key (@_)
	{
		my $ft =  "{\"name\": \"$key\", \"full_text\":\"$sections{$key}->{full_text}\"}";

		push(@{$secs}, $ft);
	}
	print(join(',', @$secs));
}

sub add_section
{
	my ($name, $cmd, $update_time) = @_;
	#push(@sections, "{\"name\": \"$name\", \"full_text\":\"$full_text\"}");
	$update_time //= '1'; #update every seconds by default
	# shell commands are default for now
	$sections{$name} = {
		cmd => $cmd, 
		full_text => '', 
		update_time => $update_time, 
		time_since_update => 30, # max int
		is_sh => 1
	};
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
