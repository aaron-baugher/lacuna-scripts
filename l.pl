#!/usr/bin/env perl
#
# A set of routines for use in my Perl scripts for Lacuna Expanse.  See the other
# scripts found with this for examples.

use 5.010; use strict; use warnings;
use Data::Printer;
use FindBin;
use List::Util            qw(first);
# If you've downloaded the latest GLC with git, point to its location:
use lib '/home/abaugher/git/Games-Lacuna-Client/lib';
use Games::Lacuna::Client ();
use Games::Lacuna::Client::Types;
use Getopt::Long          qw(GetOptions);
use YAML::Any             qw(LoadFile DumpFile Dump);
use Fcntl qw(:flock);
$|=1;

my $client = Games::Lacuna::Client->new(
    cfg_file => 'lacuna.yml',
    # debug    => 1,
);
my $c = load_cache();

my $empire  = $client->empire->get_status->{empire};
my $planets = $empire->{planets};

# Build a timestamp for now
my @gm = gmtime;
$gm[5]+=1900; $gm[4]++;
my $now = sprintf "%04d %02d %02d %02d %02d %02d", @gm[5,4,3,2,1,0];

# Get the basic stats from the server, when nothing else is needed as part of the call.
sub get_stats {
    my $processor = shift;
    my $s = $client->stats->empire_rank();
    return $s;
}

# Get a GLC object.
sub get_client {
    return $client;
}

# Loop through the planets, and run a routine on each planet's building hash
sub for_each_planet_get_buildings {
    my $processor = shift;
    for my $pid ( sort { $planets->{$a} cmp $planets->{$b} } keys %$planets ) {
        my $pname = $planets->{$pid};
        my $planet = $client->body( id => $pid )->get_buildings;
        $processor->($client, $planet, $pid);
    }
    save_cache($c);
}

# Loop through the planets and run a routine on each planet's planet hash
sub for_each_planet {
    my $processor = shift;
    for my $pid ( sort { $planets->{$a} cmp $planets->{$b} } keys %$planets ) {
        my $pname = $planets->{$pid};
        my $planet = $client->body( id => $pid )->get_status;
        $processor->($client, $planet, $pid);
    }
    save_cache($c);
}

# Run a routine on one planet's hash
sub one_planet {
    my $processor = shift;
    my $pname = shift;
    my $pid = first { $planets->{$_} eq $pname } keys %$planets;
    unless( $pid ){
        say "No such planet found.";
        return;
    }
    my $planet = $client->body( id => $pid );
    $processor->($client, $planet, $pid);
    save_cache($c);
}

# Run a routine on a particular building on a particular planet
sub one_planet_one_building {
    my $processor = shift;
    my $pname = shift;
    my $building_name = shift;
    my $options = shift;
   
    my $pid = first { $planets->{$_} eq $pname } keys %$planets;

    unless( $pid ){
        say "No such planet found.";
        return;
    }
    if ( $options->{always_rescan} ) {
        $c->{planets}{$pname}{buildings} = undef;
    }
    my $buildings = $c->{planets}{$pname}{buildings};
    if ( ! $buildings ) {
        # Load planet data
        my $body      = $client->body( id => $pid );
        my $result    = $body->get_buildings;
        $buildings = $result->{buildings};
        $c->{planets}{$pname}{buildings} = $buildings;
        say '...saving buildings cache for ', $pname;
        save_cache($c);
    }
    # Find the right building
    my $bid = first {
        $buildings->{$_}->{name} eq $building_name
    } sort { $options->{highfirst} ? $buildings->{$b}{level} <=> $buildings->{$a}{level} :
                                     $buildings->{$a}{level} <=> $buildings->{$b}{level} } keys %$buildings;
    if (! $bid and $options->{always_rescan} ) {
        # Load planet data
        my $body      = $client->body( id => $pid );
        my $result    = $body->get_buildings;
        $buildings = $result->{buildings};
        $c->{planets}{$pname}{buildings} = $buildings;
        say '...saving buildings cache for ', $pname;
        save_cache($c);
        # Find the right building
        $bid = first {
            $buildings->{$_}->{name} eq $building_name
        } keys %$buildings;
    }
    return unless $bid;
    $processor->($client, $planets, $pid, $buildings, $bid);
}

