use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('MARC::Collection::Stats::Plugin::NKC', 'MARC::Collection::Stats::Plugin::NKC is covered.');
