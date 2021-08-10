package Test::Google::RestApi::SheetsApi4::Worksheet;

use Test::Unit::Setup;

use parent 'Test::Unit::TestBase';

use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';

# init_logger($TRACE);

sub class { 'Google::RestApi::SheetsApi4::Worksheet' }

sub setup : Tests(setup) {
  my $self = shift;
  $self->SUPER::setup(@_);

  $self->_uri_responses(qw(
    get_worksheet_properties_title_sheetid
    get_worksheet_values_col
    get_worksheet_values_row
    put_worksheet_values_col
    put_worksheet_values_row
  ));
  $self->_fake_http_auth();
  $self->_fake_http_no_retries();

  return;
}

sub _constructor : Tests(8) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $class = $self->class();

  use_ok $self->class();

  ok my $ws0 = $self->_fake_worksheet(), 'Constructor should succeed';
  isa_ok $ws0, $class, 'Constructor with "id" returns';

  ok $ws0 = $self->_fake_worksheet(name => fake_worksheet_name()),
    'Constructor with "name" should succeed';
  isa_ok $ws0, $class, 'Constructor with "name" returns';

  ok $ws0 = $self->_fake_worksheet(uri => fake_worksheet_uri()),
    'Constructor with "uri`" should succeed';
  isa_ok $ws0, $class, 'Constructor with "uri" returns';

  throws_ok sub { $ws0 = $class->new(spreadsheet => fake_spreadsheet()) },
    qr/At least one of/i,
    'Constructor with missing params should throw';

  return;
}

sub worksheet_id : Tests() {
  my $self = shift;
  return;
}

sub worksheet_name : Tests() {
  my $self = shift;
}

sub worksheet_uri : Tests() {
  my $self = shift;
}

sub properties : Tests() {
  my $self = shift;
}

sub col : Tests(3) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $ws0 = $self->_fake_worksheet();
  is_valid $ws0->col('A'), undef, 'Col returns undef';
  is_deeply $ws0->col('A', [qw(joe)]), [qw(joe)], 'Col returns an array of values';
  throws_ok sub { $ws0->col('A1:B2') }, qr/Unable to translate column/i, 'Bad col throws';
  
  return;
}

sub cols : Tests() {
  my $self = shift;
}

sub row : Tests(3) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $ws0 = $self->_fake_worksheet();
  is_valid $ws0->row(1), undef, 'Row returns undef';
  is_deeply $ws0->row(1, [qw(joe)]), [qw(joe)], 'Row returns an array of values';
  throws_ok sub { $ws0->row('A1:B2') }, qr/Must be a positive integer/i, 'Bad row throws';
  
  return;
}

sub rows : Tests() {
  my $self = shift;
}

sub cell : Tests() {
  my $self = shift;
}

sub enable_header_col : Tests() {
  my $self = shift;
}

sub header_row : Tests() {
  my $self = shift;
}

sub name_value_pairs : Tests() {
  my $self = shift;
}

sub tie_ranges : Tests() {
  my $self = shift;
}

sub tie_cols : Tests() {
  my $self = shift;
}

sub tie_rows : Tests() {
  my $self = shift;
}

sub tie_cells : Tests() {
  my $self = shift;
}

sub tie : Tests() {
  my $self = shift;
}

sub submit_requests : Tests() {
  my $self = shift;
}

sub config : Tests() {
  my $self = shift;
}

sub _fake_worksheet {
  my $self = shift;
  my %p = @_;
  $p{id} = fake_worksheet_id() if !%p;
  return $self->class()->new(%p, spreadsheet => fake_spreadsheet());
}

1;
