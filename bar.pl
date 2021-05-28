#!/usr/bin/perl

# TODO update-time = 0 -> wait for signal SIGUSR1 

use warnings;
use strict;
use Data::Dumper;
use File::Basename;

# should be in the structure of
# section_name => {full_text, update_time}
my %sections;
my $sh_dir = dirname(__FILE__);
#my $ongoing = 0; # if signal occurs while ongoing = 1 erase old work and redo

add_section('keyboard_layout', 'keyboard_layout.sh', update_time => 0, format => 'KBD[%]');
add_section('loadavg', 'loadavg.sh', update_time => 5);
add_section('vpn', 'is_on_vpn.sh', update_time => 0, format => 'On VPN: %');
add_section('date_time', "date_time.sh", update_time => 0);
add_section('gpu_temp', "gpu_temp.sh", update_time => 5, format => 'GPU %c');
add_section('cpu_temp', "cpu_temp.sh", update_time => 5, format => 'CPU Cores 0[%c] 1[%c] 2[%c] 3[%c]');

# signal handling for IPC
sub handle_signal
{
	loop(1);
}

$SIG{USR1} = \&handle_signal;

# don't buffer output. Print outs are messed with if sleep is used.
$| = 1;

# beginning of json
print "{ \"version\": 1 }\n" or die;
print "[\n";
print "[],\n";

# just update everything once
loop(1);

while(1) 
{
	loop();
}

# this is since the loop will be repeated twice
# first time is simply to set all values once 
# so no section is left empty 
sub loop
{
	my $bar_text = '';
	$bar_text = '[';
	update(shift);
	$bar_text .= to_json(qw(vpn keyboard_layout cpu_temp gpu_temp loadavg date_time));
	$bar_text .=  "]";
	# check json 
	`echo '$bar_text' | jq; echo $?` ;
	if ($?)
	{
		$bar_text = "[\"name\":\"error\", \"full_text\":\"$?\"]";
	}
	$bar_text .= ",\n";
	print $bar_text;
	sleep 1;
}

sub update
{
	my $override = shift;
	for my $k (keys %sections)
	{
		my $update_time = $sections{$k}->{update_time} // 0;
		my $time_since_update = $sections{$k}->{time_since_update};
		if( ($time_since_update > $update_time ) or $override) 
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
	return join(',', @$secs);
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
	if($format and $full_text)
	{
		my $c = () = $format =~ /%/g; # count number of %
		if($c > 1)
		{
			map { $format =~ s/%/$_/ } split(' ', $full_text);
		}
		else
		{
			$format =~ s/(.+)?%(.+)?/$1$full_text$2/;
		}
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

