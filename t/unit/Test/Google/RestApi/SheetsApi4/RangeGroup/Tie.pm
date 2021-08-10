package Test::Google::RestApi::SheetsApi4::RangeGroup::Tie;

use Test::Unit::Setup;

use parent 'Test::Unit::TestBase';

use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

sub class { 'Google::RestApi::SheetsApi4::RangeGroup::Tie' }

sub setup : Tests(setup) {
  my $self = shift;
  $self->SUPER::setup(@_);

  $self->_uri_responses(qw(
    get_worksheet_properties_title_sheetid
    get_worksheet_values_cell
    get_worksheet_values_a1_b1_c1
    post_worksheet_values_a1_b1_c1
  ));
  $self->_fake_http_auth();
  $self->_fake_http_no_retries();

  return;
}

sub tie : Tests(10) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $worksheet = fake_worksheet();
  $worksheet->rest_api()->max_attempts(1);

  my $tied;
  is_hash $tied = $worksheet->tie_cells({id => 'A1'}, {name => 'B1'}, {address => 'C1'}), "Tie some cells";
  is_deeply tied(%$tied)->values(), [undef,undef,undef], "Tied cell values";

  $tied->{id} = 1000;
  $tied->{name} = "Joe Blogs";
  $tied->{address} = "123 Some Street";

  is $worksheet->cell("A1"), undef, "Cell 'A1' is 'undef'";
  is $worksheet->cell("B1"), undef, "Cell 'B1' is 'undef'";
  is $worksheet->cell("C1"), undef, "Cell 'C1' is 'undef'";

  is_array my $values = tied(%$tied)->submit_values(), "Updating a row";
  is scalar @$values, 3, "Updated three values";

  is $worksheet->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $worksheet->cell("B1"), "Joe Blogs", "Cell 'B1' is 'Joe Blogs'";
  is $worksheet->cell("C1"), "123 Some Street", "Cell 'C1' is '123 Some Street'";

  return;
}

sub tie_cols : Tests(11) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $worksheet = fake_worksheet();
  $worksheet->rest_api()->max_attempts(1);

  my $cols;
  is_hash $cols = $worksheet->tie_cols({id => 'B:B'}, {name => 'C:C'}, {address => 'D:D'}), "Tie cols";

  tied(%$cols)->fetch_range(1);
  isa_ok $cols->{1}, Col, "Key '1' should be a col";
  is $cols->{1}->range(), "$self->{name}A:A", "Col '1' is range 'A:A'";
  isa_ok $cols->{2}, Col, "Key '2' should be a col";
  is $cols->{2}->range(), "$self->{name}B:B", "Col '2' is range 'B:B'";

  $cols->{id} = [ 1000, 1001, 1002 ];
  $cols->{name} = [ "Joe Blogs", "Freddie Mercury", "Iggy Pop" ];
  $cols->{address} = [ "123 Some Street", "345 Some Other Street", "Another Universe" ];

  is_array tied(%$cols)->submit_values(), "Updating a row";

  is $worksheet->cell("B1"), 1000, "Cell 'B1' is '1000'";
  is $worksheet->cell("C1"), "Joe Blogs", "Cell 'C1' is 'Joe Blogs'";
  is $worksheet->cell("D1"), "123 Some Street", "Cell 'D1' is '123 Some Street'";

  is $worksheet->cell("B2"), 1001, "Cell 'B2' is '1001'";
  is $worksheet->cell("C2"), "Freddie Mercury", "Cell 'C2' is 'Freddie Mercury'";
  is $worksheet->cell("D2"), "345 Some Other Street", "Cell 'D2' is '345 Some Other Street'";

  is $worksheet->cell("B3"), 1002, "Cell 'B3' is '1002'";
  is $worksheet->cell("C3"), "Iggy Pop", "Cell 'C3' is 'Iggy Pop'";
  is $worksheet->cell("D3"), "Another Universe", "Cell 'D3' is 'Another Universe'";

  return;
}

sub tie_cols2 { # : Tests(10) {
  my $self = shift;

  my $worksheet = fake_worksheet();

  my $cols;
  is_hash $cols = $worksheet->tie_cols(1, 2), "Tying cols '1' and '2'";
  tied(%$cols)->fetch_range(1);
  isa_ok $cols->{1}, Col, "Key '1' should be a col";
  is $cols->{1}->range(), "$self->{name}A:A", "Col '1' is range 'A:A'";
  isa_ok $cols->{2}, Col, "Key '2' should be a col";
  is $cols->{2}->range(), "$self->{name}B:B", "Col '2' is range 'B:B'";

  is_hash $cols = $worksheet->tie_cols({ fred => '1' }), "Tying cols 'fred => 1'";
  tied(%$cols)->fetch_range(1);
  isa_ok $cols->{fred}, Col, "Key 'fred' should be a col";
  is $cols->{fred}->range(), "$self->{name}A:A", "Col 'fred => 1' is range 'A:A'";

  is_hash $cols = $worksheet->tie_cols({ fred => [[1,1], [2,2]] }), "Tying cols to a bad range";
  tied(%$cols)->fetch_range(1);
  throws_ok sub { $cols->{fred}->range(); }, qr/Unable to translate/, "Using a bad range should fail";

  return;
}

