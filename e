#!/usr/bin/env perl
use 5.010; use strict; use warnings;
use List::Util qw(first);
$|=1;

my $shipyard_planet = 'Brinn'; # set to the planet with your best shipyard
my $esent = 0;

require 'l.pl';

sub doit {
    my $client = shift;
    my $planets = shift;
    my $pid = shift;
    my $buildings = shift;
    my $bid = shift;
    
    my $bb = $client->building( id => $bid, type => 'Archaeology' );
    my $v = $bb->view_excavators( id => $bid );
    my $eout = scalar @{$v->{excavators}};
    my $emax = $v->{max_excavators};
    my $etra = $v->{travelling};
    $eout--;

    if ( $eout + $etra != $emax ) {
        say "$planets->{$pid} can handle $emax excavators and has $eout in place and $etra travelling";
    }

    $bid = first { $buildings->{$_}->{url} eq '/spaceport' } 
        keys %$buildings;
    $bb = $client->building( id => $bid, type => 'SpacePort' );
    my @e = grep { $_->{type} eq 'excavator' } 
        @{$bb->view_all_ships({no_paging => 1})->{ships}};
    my $e = @e;
    if ( $e < 20 ) {
        say "$planets->{$pid} down to $e excavators in storage";
        say `./exs $planets->{$pid}` unless $planets->{$pid} eq 'Altare';
        $esent += 6;
    }
    sleep 2;
}

for_each_planet_one_building(\&doit, 'Archaeology Ministry');

if ($esent){
    $esent = $esent > 30 ? 30 : $esent;  # no more than 30
    say `./build-ships $shipyard_planet excavator $esent 2>&1`;
}

=head1 Name

e - Check and replace excavators

=head1 Usage

./e

=head1 Description

This script checks each planet to see if it has the maximum number of
excavators deployed.  It reports any that do not.  It also calls the B<exs>
program to ship more excavators from your main shipyard planet to any planet
that has fewer than 20 docked.

After all checks are complete, it builds up to 30 new excavators at your
shipyard planet to replace the old ones.

This is a good script to run as a daily cron task.

=head1 Requirements

Uses custom routines in l.pl, which should be found where this script was.

=head1 See Also

https://github.com/aaron-baugher/lacuna-scripts

=head1 Author

Aaron Baugher - aaron.baugher.biz

=cut

