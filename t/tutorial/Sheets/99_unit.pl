#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/../../../lib";

use Test::Tutorial::Setup;

init_logger($DEBUG);

my $name = "Sheet1";
my $spreadsheet_name = spreadsheet_name();
my $sheets_api = sheets_api();

my $ss = $sheets_api->open_spreadsheet(name => $spreadsheet_name);
my $ws0 = $ss->open_worksheet(id => 0);
my $values = $ws0->col('A', [qw(joe)]);
warn Dump($values);
