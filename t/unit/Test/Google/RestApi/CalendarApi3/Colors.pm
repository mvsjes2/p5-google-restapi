package Test::Google::RestApi::CalendarApi3::Colors;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::CalendarApi3::Colors';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();

  ok my $colors = Colors->new(calendar_api => $cal_api),
    'Constructor should succeed';
  isa_ok $colors, Colors, 'Constructor returns';

  return;
}

sub get : Tests(3) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $colors = $cal_api->colors();

  my $result = $colors->get();
  ok $result, 'Get returns result';
  ok $result->{calendar}, 'Result has calendar colors';
  ok $result->{event}, 'Result has event colors';

  return;
}

1;
