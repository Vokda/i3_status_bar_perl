package job;

use warnings;
use strict;

my $max_time = 1; # 1 second for the entire job
my $time_used = 0;

sub new
{
	my ($class, $args) = @_;
	my $self = bless {}, $class;
}



1;
