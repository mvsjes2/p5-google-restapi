package Test::Google::RestApi::SheetsApi4::Range::Row;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Range::Row';

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

my $sheet = "'Sheet1'";

sub range : Tests(13) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  is _new_range('1:1')->range(),          "$sheet!1:1", "1:1 should be 1:1";
  is _new_range([undef, '1'])->range(),   "$sheet!1:1", "[undef, '1'] should be 1:1";
  is _new_range([0, '1'])->range(),       "$sheet!1:1", "[0, '1'] should be 1:1";
  is _new_range(['', '1'])->range(),      "$sheet!1:1", "['', '1'] should be 1:1";
  is _new_range([[undef, '1']])->range(), "$sheet!1:1", "[[undef, '1']] should be 1:1";
  is _new_range([[0, '1']])->range(),     "$sheet!1:1", "[[0, '1']] should be 1:1";
  is _new_range([['', '1']])->range(),    "$sheet!1:1", "[['', '1']] should be 1:1";
  is _new_range({row => '1'})->range(),   "$sheet!1:1", "{row => '1'} should be 1:1";
  is _new_range([{row => '1'}])->range(), "$sheet!1:1", "[{row => '1'}] should be 1:1";
  is _new_range([[5, '1'], [undef, '1']])->range(), "$sheet!E1:1", "[[5, '1'], [undef, '1']] should be E1:1";
  is _new_range([[5, '1'], [0, '1']])->range(),     "$sheet!E1:1", "[[5, '1'], [0, '1']] should be E1:1";
  is _new_range([[5, '1'], ['', '1']])->range(),    "$sheet!E1:1", "[[5, '1'], ['', '1']] should be E1:1";
  is _new_range([{row => '1', col => 5}, {row => '1'}])->range(), "$sheet!E1:1", "[{row => '1', col => 5}, {row => '1'}] should be E1:1";

  return;
}

sub _new_range { fake_worksheet()->range_row(shift); }

1;
