lacuna-scripts
==============

Perl scripts that I've written for keeping my planets going in Lacuna
Expanse.

This is a random assortment of scripts that I wrote to automate various
functions in the game Lacuna Expanse.  It has a great, easy-to-use API that
makes it easy to automate the daily maintenance of your colonies, from
mining for glyphs to making sure your build queues are always busy.  My
scripts all use the Perl module Games::Lacuna::Client, which handles the
JSON-RPC backend and turns the server response into a single hash structure.

I started writing these scripts as practice in functional programming.  Each
script has a function which it then passes to a library function that
loops through all the planets/buildings and applies the first function to
each.  The idea was to keep the individual functions very simple by putting
as much of the API work and looping in the required function as possible.

These scripts evolved somewhat as my planets developed, so some of them were
useful for low-level planets (the 'trade' script that gathers all glyphs to
one planet where they can be combined, for instance), but became worthless
later.  See the docs in each script to find which are useful for you, and
certainly feel free to fork or modify them as you like for your own
purposes.

Lacuna Expanse is a fun, free, planet-building game that uses Perl on the
server end.  You can play competitively, where attacks between players are
possible, or stay out of the fighting with an independent planet -- and
change later if you wish.




