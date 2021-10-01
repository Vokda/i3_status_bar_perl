#!/usr/bin/perl

# update-time = 0 -> wait for signal SIGUSR1 
# update-time > 0 -> update every x seconds

use warnings;
use strict;
use Data::Dumper;
use File::Basename;
use lib dirname(__FILE__);
use job_scheduler;

# should be in the structure of
# section_name => {full_text, update_time}
my %sections;
my $job_scheduler = new job_scheduler();
#my $ongoing = 0; # if signal occurs while ongoing = 1 erase old work and redo

add_section('keyboard_layout', 'keyboard_layout.sh', update_time => 0, format => 'KBD[%]');
add_section('loadavg', 'loadavg.sh', update_time => 5);
add_section('vpn', 'is_on_vpn.sh', update_time => 0, format => 'On VPN: %');
add_section('date_time', "date_time.sh", update_time => 1);
add_section('gpu_temp', "gpu_temp.sh", update_time => 5, format => 'GPU %c');
add_section('cpu_temp', "cpu_temp.sh", update_time => 5, format => 'CPU Cores 0[%c] 1[%c] 2[%c] 3[%c]');

#$job_scheduler->list_jobs();

# signal handling for IPC
sub handle_signal
{
	update(override => 1, signal_only => 1);
}

$SIG{USR1} = \&handle_signal;

# don't buffer output. Print outs are messed with if sleep is used.
$| = 1;

# beginning of json
print "{ \"version\": 1 }\n" or die;
print "[\n";
print "[],\n";

# just update everything once
update(override => 1);

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
	my $override = shift;
	update(override => $override);
	$bar_text .= to_json(qw(vpn keyboard_layout cpu_temp gpu_temp loadavg date_time));
	$bar_text .=  "]";
	# check json 
	`echo '$bar_text' | jq; echo $?` ;
	if ($?)
	{
		open(my $err_fh, '>>', 'error.log') or die "could not open error.log";
		print $err_fh `echo '$bar_text'| jq`;
		$bar_text = "[\"name\":\"error\", \"full_text\":\"$?\"]";
		close $err_fh;
	}
	$bar_text .= ",\n";
	print $bar_text;
	sleep 1;
}

sub update
{
	my %args = @_;
	$job_scheduler->exec(override => $args{override});
	for my $job (@{$job_scheduler->get_jobs()})
	{
		if($job->{update})
		{
			my $section = $sections{$job->{name}};
			$section->{full_text} = format_full_text($job->{full_text}, $section->{format});
			$section->{time_since_update} = 0;
			$job->{update} = 0;
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
	
	my $id = scalar keys %sections;
	my $section = {
		name => $name,
		cmd => $cmd, 
		full_text => '', 
		update_time => $args{update_time}, 
		# just some big number so that everything updates first loop
		time_since_update => 9999999999, 
		format => $args{format}
	};
	$sections{$name} = $section;
	
	$job_scheduler->add_job(%$section);
}

sub format_full_text
{
	my ($full_text, $format) = @_;
	$full_text =~ s/\n//; # newlines are a big no-no!
	if($format and $full_text)
	{
		my $c = () = $format =~ /%/g; # count number of %
		if($c > 1)
		{
			map { $format =~ s/%/$_/ } split(' ', $full_text);
		}
		else
		{
			$format =~ s/(.*)%(.*)/$1$full_text$2/;
		}
		return $format;
	}
	return $full_text
}
