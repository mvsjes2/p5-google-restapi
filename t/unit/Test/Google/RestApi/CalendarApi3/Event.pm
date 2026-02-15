package Test::Google::RestApi::CalendarApi3::Event;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::CalendarApi3::Event';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(3) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => mock_calendar_id());

  ok my $event = Event->new(calendar => $cal),
    'Constructor without id should succeed';
  isa_ok $event, Event, 'Constructor returns';

  ok Event->new(calendar => $cal, id => 'event123'),
    'Constructor with id should succeed';

  return;
}

sub requires_id : Tests(3) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => mock_calendar_id());
  my $event = Event->new(calendar => $cal);

  throws_ok sub { $event->get() },
    qr/Event ID required/i,
    'get() without ID should throw';

  throws_ok sub { $event->update(summary => 'test') },
    qr/Event ID required/i,
    'update() without ID should throw';

  throws_ok sub { $event->delete() },
    qr/Event ID required/i,
    'delete() without ID should throw';

  return;
}

sub create_and_delete : Tests(4) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => mock_calendar_id());

  my $event = $cal->event()->create(
    summary => 'Test Event',
    start   => { dateTime => '2026-03-01T10:00:00Z' },
    end     => { dateTime => '2026-03-01T11:00:00Z' },
  );
  isa_ok $event, Event, 'Create returns Event object';
  ok my $event_id = $event->event_id(), 'Event has ID';

  my $details = $event->get();
  ok $details, 'Get returns event details';

  lives_ok sub { $event->delete() }, 'Delete event lives';

  return;
}

sub quick_add : Tests(3) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => mock_calendar_id());

  my $event = $cal->event()->quick_add(text => 'Lunch tomorrow at noon');
  isa_ok $event, Event, 'Quick add returns Event object';
  ok $event->event_id(), 'Quick add event has ID';

  lives_ok sub { $event->delete() }, 'Delete quick add event lives';

  return;
}

1;
