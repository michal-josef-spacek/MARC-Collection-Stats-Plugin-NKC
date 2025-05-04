use strict;
use warnings;

use MARC::Collection::Stats::Plugin::NKC;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Collection::Stats::Plugin::NKC::VERSION, 0.01, 'Version.');