sub tie_rows { # : Tests(10) {
  my $self = shift;

  my $worksheet = fake_worksheet();

  my $rows;
  is_hash $rows = $worksheet->tie_rows(1, 2), "Tying rows '1' and '2'";
  tied(%$rows)->fetch_range(1);
  isa_ok $rows->{1}, Row, "Key '1' should be a row";
  is $rows->{1}->range(), "$self->{name}1:1", "Key '1' should be range '1:1'";
  isa_ok $rows->{2}, Row, "Key '2' should be a row";
  is $rows->{2}->range(), "$self->{name}2:2", "Key '2' should be range '2:2'";

  is_hash $rows = $worksheet->tie_rows({ fred => '1' }), "Tying rows 'fred => 1'";
  tied(%$rows)->fetch_range(1);
  isa_ok $rows->{fred}, Row, "Key 'fred' should be a row";
  is $rows->{fred}->range(), "$self->{name}1:1", "Row 'fred => 1' is range '1:1'";

  is_hash $rows = $worksheet->tie_rows({ fred => [[1,1], [2,2]] }), "Tying rows to a bad range";
  tied(%$rows)->fetch_range(1);
  throws_ok sub { $rows->{fred}->range(); }, qr/Unable to translate/, "Using a bad range should fail";

  return;
}

sub tie_cell { # : Tests(7) {
  my $self = shift;

  my $worksheet = fake_worksheet();

  my $cells;
  is_hash $cells = $worksheet->tie(), "Create blank tie";
  my $ranges = $worksheet->tie_cells('A1', { fred => [2, 2] });
  is_hash tied(%$cells)->add_tied($ranges), "Adding tied cells";
  is_array tied(%$cells)->values(), "Tied cell batch values";

  $cells->{A1} = 1000;
  $cells->{fred} = "Joe Blogs";
  $cells->{C3} = "123 Some Street";

  is_array tied(%$cells)->submit_values(), "Updating cells";

  is $worksheet->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $worksheet->cell("B2"), "Joe Blogs", "Cell 'B2' is 'Joe Blogs'";
  is $worksheet->cell("C3"), "123 Some Street", "Cell 'C3' is '123 Some Street'";

  return;
}

sub tie_cells { # : Tests(16) {
  my $self = shift;

  my $worksheet = fake_worksheet();

  my $cells;
  is_hash $cells = $worksheet->tie_cells('A1', 'B2'), "Tying cells 'A1' and 'B2'";
  tied(%$cells)->fetch_range(1);
  isa_ok $cells->{A1}, Cell, "Key 'A1' should be a cell";
  is $cells->{A1}->range(), "$self->{name}A1", "Cell 'A1' is range 'A1'";
  isa_ok $cells->{B2}, Cell, "Key 'B2' should be a cell";
  is $cells->{B2}->range(), "$self->{name}B2", "Cell 'B2' is range 'B2'";

  isa_ok $cells->{C3} = "Charlie", Cell, "Auto-creating cell 'C3'";
  isa_ok $cells->{C3}, Cell, "Key 'C3' should be a cell";
  is $cells->{C3}->range(), "$self->{name}C3", "Cell 'C3' is range 'C3'";

  is_hash $cells = $worksheet->tie_cells({ fred => 'A1' }), "Tying cells 'fred => A1'";
  tied(%$cells)->fetch_range(1);
  isa_ok $cells->{fred}, Cell, "Key 'fred' should be a cell";
  is $cells->{fred}->range(), "$self->{name}A1", "Cell 'fred => A1' is range 'A1'";

  is_hash $cells = $worksheet->tie_cells({ fred => [1, 1] }), "Tying cells 'fred => [1, 1]'";
  tied(%$cells)->fetch_range(1);
  isa_ok $cells->{fred}, Cell, "Key 'fred' should be a cell";
  is $cells->{fred}->range(), "$self->{name}A1", "Cell 'fred => [1, 1]' is 'A1'";

  is_hash $cells = $worksheet->tie_cells({ fred => [[1,1], [2,2]] }), "Tying a cell to a bad range";
  tied(%$cells)->fetch_range(1);
  throws_ok sub { $cells->{fred}->range(); }, qr/Unable to translate/, "Using a bad range should fail";

  return;
}

sub tie_slice { # : Tests(8) {
  my $self = shift;

  my $worksheet = fake_worksheet();

  my $cells;
  is_hash $cells = $worksheet->tie(), "Create blank tie";
  @$cells{ 'A1', 'B2', 'C3', 'D4:E5' } = (1000, "Joe Blogs", "123 Some Street", [["Halifax"]]);

  is $worksheet->cell("A1"), undef, "Cell 'A1' is 'undef'";
  is $worksheet->cell("B2"), undef, "Cell 'B2' is 'undef'";
  is $worksheet->cell("C3"), undef, "Cell 'C3' is 'undef'";

  is_array tied(%$cells)->submit_values(), "Updating cells";

  is $worksheet->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $worksheet->cell("B2"), "Joe Blogs", "Cell 'B2' is 'Joe Blogs'";
  is $worksheet->cell("C3"), "123 Some Street", "Cell 'C3' is '123 Some Street'";

  return;
}

sub tie_return_objects { # : Tests(6) {
  my $self = shift;

  my $worksheet = fake_worksheet();

  my $cols = $worksheet->tie_cols({id => 'B:B'}, {name => 'C:C'}, {address => 'D:D'});
  isa_ok tied(%$cols)->fetch_range(1), $self->class(), "Turning on cols return objects";
  isa_ok $cols->{id}->red(), Col, "Setting id to red";
  isa_ok $cols->{name}->center(), Col, "Setting name centered";
  isa_ok $cols->{address}->font_size(12), Col, "Setting address font size";
  isa_ok tied(%$cols)->fetch_range(0), $self->class(), "Turning off return objects";
  is_hash tied(%$cols)->submit_requests(), "Submitting requests";

  return;
}

1;
