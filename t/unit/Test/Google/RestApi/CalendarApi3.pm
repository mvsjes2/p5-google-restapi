package Test::Google::RestApi::CalendarApi3;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::CalendarApi3';
use aliased 'Google::RestApi::CalendarApi3::Calendar';
use aliased 'Google::RestApi::CalendarApi3::CalendarList';
use aliased 'Google::RestApi::CalendarApi3::Colors';
use aliased 'Google::RestApi::CalendarApi3::Settings';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(4) {
  my $self = shift;

  throws_ok sub { CalendarApi3->new() },
    qr/api/i,
    'Constructor without api should throw';

  ok my $cal = CalendarApi3->new(api => mock_rest_api()), 'Constructor should succeed';
  isa_ok $cal, CalendarApi3, 'Constructor returns';
  can_ok $cal, qw(api calendar calendar_list colors settings
                  create_calendar list_calendars freebusy);

  return;
}

sub calendar_factory : Tests(3) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  ok my $cal = $cal_api->calendar(id => 'primary'), 'Calendar factory should succeed';
  isa_ok $cal, Calendar, 'Calendar factory returns';
  is $cal->calendar_id(), 'primary', 'Calendar has correct ID';

  return;
}

sub calendar_list_factory : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  ok my $cl = $cal_api->calendar_list(id => 'primary'), 'CalendarList factory should succeed';
  isa_ok $cl, CalendarList, 'CalendarList factory returns';

  return;
}

sub colors_factory : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  ok my $colors = $cal_api->colors(), 'Colors factory should succeed';
  isa_ok $colors, Colors, 'Colors factory returns';

  return;
}

sub settings_factory : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  ok my $settings = $cal_api->settings(id => 'timezone'), 'Settings factory should succeed';
  isa_ok $settings, Settings, 'Settings factory returns';

  return;
}

sub create_and_delete_calendar : Tests(3) {
  my $self = shift;

  my $cal_api = mock_calendar_api();

  my $calendar = $cal_api->create_calendar(summary => 'Test Calendar');
  isa_ok $calendar, Calendar, 'Create returns Calendar object';
  ok my $cal_id = $calendar->calendar_id(), 'Calendar has ID';

  lives_ok sub { $calendar->delete() }, 'Delete calendar lives';

  return;
}

sub list_calendars : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();

  my @calendars = $cal_api->list_calendars();
  ok scalar(@calendars) >= 1, 'List should return at least one calendar';
  ok $calendars[0]->{id}, 'Calendar has an ID';

  return;
}

1;
