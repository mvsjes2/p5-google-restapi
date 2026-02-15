package Test::Google::RestApi::CalendarApi3::Calendar;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::CalendarApi3::Calendar';
use aliased 'Google::RestApi::CalendarApi3::Event';
use aliased 'Google::RestApi::CalendarApi3::Acl';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _setup_live_calendar : Tests(startup) {
  my $self = shift;
  return unless $ENV{GOOGLE_RESTAPI_CONFIG};
  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->create_calendar(summary => 'Test Calendar');
  $self->{_live_cal} = $cal;
  return;
}

sub _teardown_live_calendar : Tests(shutdown) {
  my $self = shift;
  $self->{_live_cal}->delete() if $self->{_live_cal};
  return;
}

sub _cal_id {
  my $self = shift;
  return $self->{_live_cal} ? $self->{_live_cal}->calendar_id() : mock_calendar_id();
}

sub _constructor : Tests(3) {
  my $self = shift;

  my $cal_api = mock_calendar_api();

  ok my $cal = Calendar->new(calendar_api => $cal_api, id => 'primary'),
    'Constructor should succeed';
  isa_ok $cal, Calendar, 'Constructor returns';
  is $cal->calendar_id(), 'primary', 'Calendar has correct ID';

  return;
}

sub get : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => $self->_cal_id());

  my $metadata = $cal->get();
  ok $metadata, 'Get returns metadata';
  ok $metadata->{summary}, 'Metadata has summary';

  return;
}

sub update : Tests(1) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => $self->_cal_id());

  lives_ok sub { $cal->update(summary => 'Updated Calendar') }, 'Update lives';

  return;
}

sub event_factory : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => $self->_cal_id());

  ok my $event = $cal->event(), 'Event factory without ID should succeed';
  isa_ok $event, Event, 'Event factory returns';

  return;
}

sub events_max_pages : Tests(1) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => $self->_cal_id());

  my @events = $cal->events(max_pages => 1);
  ok defined(\@events), 'Events with max_pages returns array';

  return;
}

sub acl_rules_max_pages : Tests(1) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => $self->_cal_id());

  my @rules = $cal->acl_rules(max_pages => 1);
  ok defined(\@rules), 'acl_rules with max_pages accepts param';

  return;
}

sub acl_factory : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => $self->_cal_id());

  ok my $acl = $cal->acl(), 'ACL factory without ID should succeed';
  isa_ok $acl, Acl, 'ACL factory returns';

  return;
}

1;
