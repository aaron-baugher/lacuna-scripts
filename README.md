lacuna-scripts
==============

This is a random assortment of scripts that I wrote to automate various
functions in the game Lacuna Expanse.  It has a great, easy-to-use API that
makes it easy to automate the daily maintenance of your colonies, from
mining for glyphs to making sure your build queues are always busy.  My
scripts all use the Perl module Games::Lacuna::Client, which handles the
JSON-RPC backend and turns the server response into a single hash structure.

I started writing these scripts as practice in functional programming.  Each
script has a function which it then passes to a library function that
loops through all the planets/buildings and applies the first function to
each.  The idea was to keep the individual processing functions very simple
by putting as much of the API work and looping in the library as possible.

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

Before using these scripts, you will need to create a config file with your
player information.  Call it "lacuna.yml", place it in the same directory as
the scripts, and put these four lines with your info:

empire_name: <your empire name>
empire_password: <your empire password>
server_uri: https://us1.lacunaexpanse.com/
api_key: <get this from https://us1.lacunaexpanse.com/api/ApiKeys.html>

Since these scripts use API/RPC calls just as the web client does, it counts
against your per-minute and per-day RPC limits.  If you start getting a lot of
"Slow down!" messages from your scripts or the web client, you may need to run
the scripts less often or put "sleep" commands in them to slow them down.


