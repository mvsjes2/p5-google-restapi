#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/../../../lib";

use Test::Tutorial::Setup;

init_logger($DEBUG);

my $name = "Sheet1";
my $spreadsheet_name = spreadsheet_name();
my $sheets_api = sheets_api();

my $ss = $sheets_api->create_spreadsheet(title => $spreadsheet_name);
#$ss->named_ranges();

my $ws0 = $ss->open_worksheet(id => 0);
$ws0->cols(['B','C','D'], [['Customer ID'], ['Customer Name'], ['Address']]);
$ws0->rows([2,3], [['Sam Brady'], ['George Jones']]);

$ws0->range("D4:E5")->values();
$ws0->range("D4:E5")->values(values => [["Halifax"]]);
$ws0->spreadsheet()->cache_seconds(0);
$ws0->range("D4:E5")->values();

#$ws0->cols([qw(A B C)]);
#my $values = $ws0->cols([qw(A B C)], [['joe'],['fred'], ['charlie']]);
#$ws0->rows([qw(1 2 3)]);
#my $values = $ws0->rows([qw(1 2 3)], [['joe'],['fred'], ['charlie']]);
#$ws0->cells([qw(A1 B1 C1)], [qw(joe fred charlie)]);
#$ws0->col('A');
#$ws0->row(1);
$sheets_api->delete_all_spreadsheets($spreadsheet_name);
