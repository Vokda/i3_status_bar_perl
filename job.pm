package job;

use warnings;
use strict;
use File::Basename;

my $max_time = 1; # 1 second for the entire job
my $time_used = 0;
my $cmd_dir = dirname(__FILE__) . "/cmds";

sub new
{
	my ($class, $args) = @_;
	my %vars = %{$args};
	my $self = bless \%vars, $class;
}

sub exec
{
	my $self = shift;
	my $cmd = $self->{cmd};
	my $shell_out =`$cmd_dir/$cmd`;
	$self->{time_since_update} = 0;
	die ";;$shell_out" unless $shell_out;
	chomp $shell_out;

	$self->{full_text} = $shell_out;
}
1;
