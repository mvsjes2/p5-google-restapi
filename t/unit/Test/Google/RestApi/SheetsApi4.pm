package Test::Google::RestApi::SheetsApi4;

use Test::Unit::Setup;

use parent 'Test::Unit::TestBase';

use aliased 'Google::RestApi::SheetsApi4::Spreadsheet';

# init_logger();

sub class { 'Google::RestApi::SheetsApi4' }

sub setup : Tests(setup) {
  my $self = shift;
  $self->SUPER::setup(@_);

  $self->_uri_responses(qw(
    get_spreadsheets
    delete_spreadsheet
    post_spreadsheet_copy
    post_spreadsheet_create
  ));

  $self->_fake_http_auth();
  $self->_fake_http_no_retries();

  return;
}

sub _constructor : Tests(3) {
  my $self = shift;

  my $class = $self->class();

  use_ok $self->class();
  ok my $spreadsheets = $class->new(api => fake_rest_api()), 'Constructor should succeed';
  isa_ok $spreadsheets, $class, 'Constructor returns';

  return;
}

sub api : Tests(4) {
  my $self = shift;

  my $sheets_api = fake_sheets_api();
  $self->_fake_http_response();

  is_valid $sheets_api->api(), EmptyHashRef, 'Empty get';
  my $transaction = $sheets_api->rest_api()->transaction();
  is $transaction->{request}->{uri}, sheets_endpoint(), "Request base uri string is valid";

  is_valid $sheets_api->api(uri => 'x'), EmptyHashRef, 'Get with URI';
  $transaction = $sheets_api->rest_api()->transaction();
  is $transaction->{request}->{uri}, sheets_endpoint() . '/x', "Request extra uri string is valid";

  return;
}

sub spreadsheets : Tests(1) {
  my $self = shift;

  my $sheets_api = fake_sheets_api();
  $self->_fake_http_response_by_uri();

  my @spreadsheets = $sheets_api->spreadsheets();
  my $qr_id = $self->class()->Spreadsheet_Id;
  is_valid \@spreadsheets, ArrayRef[Dict[id => StrMatch[qr/$qr_id/], name => Str]], "Spreadsheets return";
  
  return;
}

sub create_spreadsheet : Tests(3) {
  my $self = shift;

  my $sheets_api = fake_sheets_api();
  $self->_fake_http_response_by_uri();

  isa_ok $sheets_api->create_spreadsheet(title => fake_spreadsheet_name()), Spreadsheet, "Create sheet by title";
  isa_ok $sheets_api->create_spreadsheet(name => fake_spreadsheet_name()), Spreadsheet, "Create sheet by name";
  throws_ok sub { $sheets_api->create_spreadsheet(eman => fake_spreadsheet_name()) }, qr/should be supplied/, "No name or title should fail";
  
  return;
}

sub copy_spreadsheet : Tests(3) {
  my $self = shift;

  my $sheets_api = fake_sheets_api();
  $self->_fake_http_response_by_uri();

  isa_ok $sheets_api->copy_spreadsheet(spreadsheet_id => fake_spreadsheet_id()), Spreadsheet, "Copy sheet";
  isa_ok $sheets_api->copy_spreadsheet(
    spreadsheet_id => fake_spreadsheet_id(),
    name           => fake_spreadsheet_name()
  ), Spreadsheet, "Copy sheet with name";
  isa_ok $sheets_api->copy_spreadsheet(
    spreadsheet_id => fake_spreadsheet_id(),
    title          => fake_spreadsheet_name()
  ), Spreadsheet, "Copy sheet with title";

  return;
}

sub delete_spreadsheet : Tests(1) {
  my $self = shift;

  my $sheets_api = fake_sheets_api();
  $self->_fake_http_response_by_uri();

  is $sheets_api->delete_spreadsheet('x'), 1, 'Delete should return true';

  return;
}

sub delete_all_spreadsheets : Tests(4) {
  my $self = shift;

  my $sheets_api = fake_sheets_api();
  $self->_fake_http_response_by_uri();

  is $sheets_api->delete_all_spreadsheets("no_such_spreadsheet"), 0, 'Delete non-existant should return 0';
  is $sheets_api->delete_all_spreadsheets("fake_spreadsheet"), 0, 'Delete common prefix should return 0';
  is $sheets_api->delete_all_spreadsheets("fake_spreadsheet1"), 1, 'Delete existing should return 1';
  is $sheets_api->delete_all_spreadsheets("fake_spreadsheet2"), 2, 'Delete existing duplicate name should return 2';

  return;
}

1;
