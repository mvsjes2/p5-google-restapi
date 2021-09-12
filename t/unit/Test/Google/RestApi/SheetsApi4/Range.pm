package Test::Google::RestApi::SheetsApi4::Range;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::SheetsApi4::Range';
use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

use parent qw(Test::Google::RestApi::SheetsApi4::Range::Base);

my $sheet = "'Sheet1'";

sub _constructor : Tests(2) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $range = Range->new(
    worksheet => fake_worksheet,
    range     => 'A1:B2',
  );
  isa_ok $range, Range, 'Constructor returns';
  can_ok $range, 'range';

  return;
}

# we don't want to recreate the 'types' tests here, just want to
# ensure that the factory object returns all the right objects.
sub factory : Tests(23) {
  my $self = shift;
  
  $self->_fake_http_response_by_uri();

  my $range = fake_worksheet()->range_factory(range => 'A1:B2');
  is $range->range(), "$sheet!A1:B2", "A1:B2 returns A1:B2";
  isa_ok $range, Range, "A1:B2 returns a Range object";

  
  $range = fake_worksheet()->range_factory(range => 'A:A');
  is $range->range(), "$sheet!A:A", "A:A returns A:A";
  isa_ok $range, Col, "A:A returns a Col object";

  $range = fake_worksheet()->range_factory(range => 'A1:A');
  is $range->range(), "$sheet!A1:A", "A1:A returns A1:A";
  isa_ok $range, Col, "A1:A returns a Col object";

  $range = fake_worksheet()->range_factory(range => 'A:A2');
  is $range->range(), "$sheet!A:A2", "A:A2 returns A:A2";
  isa_ok $range, Col, "A:A2 returns a Col object";

  $range = fake_worksheet()->range_factory(range => 'A');
  is $range->range(), "$sheet!A:A", "A returns A:A";
  isa_ok $range, Col, "A returns a Col object";

  
  $range = fake_worksheet()->range_factory(range => '1:1');
  is $range->range(), "$sheet!1:1", "1:1 returns 1:1";
  isa_ok $range, Row, "1:1 returns a Row object";

  $range = fake_worksheet()->range_factory(range => 'A1:1');
  is $range->range(), "$sheet!A1:1", "A1:1 returns A1:1";
  isa_ok $range, Row, "A1:1 returns a Row object";

  $range = fake_worksheet()->range_factory(range => '1:B1');
  is $range->range(), "$sheet!1:B1", "1:B1 returns 1:B1";
  isa_ok $range, Row, "1:B1 returns a Row object";

  $range = fake_worksheet()->range_factory(range => '1');
  is $range->range(), "$sheet!1:1", "1 returns 1:1";
  isa_ok $range, Row, "1 returns a Row object";


  $range = fake_worksheet()->range_factory(range => 'A1');
  is $range->range(), "$sheet!A1", "A1 returns A1";
  isa_ok $range, Cell, "A1 returns a Cell object";

  $range = fake_worksheet()->range_factory(range => "George");
  is $range->named(), 'George', "George should be a named range";
  isa_ok $range, Col, "Named range";

  $range = fake_worksheet()->range_factory(range => "A1");
  is $range->named(), undef, "A1 should not be a named range";

  return;
}

sub clear {
}

sub values {
}

sub values_response_from_api {
}

sub batch_values {
}

sub append {
}

sub range : Tests(2) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  isa_ok my $range = _new_range('A1:B2'), Range, "New range 'A1:B2'";
  is $range->range(), "$sheet!A1:B2", "A1:B2 should be '$sheet!A1:B2'";

  return;
}

sub range_to_array {
}

sub range_to_hash {
}

sub range_to_index {
}

sub range_to_dimension {
}

sub cell_at_offset {
}

sub offset {
}

sub offsets {
}

sub is_inside {
}

sub _new_range { fake_worksheet()->range(shift); }

1;