# Run a routine on a particular building on all planets
sub for_each_planet_one_building {
    my $processor = shift;
    my $building_name = shift;
    my $options = shift;
    
    for my $pid ( sort { $planets->{$a} cmp $planets->{$b} } keys %$planets ) {
        my $pname = $planets->{$pid};
        my $buildings = $c->{planets}{$pname}{buildings};
        unless( $buildings ){
            # Load planet data
            my $body      = $client->body( id => $pid );
            my $result    = $body->get_buildings;
            $buildings = $result->{buildings};
            $c->{planets}{$pname}{buildings} = $buildings;
            say '...saving buildings cache for ', $pname;
            save_cache($c);
        }
        # Find the right building
        my $bid = first {
            $buildings->{$_}->{name} eq $building_name
        } keys %$buildings;

        if (! $bid and $options->{always_rescan}) {
            # Load planet data
            my $body      = $client->body( id => $pid );
            my $result    = $body->get_buildings;
            $buildings = $result->{buildings};
            $c->{planets}{$pname}{buildings} = $buildings;
            say '...saving buildings cache for ', $pname;
            save_cache($c);
            # Find the right building
            $bid = first {
                $buildings->{$_}->{name} eq $building_name
            } keys %$buildings;
        }
        next unless $bid;
        $processor->($client, $planets, $pid, $buildings, $bid);
    }
}

# load the cache file containing planet and building info
sub load_cache {
    my $n = shift || 'cache.yml';
    my $c;
    eval { $c = LoadFile($n); };
    $c = {} unless $c;
    return $c;
}

# save the cache file containing planet and building info
sub save_cache {
    my $c = shift;
    my $n = shift || 'cache.yml';
    open my $out, '>', $n or die $!;
    flock($out, LOCK_EX) or die $!;
    print $out Dump($c);
    flock($out, LOCK_UN) or die $!;
    close $out;
    return 1;
}

# Take a number and return it in K with underscore separators
sub num {
    my @nums = @_;
    for (@nums) {
        my $s = $_;
        $_ /= 1000;             # if $s > 999_999_999;
        my $n = reverse int $_;
        $n =~ s/(\d\d\d)(?=\d)/$1_/g;
        $_ = scalar reverse $n;
		
    }
    return @nums;
}

# alpha sort routine
sub alpha {
    return $a cmp $b;
}

# Build a hash tying all resources as keys to their types as values.
# NOTE:
# Might be useful to make this stateful, if I ever write something that
# runs continuously or uses it many times.
sub get_resource_hash {
    my $dir = shift;
    my %r = ( energy => ['energy'],
              water  => ['water'],
              waste  => ['waste'],
              food   => [qw[ algae  apple  bean beetle bread
                             burger cheese chip cider  corn
                             fungus lapis  meal milk   pancake
                             pie    potato root shake  soup
                             syrup  wheat ]],
              ore =>   [qw[ anthracite bauxite  beryl     chalcopyrite
                            chromite   fluorite galena    goethite
                            gold       gypsum   halite    kerogen
                            magnetite  methane  monazite  rutile
                            sulfur     trona    uraninite zircon ]],
          );
    return \%r if $dir;
    my %h;
    for my $k (keys %r) {
        $h{$_} = $k for (@{$r{$k}});
    }
    return \%h;
}

# Expand abbreviated input of resource names into complete name
sub resname {
    my $o = lc shift;
    my %r = %{get_resource_hash()};
    my $n = first { $_ =~ /\A$o/ } keys %r;
    return( $n or $o );
}

# Simple routine to return a building's name from its type.
# NOTE:
# This is really unnecessary; bname() does this and more,
# and GLC does it too.  Should remove.
sub building_type {
    my $n = shift;
    return( bname($n)->{type} or $n );
}

# Turn a number of seconds into a DD:HH:MM:SS clock value.
sub secs2clock {
    my @n;
    for my $t (@_) {
        $t ||= 0;
        my $neg;
        if ( $t < 0 ) {
            $neg = 1;
            $t *= -1;
        }
        my $s;
        if ( ! $t ) {
            $s = '0:00';
            $t = 0;
        } elsif ( $t < 60 ) {
            $s = sprintf "0:%02d", $t;
        } else {
            my $ss = $t%60;
            my $mm = int($t/60%60);
            my $hh = int($t/(60*60)%24);
            my $dd = int($t/(24*60*60));
            $s = sprintf "%d:%02d:%02d:%02d", $dd, $hh, $mm, $ss;
            $s =~ s/^[0:]+//;
        }
        if ( $t < 3600*8 ) {
            #			$s .= '   ******';
        }
        $s = "-$s" if $neg;
        push @n, $s;
    }
    return wantarray ? @n : $n[0];
}	


# Takes a string, compares to a list of building types,
# and returns a hash with the matching building type and name
# NOTE:
# If it fails, it returns the match value for both.  Needed that once to match a building
# that wasn't in the list yet, but now that shouldn't happen, so that should probably
# be changed to something useful like a warning.
sub bname {
    my $o = shift;
    my %bt;
    my @types  = Games::Lacuna::Client::Types::building_types();
    my @labels = Games::Lacuna::Client::Types::building_labels();  # is destroyed
    for my $tt (@types) {
        $bt{$tt} = shift @labels;
    }
    my $t = first { /^$o/i } sort keys %bt;
    if ( $t and $bt{$t} ) {
        return({ type => $t, name => $bt{$t} });
    } else {
        return({ type => $o, name => $o });
    }
}

1;
