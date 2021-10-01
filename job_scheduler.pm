package job_scheduler;

use job;
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);
use warnings;
use strict;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($WARN);

# 1 second at most so the timer can update once a second
my $max_time = 0.8;
my $ticks = 1;

sub new
{
	my ($class, $args) = @_;
	my $self = bless {
		jobs => []
	}, $class;
}

sub add_job
{
	my $self = shift;
	my %args = @_;
	my $job_data = {
		name => $args{name},
		update_time => $args{update_time},
		priority => $args{update_time}, # TODO
		time_since_update => $args{time_since_update},
		cmd => $args{cmd},
		avg_time => 0, # avg time to execute job
		update => 1
	};
	my $job = new job($job_data);
	if(not scalar @{$self->{jobs}})
	{
		push(@{$self->{jobs}}, $job);
	}
	else
	{
		my $pushed = 0;
		for(my $i = 0; $i < scalar @{$self->{jobs}}; $i++)
		{
			my $i_job = $self->{jobs}->[$i];
			my $prio = $i_job->{priority};
			if($prio >= $job_data->{priority})
			{
				splice(@{$self->{jobs}}, $i, 0, $job);
				$pushed = 1;
				last;
			}
		}
		push(@{$self->{jobs}}, $job) unless $pushed;
	}
	#$self->list_jobs();
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
	my $accumulated_time = 0;
	if($args{override}) # mostly only used for first run
	{
		if($args{signal_only})
		{
			for my $job (@{$self->{jobs}})
			{
				if($job->{update_time} == 0)
				{
					$self->_exec_job(job => $job, accumulated_time => \$accumulated_time );
				}
			}
		}
		else
		{
			for my $job (@{$self->{jobs}})
			{
				$self->_exec_job(job => $job, accumulated_time => \$accumulated_time );
			}
		}
	}
	else
	{
		for my $job (@{$self->{jobs}})
		{
			last if($accumulated_time > $max_time);
			next if($job->{update_time} == 0 or $max_time < $accumulated_time + $job->{avg_time});
			next if($job->{time_since_update} < $job->{update_time});

			$self->_exec_job(job => $job, accumulated_time => \$accumulated_time );
		}
	}
			
	WARN "Poor scheduling: $accumulated_time > max time ($max_time)" if($accumulated_time > $max_time);	
	$ticks++;
}

sub _exec_job
{
	my $self = shift;
	my $args = {@_};
	my $job = $args->{job};

	my $t = [gettimeofday];
	$job->exec();
	my $interval = tv_interval($t);
	$job->{time_since_update} += $interval;
	$args->{accumulated_time} += $interval;
	my $avg = $job->{avg_time};
	$job->{avg_time} = $avg + (($interval - $avg) / $ticks);
	$job->{update}++;
}
1;
