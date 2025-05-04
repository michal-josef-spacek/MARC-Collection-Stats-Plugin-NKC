use strict;
use warnings;

use MARC::Collection::Stats::Plugin::NKC::LargestPublishersSince;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Collection::Stats::Plugin::NKC::LargestPublishersSince->new;
isa_ok($obj, 'MARC::Collection::Stats::Plugin::NKC::LargestPublishersSince');
