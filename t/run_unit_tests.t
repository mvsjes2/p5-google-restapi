#!/usr/bin/env perl

# run this with 'prove -v run_unit_tests' to run them all in verbose mode.

# to test a single class:
# TEST_CLASS='Test::Google::RestApi::SheetsApi4::Range::Col' prove -v t/run_unit_tests.t

use strict;
use warnings;

use FindBin;
use Module::Load;

use Test::Class;

use lib "$FindBin::RealBin/../lib";   # the rest::api code
use lib "$FindBin::RealBin/lib";      # the support code for these tests.
use lib "$FindBin::RealBin/unit";

if ($ENV{TEST_CLASS}) {
    load($ENV{TEST_CLASS});
} else {
    load('Test::Class::Load');
    Test::Class::Load->import("$FindBin::RealBin/unit");
}

Test::Class->runtests();
