package Test::Google::RestApi::CalendarApi3::CalendarList;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::CalendarApi3::CalendarList';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(3) {
  my $self = shift;

  my $cal_api = mock_calendar_api();

  ok my $cl = CalendarList->new(calendar_api => $cal_api),
    'Constructor without id should succeed';
  isa_ok $cl, CalendarList, 'Constructor returns';

  ok CalendarList->new(calendar_api => $cal_api, id => 'primary'),
    'Constructor with id should succeed';

  return;
}

sub get : Tests(2) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cl = $cal_api->calendar_list(id => 'primary');

  my $details = $cl->get();
  ok $details, 'Get returns details';
  ok $details->{summary}, 'Details has summary';

  return;
}

sub insert_and_delete : Tests(3) {
  my $self = shift;

  my $cal_api = mock_calendar_api();

  my $cl = $cal_api->calendar_list()->insert(id => 'test_cal@group.calendar.google.com');
  isa_ok $cl, CalendarList, 'Insert returns CalendarList object';
  ok my $cl_id = $cl->calendar_list_id(), 'CalendarList has ID';

  lives_ok sub { $cl->delete() }, 'Delete calendar list entry lives';

  return;
}

1;
