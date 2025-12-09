package Test::Google::RestApi::SheetsApi4::Range::Cell;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

my $sheet = "'Sheet1'";

sub range : Tests(13) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  is _new_range('A1')->range(),       "$sheet!A1", "A1 should be A1";
  is _new_range(['A', 1])->range(),   "$sheet!A1", "['A', 1] should be A1";
  is _new_range([['A', 1]])->range(), "$sheet!A1", "[['A', 1]] should be A1";
  is _new_range([1, 1])->range(),     "$sheet!A1", "[1, 1] should be A1";
  is _new_range([[1, 1]])->range(),   "$sheet!A1", "[[1, 1]] should be A1";
  is _new_range({row => 1, col => 'A'})->range(),     "$sheet!A1", "{row => 1, col => 'A'} should be A1";
  is _new_range([ {row => 1, col => 'A'} ])->range(), "$sheet!A1", "[{row => 1, col => 'A'}] should be A1";
  is _new_range({row => 1, col => 1})->range(),       "$sheet!A1", "{row => 1, col => 1} should be A1";
  is _new_range([ {row => 1, col => 1} ])->range(),   "$sheet!A1", "[{row => 1, col => 1}] should be A1";
  is _new_range([['A', 1], ['A', 1]])->range(),       "$sheet!A1", "[['A', 1], ['A', 1]] should be A1";
  is _new_range([[1, 1], [1, 1]])->range(),           "$sheet!A1", "[[1, 1], [1, 1]] should be A1";
  is _new_range( {row => 1, col => 'A'}, {row => 1, col => 'A'} )->range(), "$sheet!A1", "{row => 1, col => 'A'}, {row => 1, col => 'A'} should be A1";
  is _new_range( {row => 1, col => 1}, {row => 1, col => 1} )->range(), "$sheet!A1", "{row => 1, col => 1}, {row => 1, col => 1} should be A1";

  return;
}

sub _new_range { fake_worksheet()->range_cell(shift); }

1;
