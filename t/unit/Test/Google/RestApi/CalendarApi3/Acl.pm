package Test::Google::RestApi::CalendarApi3::Acl;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::CalendarApi3::Acl';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _setup_live_calendar : Tests(startup) {
  my $self = shift;
  return unless $ENV{GOOGLE_RESTAPI_CONFIG};
  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->create_calendar(summary => 'Test Calendar ACL');
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
  my $cal = $cal_api->calendar(id => $self->_cal_id());

  ok my $acl = Acl->new(calendar => $cal),
    'Constructor without id should succeed';
  isa_ok $acl, Acl, 'Constructor returns';

  ok Acl->new(calendar => $cal, id => 'user:test@example.com'),
    'Constructor with id should succeed';

  return;
}

sub requires_id : Tests(3) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => $self->_cal_id());
  my $acl = Acl->new(calendar => $cal);

  throws_ok sub { $acl->get() },
    qr/ACL ID required/i,
    'get() without ID should throw';

  throws_ok sub { $acl->update(role => 'writer') },
    qr/ACL ID required/i,
    'update() without ID should throw';

  throws_ok sub { $acl->delete() },
    qr/ACL ID required/i,
    'delete() without ID should throw';

  return;
}

sub create_and_delete : Tests(4) {
  my $self = shift;

  my $cal_api = mock_calendar_api();
  my $cal = $cal_api->calendar(id => $self->_cal_id());

  my $acl = $cal->acl()->create(
    role        => 'reader',
    scope_type  => 'user',
    scope_value => 'test@example.com',
  );
  isa_ok $acl, Acl, 'Create returns Acl object';
  ok my $acl_id = $acl->acl_id(), 'ACL has ID';

  my $details = $acl->get();
  ok $details, 'Get returns ACL details';

  lives_ok sub { $acl->delete() }, 'Delete ACL lives';

  return;
}

1;
