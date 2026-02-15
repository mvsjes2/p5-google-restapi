package Test::Google::RestApi::TasksApi1::TaskList;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::TasksApi1::TaskList';
use aliased 'Google::RestApi::TasksApi1::Task';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _setup_live_task_list : Tests(startup) {
  my $self = shift;
  return unless $ENV{GOOGLE_RESTAPI_CONFIG};
  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->create_task_list(title => 'Test Task List');
  $self->{_live_tl} = $tl;
  # Create a task so tasks_max_pages has something to return
  my $task = $tl->create_task(title => 'Test Task for List');
  $self->{_live_task} = $task;
  return;
}

sub _teardown_live_task_list : Tests(shutdown) {
  my $self = shift;
  $self->{_live_tl}->delete() if $self->{_live_tl};
  return;
}

sub _tl_id {
  my $self = shift;
  return $self->{_live_tl} ? $self->{_live_tl}->task_list_id() : mock_task_list_id();
}

sub _constructor : Tests(3) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();

  ok my $tl = TaskList->new(tasks_api => $tasks_api, id => $self->_tl_id()),
    'Constructor should succeed';
  isa_ok $tl, TaskList, 'Constructor returns';
  is $tl->task_list_id(), $self->_tl_id(), 'TaskList has correct ID';

  return;
}

sub requires_id : Tests(4) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = TaskList->new(tasks_api => $tasks_api);

  throws_ok sub { $tl->get() },
    qr/TaskList ID required/i,
    'get() without ID should throw';

  throws_ok sub { $tl->update(title => 'test') },
    qr/TaskList ID required/i,
    'update() without ID should throw';

  throws_ok sub { $tl->delete() },
    qr/TaskList ID required/i,
    'delete() without ID should throw';

  throws_ok sub { $tl->clear() },
    qr/TaskList ID required/i,
    'clear() without ID should throw';

  return;
}

sub get : Tests(2) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => $self->_tl_id());

  my $metadata = $tl->get();
  ok $metadata, 'Get returns metadata';
  ok $metadata->{title}, 'Metadata has title';

  return;
}

sub update : Tests(1) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => $self->_tl_id());

  lives_ok sub { $tl->update(title => 'Updated Task List') }, 'Update lives';

  return;
}

sub task_factory : Tests(2) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => $self->_tl_id());

  ok my $task = $tl->task(), 'Task factory without ID should succeed';
  isa_ok $task, Task, 'Task factory returns';

  return;
}

sub tasks_max_pages : Tests(2) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => $self->_tl_id());

  my @tasks = $tl->tasks(max_pages => 1);
  ok scalar(@tasks) >= 1, 'Tasks with max_pages returns results';
  ok $tasks[0]->{id}, 'Task has an ID';

  return;
}

sub clear : Tests(1) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => $self->_tl_id());

  lives_ok sub { $tl->clear() }, 'Clear lives';

  return;
}

1;
