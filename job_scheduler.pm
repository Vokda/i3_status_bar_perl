package job_scheduler;

use job;
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);
use warnings;
use strict;
use Log::Log4perl qw(:easy);
our $log = Log::Log4perl::get_logger("job_scheduler");

# 1 second at most so the timer can update once a second
my $max_time = 0.8;
my $ticks = 1;

sub new
{
	my ($class, $args) = @_;
	my $self = bless {
		jobs => {}
	}, $class;
}

sub add_job
{
	my $self = shift;
	my %args = @_;
	my $job_data = {
		name => $args{name},
		update_time => $args{update_time},
		original_priority => $args{priority},
		priority => $args{priority}, # TODO
		time_since_update => $args{time_since_update},
		cmd => $args{cmd},
		avg_time => 0, # avg time to execute job
		updated => 1
	};
	my $job_data_dumped = '' . sprintf Dumper $job_data;
	$log->info("Job $job_data->{name} added: $job_data_dumped");
	die unless $args{cmd};
	my $job = new job($job_data);
	my $nr_jobs = scalar keys %{$self->{jobs}};
	my $pushed = 0;

	my $prio = $job->{priority};
	while(1)
	{
		if(not $self->{jobs}->{$prio})
		{
			$self->{jobs}->{$prio} = $job;
			last;
		}
		else
		{
			$prio++;
			next;
		}
	}
}

sub list_jobs
{
	my $self = shift;
	use Data::Dumper;
	warn Dumper "Jobs: ", $self->{jobs};
	warn Dumper "-----";
}

sub get_jobs
{
	my $self = shift;
	return $self->{jobs};
}

sub exec
{
	my $self = shift;
	my %args = @_;
	my $accumulated_time = 0.0;
	my $t = [gettimeofday];
	if($args{override}) # mostly only used for first run
	{
		if($args{signal_only})
		{
			for my $k (keys %{$self->{jobs}})
			{
				my $job = $self->{jobs}->{$k};
				if($job->{update_time} == 0)
				{
					$self->_exec_job(job => $job);
				}
			}
		}
		else
		{
			for my $k (keys %{$self->{jobs}})
			{
				my $job = $self->{jobs}->{$k};
				$self->_exec_job(job => $job);
			}
		}
	}
	else
	{
		for my $k (sort {$a <=> $b} keys %{$self->{jobs}})
		{
			my $job = $self->{jobs}->{$k};
			last if($accumulated_time > $max_time); # no more time, jobs will have to wait for next update
			next if($job->{update_time} == 0); # only update at signal

			# it hasn't been long enough since last update.
			# next if($job->{update_time} > 0 and $job->{time_since_update} < $job->{update_time});
			if($job->{time_since_update} <= $job->{update_time})
			{
				next;
			}

			$self->_exec_job(job => $job);
		}
	}


			
	$ticks++;
	my $interval = tv_interval($t);
	$accumulated_time += $interval;
	for my $k  (keys %{$self->{jobs}})
	{
		my $job = $self->{jobs}->{$k};
		$job->{time_since_update} += $accumulated_time;
	}
	if($accumulated_time > $max_time)	
	{
		$log->info("Poor scheduling: $accumulated_time > max time ($max_time)");
	}
}

sub time_since_last_loop
{
	my $self = shift;
	my $t = shift;
	map {$_->{time_since_update} += $t} values %{$self->{jobs}};
}

sub _exec_job
{
	my $self = shift;
	my $args = {@_};
	my $job = $args->{job};

	my $t = [gettimeofday];
	$job->exec();
	my $interval = tv_interval($t);

	my $avg = $job->{avg_time};
	$job->{avg_time} = $avg + (($interval - $avg) / $ticks);
	$job->{updated} = 1;
}
1;
