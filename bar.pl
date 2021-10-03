#!/usr/bin/perl

# update-time = 0 -> wait for signal SIGUSR1 
# update-time > 0 -> update every x seconds

use warnings;
use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use Data::Dumper;
use File::Basename;
use lib dirname(__FILE__);
use job_scheduler;
use Log::Log4perl qw(:easy);

Log::Log4perl->init(dirname(__FILE__) . '/logs/conf');
our $log = Log::Log4perl::get_logger("bar");

$log->info("Status bar start");

my %sections;
my $job_scheduler = new job_scheduler();

# read sections conf
my $conf_file = dirname(__FILE__) . '/cmds/cmds.conf';
open(my $conf_fh, '<', $conf_file) or die "could not open $conf_file";
while(my $row = <$conf_fh>)
{
	if($row !~ m/^#|^$/)
	{
		my @sec_params = eval $row;
		add_section(@sec_params);
	}
}


# signal handling for IPC
sub handle_signal
{
	$log->info("Signal received!");
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
	my $loop_start_t = [gettimeofday];
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
	my $loop_time = tv_interval($loop_start_t);
	$job_scheduler->time_since_last_loop($loop_time);
}

sub update
{
	my %args = @_;
	$job_scheduler->exec(@_);
	my $jobs = $job_scheduler->get_jobs();
	for my $k (keys %$jobs)
	{
		my $job = $jobs->{$k};
		if($job->{updated})
		{
			my $section = $sections{$job->{name}};
			$section->{full_text} = format_full_text($job->{full_text}, $section->{format});
			$job->{time_since_update} = 0;
			$job->{updated} = 0;
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
	$args{priority} //=1;
	
	my $id = scalar keys %sections;
	die Dumper \%args unless($cmd and $name);
	my $section = {
		name => $name,
		cmd => $cmd, 
		full_text => '', 
		update_time => $args{update_time}, 
		priority => $args{priority},
		# just some big number so that everything updates first loop
		time_since_update => 999.0, 
		format => $args{format}
	};
	$sections{$name} = {format => $section->{format}};
	
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
