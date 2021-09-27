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
	warn Dumper @_;
	my %args = @_;
	warn Dumper \%args;
	die;
	my $job_data = {
		priority => $args{update_time},
		time_since_update => $args{time_since_update},
		cmd => $args{cmd}
	};
	my $job = new job($job_data);
	my @jobs = @{$self->{jobs}};
	if(not @jobs)
	{
		push(@jobs, $job);
	}
	else
	{
		for(my $i = 0; $i < scalar @jobs; $i++)
		{
			my $prio = $jobs[$i]->{priority};
			if($prio >= $job_data->{priority})
			{
				splice(@jobs, $i, 0, $job);
			}
		}
	}
}

sub list_jobs
{
	my $self = shift;
	use Data::Dumper;
	warn Dumper $self->{jobs};
}

1;
