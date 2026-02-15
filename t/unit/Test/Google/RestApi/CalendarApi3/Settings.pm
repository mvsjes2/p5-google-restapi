package Test::Google::RestApi::CalendarApi3::Settings;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::CalendarApi3::Settings';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();

  ok my $settings = Settings->new(calendar_api => $cal_api, id => 'timezone'),
    'Constructor should succeed';
  isa_ok $settings, Settings, 'Constructor returns';

  return;
}

sub get : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $settings = $cal_api->settings(id => 'timezone');

  my $result = $settings->get();
  ok $result, 'Get returns result';
  ok $result->{value}, 'Result has value';

  return;
}

sub value : Tests(1) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $settings = $cal_api->settings(id => 'timezone');

  my $value = $settings->value();
  is $value, 'Australia/Sydney', 'Value returns correct timezone';

  return;
}

sub requires_id : Tests(1) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $settings = Settings->new(calendar_api => $cal_api);

  throws_ok sub { $settings->get() },
    qr/Settings ID required/i,
    'get() without ID should throw';

  return;
}

1;
