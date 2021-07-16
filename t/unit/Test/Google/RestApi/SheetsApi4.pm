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

sub api : Tests() {
  my $self = shift;

  my $class = $self->class();
  $self->_fake_http_auth();
  my $sheets = $class->new(api => fake_rest_api());
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

sub delete_all_spreadsheets : Tests() {
  my $self = shift;

  my $class = $self->class();
  $self->_fake_http_auth();
  my $sheets = $class->new(api => fake_rest_api());
}

sub spreadsheets : Tests() {
  my $self = shift;

  my $class = $self->class();
  $self->_fake_http_auth();

  my $sheets = $class->new(api => fake_rest_api());

  $self->_fake_http_response(200, fake_json_response('spreadsheets'));
  my @spreadsheets = $sheets->spreadsheets();
  my $qr_id = $class->Spreadsheet_Id;
  is_valid \@spreadsheets, ArrayRef[Dict[id => StrMatch[qr/$qr_id/], name => Str]], "Spreadsheets return";
  
  return;
}

1;
