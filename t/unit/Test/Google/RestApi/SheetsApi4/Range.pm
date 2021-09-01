package Test::Google::RestApi::SheetsApi4::Range;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Range';
use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

use parent qw(Test::Google::RestApi::SheetsApi4::Range::Base);

my $sheet = "'Sheet1'";

sub class { Range; }

sub _constructor : Tests(2) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $class = class();
  my $range = $class->new(
    worksheet => fake_worksheet,
    range     => 'A1:B2',
  );
  isa_ok $range, $class, 'Constructor returns';
  can_ok $range, 'range';
  return;
}

sub range : Tests(6) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $x = "A1:B2";

  my $range;
  isa_ok $range = $self->_new_range($x), Range, "New range '$x'";
  is $range->range(), "$sheet!$x", "A1:B2 should be $x";

  $range = $self->_new_range([[1,1], [2,2]]);
  is $range->range(), "$sheet!$x", "[[1,1], [2,2]] should be $x";

  $range = $self->_new_range([['A',1], ['B',2]]);
  is $range->range(), "$sheet!$x", "[[A,1], [B,2]] should be $x";

  $range = $self->_new_range([{row => 1, col => 1}, {row => 2, col => 2}]);
  is $range->range(), "$sheet!$x", "[{row => 1, col => 1}, {row => 2, col => 2}] should be $x";

  $range = $self->_new_range([{row => 1, col => 'A'}, {row => 2, col =>'B'}]);
  is $range->range(), "$sheet!$x", "[{row => 1, col => A}, {row => 2, col => B}] should be $x";

  return;
}

sub range_named : Tests(3) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  is $self->_new_range("George")->is_named(), 1, "George should be a named range";
  is $self->_new_range("A1")->is_named(), undef, "A1 should not be a named range";
  is $self->_new_range("A1:B2")->is_named(), undef, "A1:B2 should not be a named range";

  return;
}

sub range_mixed : Tests(6) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $range = $self->_new_range(['A1', [2, 2]]);
  is $range->range(), "$sheet!A1:B2", "[A1, [2, 2]] should be A1:B2";

  $range = $self->_new_range(['A1', {col => 2, row => 2}]);
  is $range->range(), "$sheet!A1:B2", "[A1, {col => 2, row => 2}] should be A1:B2";

  $range = $self->_new_range([[1, 1], 'B2']);
  is $range->range(), "$sheet!A1:B2", "[[1, 1], 'B2'] should be A1:B2";

  $range = $self->_new_range([{col => 1, row => 1}, 'B2']);
  is $range->range(), "$sheet!A1:B2", "[{col => 1, row => 1}, 'B2'] should be A1:B2";

  $range = $self->_new_range([{col => 1, row => 1}, [2, 2]]);
  is $range->range(), "$sheet!A1:B2", "[{col => 1, row => 1}, [2, 2]] should be A1:B2";

  $range = $self->_new_range([[1, 1], {col => 2, row => 2}]);
  is $range->range(), "$sheet!A1:B2", "[[1, 1], {col => 2, row => 2}] should be A1:B2";

  return;
}

sub range_factory : Tests(17) {
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

  return;
}

1;
