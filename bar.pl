#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use File::Basename;

# should be in the structure of
# section_name => {full_text, update_time}
my %sections;
my $sh_dir = dirname(__FILE__);

add_section('keyboard_layout', 'keyboard_layout.sh', update_time => 4, format => 'KBD[%]');
#add_section('keyboard_layout', 'KBD [' . 'setxkbmap -query | sed -En "s/layout:\s+(..)/\1/p"' . ']', 10);
add_section('loadavg', 'loadavg.sh', update_time => 5);
add_section('vpn', 'is_on_vpn.sh', update_time => 600, format => 'On VPN: %');
add_section('date_time', "date_time.sh");

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

	to_json(qw(vpn keyboard_layout loadavg date_time));

	print "],\n";
	sleep 1;
}

sub update
{
	for my $k (keys %sections)
	{
		my $update_time = $sections{$k}->{update_time};
		my $time_since_update = $sections{$k}->{time_since_update};
		die Dumper $k, \$sections{$k} unless $update_time;
		if($update_time == 1 or $time_since_update > $update_time) 
		{
			my $cmd = $sections{$k}->{cmd};
			my $result = sh($cmd, $sections{$k}->{is_sh});
			$sections{$k}->{full_text} = format_full_text($result, $sections{$k}->{format});
			$sections{$k}->{time_since_update} = 0;
		}
		else
		{
			$sections{$k}->{time_since_update}++;
		}
	}
}

sub to_json
{
	my $secs = [];
	for my $key (@_)
	{
		die Dumper \$sections{$key} unless $sections{$key};
		
		my $full_text = $sections{$key}->{full_text} // '';
		my $ft =  "{\"name\": \"$key\", \"full_text\":\"$full_text\"}";

		push(@{$secs}, $ft);
	}
	print(join(',', @$secs));
}

sub add_section
{
	my $name = shift;
	my $cmd = shift;
	my %args = @_;

	$args{update_time} //= 1; #update every seconds by default
	my $is_sh = $cmd =~ /.+\.sh/ ? 1 : 0;
	$sections{$name} = {
		cmd => $cmd, 
		full_text => '', 
		update_time => $args{update_time}, 
		# just some big number so that everything updates first loop
		time_since_update => 9999999999, 
		is_sh => $is_sh,
		format => $args{format}
	};
}

sub sh
{
	my ($cmd, $is_sh) = @_;
	my $shell_out = $is_sh ? `$sh_dir/$cmd` : `$cmd`;
	die ";;$shell_out" unless $shell_out;
	chomp $shell_out;
	return $shell_out;
}

sub format_full_text
{
	my ($full_text, $format) = @_;
	if($format)
	{
		$format =~ s/(.+)?%(.+)?/$1$full_text$2/;
		return $format;
	}
	return $full_text
}

#use Timer::Simple();
#my $long_wait;
sub get_weather
{
	my $time = localtime;
	#if ($time > 
}
