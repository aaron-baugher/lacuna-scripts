#!/usr/bin/env perl
use 5.10.0;
use List::Util qw(first);
$|=1;

require 'l.pl';
my $source = 'Brinn';      # set to the name of your excavator-building planet
die "Usage: exs Destination" unless $ARGV[0];

sub doit {
    my $client = shift;
    my $planets = shift;
    my $pid = shift;
    my $buildings = shift;
    my $bid = shift;
    
    my $dest = first { $planets->{$_} eq $ARGV[0] } keys %$planets;
    die "Planet not found!" unless $dest;
    my $bb = $client->building( id => $bid, type => 'Trade' );
    my $ss = $bb->get_ships();
    
    my @excavators = map { { type  => 'ship', ship_id => $_->{id} }}
        grep { $_->{type} eq 'excavator' } @{$bb->get_ships()->{ships}};
    my $on_source = @excavators;
    splice @excavators, 6;
    my $sent = @excavators;
    $on_source -= $sent;
    
    my $ships = $bb->get_trade_ships()->{ships};
    my $ship = (sort { $b->{speed} <=> $a->{speed} or            # fastest
                       $a->{hold_size} <=> $b->{hold_size} }     # or smallest
                    grep { $_->{hold_size} >= 300_000 }   # as long as it's big enough
                    @{$ships})[0];
    unless( $ship ){
        say 'No large enough ships available for pushing.';
        next;
    }
    my $ship_id = $ship->{id};
    my $pp = $bb->push_items($dest, \@excavators, { ship_id => $ship_id });
    say "Pushed $sent excavators to $ARGV[0], $on_source remaining on $source";
}

one_planet_one_building(\&doit, $source, 'Trade Ministry');

=head1 Name

exs - Send 6 excavators to a planet

=head1 Usage

./exs [Planet]

=head1 Description

This script sends 6 excavators from your shipbuilding planet (named near the
top of the script) to whichever planet you specify.  It sends 6 because that's
the maximum that can fit in a Smuggler Ship, the fastest ship available; but
it will use the fastest ship you have which is large enough.

This script is called by the B<e> script which checks planets and makes sure
they don't run out of excavators.

=head1 Requirements

Uses custom routines in l.pl, which should be found where this script was.

=head1 See Also

https://github.com/aaron-baugher/lacuna-scripts

=head1 Author

Aaron Baugher - aaron.baugher.biz

=cut

