use Test::Integration::Setup;

use Test::Most tests => 34;

use aliased "Google::RestApi::SheetsApi4::Range::Cell";
use aliased "Google::RestApi::SheetsApi4::Range::Iterator";

# use Carp::Always;
# init_logger($DEBUG);

delete_all_spreadsheets(sheets_api());

my $spreadsheet = spreadsheet();
my $ws0 = $spreadsheet->open_worksheet(id => 0);

my @values = (
  [ 1,  2,  3,  4],
  [ 5,  6,  7,  8],
  [ 9, 10, 11, 12],
  [13, 14, 15, 16],
);

my ($range, $i, $cell);

$range = $ws0->range("A1:D4");
$range->values(values => \@values);

iterate_by_col();
iterate_by_row();
iterate_by_2_by_row();
iterate_by_10_by_row();

sub iterate_by_col {
  isa_ok $i = $range->iterator(dim => 'col'), Iterator, "Col iterator creation";
  isa_ok $cell = $i->next(), Cell, "First col iteration";
  is $cell->values(), 1, "First col iteration should be '1'";
  isa_ok $cell = $i->next(), Cell, "Second col iteration";
  is $cell->values(), 2, "Second col iteration should be '2'";
  $cell = $i->next() for (1..3);
  is $cell->values(), 5, "Col iteration to next row should be '5'";
  $cell = $i->next() for (1..11);
  is $cell->values(), 16, "Col iteration to last cell should be '16'";
  is $cell = $i->next(), undef, "Last col iteration should be undef";
  return;
}

sub iterate_by_row {
  isa_ok $i = $range->iterator(), Iterator, "Row iterator creation";
  isa_ok $cell = $i->next(), Cell, "First row iteration";
  is $cell->values(), 1, "First row iteration should be '1'";
  isa_ok $cell = $i->next(), Cell, "Second row iteration";
  is $cell->values(), 5, "Second row iteration should be '5'";
  $cell = $i->next() for (1..3);
  is $cell->values(), 2, "Row iteration to next col should be '2'";
  $cell = $i->next() for (1..11);
  is $cell->values(), 16, "Row iteration last cell should be '16'";
  is $cell = $i->next(), undef, "Last row iteration should be undef";
  return;
}

sub iterate_by_2_by_row {
  isa_ok $i = $range->iterator(by => 2), Iterator, "By 2 iterator creation";
  isa_ok $cell = $i->next(), Cell, "First by 2 iteration";
  is $cell->values(), 1, "First by 2 iteration should be '1'";
  isa_ok $cell = $i->next(), Cell, "Second by 2 iteration";
  is $cell->values(), 9, "Second by 2 iteration should be '9'";
  isa_ok $cell = $i->next(), Cell, "Third by 2 iteration";
  is $cell->values(), 2, "Third by 2 iteration should be '2'";
  isa_ok $cell = $i->next(), Cell, "Forth by 2 iteration";
  is $cell->values(), 10, "Forth by 2 iteration should be '10'";
  $cell = $i->next() for (1..3);
  isa_ok $cell = $i->next(), Cell, "By 2 iteration to last";
  is $cell->values(), 12, "By 2 iteration should be '12'";
  is $cell = $i->next(), undef, "Last by 2 iteration should be undef";
  return;
}

sub iterate_by_10_by_row {
  isa_ok $i = $range->iterator(by => 10), Iterator, "By 10 iterator creation";
  isa_ok $cell = $i->next(), Cell, "First by 10 iteration";
  is $cell->values(), 1, "First by 10 iteration should be '1'";
  isa_ok $cell = $i->next(), Cell, "Second by 10 iteration";
  is $cell->values(), 11, "Second by 10 iteration should be '9'";
  is $cell = $i->next(), undef, "Last by 10 iteration should be undef";
  return;
}

delete_all_spreadsheets(sheets_api());

# use YAML::Any qw(Dump);
# warn Dump($spreadsheet->stats());
