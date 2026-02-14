package Test::Google::RestApi::CalendarApi3::Calendar;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::CalendarApi3::Calendar';
use aliased 'Google::RestApi::CalendarApi3::Event';
use aliased 'Google::RestApi::CalendarApi3::Acl';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

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
  my $cal = $cal_api->calendar(id => mock_calendar_id());

  my $metadata = $cal->get();
  ok $metadata, 'Get returns metadata';
  ok $metadata->{summary}, 'Metadata has summary';

  return;
}

sub update : Tests(1) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => mock_calendar_id());

  lives_ok sub { $cal->update(summary => 'Updated Calendar') }, 'Update lives';

  return;
}

sub event_factory : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => mock_calendar_id());

  ok my $event = $cal->event(), 'Event factory without ID should succeed';
  isa_ok $event, Event, 'Event factory returns';

  return;
}

sub events_max_pages : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => mock_calendar_id());

  my @events = $cal->events(max_pages => 1);
  ok scalar(@events) >= 1, 'Events with max_pages returns results';
  ok $events[0]->{id}, 'Event has an ID';

  return;
}

sub acl_rules_max_pages : Tests(1) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => mock_calendar_id());

  my @rules = $cal->acl_rules(max_pages => 1);
  ok defined(\@rules), 'acl_rules with max_pages accepts param';

  return;
}

sub acl_factory : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => mock_calendar_id());

  ok my $acl = $cal->acl(), 'ACL factory without ID should succeed';
  isa_ok $acl, Acl, 'ACL factory returns';

  return;
}

1;
