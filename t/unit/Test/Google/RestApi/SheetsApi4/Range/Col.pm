package Test::Google::RestApi::SheetsApi4::Range::Col;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Range::Col';

use parent qw(Test::Google::RestApi::SheetsApi4::Range::Base);

my $sheet = "'Sheet1'";

# init_logger($TRACE);

sub range : Tests(16) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  is _new_range("A:A")->range(),     "$sheet!A:A", "A:A should be A:A";
  is _new_range(['A'])->range(),     "$sheet!A:A", "['A'] should be A:A";
  is _new_range(['1'])->range(),     "$sheet!A:A", "['1'] should be A:A";
  is _new_range([['A']])->range(),   "$sheet!A:A", "[['A']] should be A:A";
  is _new_range([['1']])->range(),   "$sheet!A:A", "[['1']] should be A:A";
  is _new_range({col => 'A'})->range(),      "$sheet!A:A", "{col => 'A'} should be A:A";
  is _new_range({col => '1'})->range(),      "$sheet!A:A", "{col => '1'} should be A:A";
  is _new_range([{col => 'A'}])->range(),    "$sheet!A:A", "[{col => 'A'}] should be A:A";
  is _new_range([{col => '1'}])->range(),    "$sheet!A:A", "[{col => '1'}] should be A:A";
  is _new_range([['A', 5], ['A']])->range(), "$sheet!A5:A", "[['A', 5], ['A']] should be A5:A";
  is _new_range([{col => 'A', row => 5}, {col => 'A'}])->range(), "$sheet!A5:A", "[{col => 'A', row => 5}, {col => 'A'}] should be A5:A";
  is _new_range("AA10:AA11")->range(), "$sheet!AA10:AA11", "AA10:AA11 should be AA10:AA11";
  is _new_range(52)->range(),          "$sheet!AZ:AZ", "52 should be col AZ:AZ";
  is _new_range(53)->range(),          "$sheet!BA:BA", "53 should be col BA:BA";
  is _new_range(18_278)->range(),      "$sheet!ZZZ:ZZZ", "18,278 should be col ZZZ:ZZZ";
  # this is an invalid column in google sheets, but let google die on us rather than us checking.
  is _new_range(18_279)->range(),      "$sheet!AAAA:AAAA", "18,279 should be col AAAA:AAAA";

  return;
}

sub _new_range { fake_worksheet()->range_col(shift); }

1;
