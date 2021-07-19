 package Test::Google::RestApi::SheetsApi4;

use Test::Unit::Setup;

use parent 'Test::Unit::TestBase';

# init_logger($DEBUG);

sub class { 'Google::RestApi::SheetsApi4' }

sub startup : Tests(startup => 3) {
  my $self = shift;
  my $class = $self->class();
  use_ok $self->class();
  ok my $spreadsheets = $class->new(api => fake_rest_api()), 'Constructor should succeed';
  isa_ok $spreadsheets, $class, 'Constructor returns';
  return;
}

sub api : Tests(3) {
  my $self = shift;

  my $class = $self->class();
  $self->_fake_http_auth();

  my $sheets = $class->new(api => fake_rest_api());
  $sheets->rest_api()->post_process(sub { $self->_api(shift); });

  $self->_fake_http_response();
  $sheets->api(
    params  => { joe => 'fred' },
    headers => [ qw(joe fred) ],
    content => { joe => 'fred' },
  );
  return;  
}

sub _api {
  my $self = shift;
  my $transaction = shift;
  is $transaction->{request}->{uri_string}, 'https://sheets.googleapis.com/v4/spreadsheets?joe=fred', "Request uri string is valid";
  is "@{ $transaction->{request}->{headers} }", 'joe fred', "Request headers are valid";
  is $transaction->{request}->{content}->{joe}, 'fred', "Request content is valid";
  return;
}

sub spreadsheets : Tests(1) {
  my $self = shift;

  my $class = $self->class();
  $self->_fake_http_auth();

  my $sheets = $class->new(api => fake_rest_api());

  $self->_fake_http_response(response => fake_json_response('spreadsheets'));
  my @spreadsheets = $sheets->spreadsheets();
  my $qr_id = $class->Spreadsheet_Id;
  is_valid \@spreadsheets, ArrayRef[Dict[id => StrMatch[qr/$qr_id/], name => Str]], "Spreadsheets return";
  
  return;
}

sub create_spreadsheet : Tests() {
  my $self = shift;

  my $class = $self->class();
  $self->_fake_http_auth();
  my $sheets = $class->new(api => fake_rest_api());
}

sub copy_spreadsheet : Tests() {
  my $self = shift;

  my $class = $self->class();
  $self->_fake_http_auth();
  my $sheets = $class->new(api => fake_rest_api());
}

sub delete_spreadsheet : Tests() {
  my $self = shift;

  my $class = $self->class();
  $self->_fake_http_auth();
  my $sheets = $class->new(api => fake_rest_api());
}

sub delete_all_spreadsheets : Tests(4) {
  my $self = shift;

  my $class = $self->class();
  $self->_fake_http_auth();

  my $api = fake_rest_api();
  my $sheets = $class->new(api => $api);

  $self->_fake_delete_all($api);
  is $sheets->delete_all_spreadsheets("so_such_spreadsheet"), 0, 'Delete non-existant should return 0';

  $self->_fake_delete_all($api);
  is $sheets->delete_all_spreadsheets("fake_spreadsheet"), 0, 'Delete common prefix should return 0';
  
  $self->_fake_delete_all($api);
  is $sheets->delete_all_spreadsheets("fake_spreadsheet1"), 1, 'Delete existing should return 1';

  $self->_fake_delete_all($api);
  is $sheets->delete_all_spreadsheets("fake_spreadsheet2"), 2, 'Delete existing duplicate name should return 2';

  return;
}

sub _fake_delete_all {
  my $self = shift;
  my ($api) = @_;
  $self->_fake_http_responses($api, [
    { response => fake_json_response('spreadsheets') },
    # delete just returns 200, no content.
    { response => '' },  # this will stay in effect and keep replying until replaced.
  ]);
  return;
}

1;
