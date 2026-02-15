package Test::Google::RestApi::TasksApi1::Task;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::TasksApi1::Task';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _setup_live_task_list : Tests(startup) {
  my $self = shift;
  return unless $ENV{GOOGLE_RESTAPI_CONFIG};
  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->create_task_list(title => 'Test Task List for Tasks');
  $self->{_live_tl} = $tl;
  # Create a persistent task for update/move/complete tests
  my $task = $tl->create_task(title => 'Persistent Test Task');
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

sub _task_id {
  my $self = shift;
  return $self->{_live_task} ? $self->{_live_task}->task_id() : 'mock_task_id_12345';
}

sub _constructor : Tests(3) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => $self->_tl_id());

  ok my $task = Task->new(task_list => $tl),
    'Constructor without id should succeed';
  isa_ok $task, Task, 'Constructor returns';

  ok Task->new(task_list => $tl, id => 'task123'),
    'Constructor with id should succeed';

  return;
}

sub requires_id : Tests(4) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => $self->_tl_id());
  my $task = Task->new(task_list => $tl);

  throws_ok sub { $task->get() },
    qr/Task ID required/i,
    'get() without ID should throw';

  throws_ok sub { $task->update(title => 'test') },
    qr/Task ID required/i,
    'update() without ID should throw';

  throws_ok sub { $task->delete() },
    qr/Task ID required/i,
    'delete() without ID should throw';

  throws_ok sub { $task->move() },
    qr/Task ID required/i,
    'move() without ID should throw';

  return;
}

sub create_and_delete : Tests(4) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => $self->_tl_id());

  my $task = $tl->create_task(
    title => 'Test Task',
    notes => 'Some notes',
  );
  isa_ok $task, Task, 'Create returns Task object';
  ok my $task_id = $task->task_id(), 'Task has ID';

  my $details = $task->get();
  ok $details, 'Get returns task details';

  lives_ok sub { $task->delete() }, 'Delete task lives';

  return;
}

sub update : Tests(1) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => $self->_tl_id());
  my $task = Task->new(task_list => $tl, id => $self->_task_id());

  lives_ok sub { $task->update(title => 'Updated Task') }, 'Update task lives';

  return;
}

sub move : Tests(1) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => $self->_tl_id());
  my $task = Task->new(task_list => $tl, id => $self->_task_id());

  lives_ok sub { $task->move() }, 'Move task lives';

  return;
}

sub complete_and_uncomplete : Tests(2) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => $self->_tl_id());
  my $task = Task->new(task_list => $tl, id => $self->_task_id());

  lives_ok sub { $task->complete() }, 'Complete task lives';
  lives_ok sub { $task->uncomplete() }, 'Uncomplete task lives';

  return;
}

sub requires_id_complete : Tests(2) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => $self->_tl_id());
  my $task = Task->new(task_list => $tl);

  throws_ok sub { $task->complete() },
    qr/Task ID required/i,
    'complete() without ID should throw';

  throws_ok sub { $task->uncomplete() },
    qr/Task ID required/i,
    'uncomplete() without ID should throw';

  return;
}

1;
