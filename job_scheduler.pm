package job_scheduler;

use job;
use Data::Dumper;
use warnings;
use strict;

# 1 second at most so the timer can update once a second
my $max_time = 1; 
my $time_used = 0;

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
	warn Dumper \%args;
	my $job_data = {
		priority => $args{update_time},
		time_since_update => $args{time_since_update},
		cmd => $args{cmd}
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
	$self->list_jobs();
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
	my $override = shift;
	if($override)
	{
		for(my $job (@{$self->{jobs}}))
		{
			$job->exec();
		}
	}
}

1;
