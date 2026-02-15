package Test::Google::RestApi::TasksApi1::Task;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::TasksApi1::Task';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(3) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => mock_task_list_id());

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
  my $tl = $tasks_api->task_list(id => mock_task_list_id());
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
  my $tl = $tasks_api->task_list(id => mock_task_list_id());

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
  my $tl = $tasks_api->task_list(id => mock_task_list_id());
  my $task = Task->new(task_list => $tl, id => 'mock_task_id_12345');

  lives_ok sub { $task->update(title => 'Updated Task') }, 'Update task lives';

  return;
}

sub move : Tests(1) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => mock_task_list_id());
  my $task = Task->new(task_list => $tl, id => 'mock_task_id_12345');

  lives_ok sub { $task->move(parent => 'mock_parent_task_id') }, 'Move task lives';

  return;
}

sub complete_and_uncomplete : Tests(2) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => mock_task_list_id());
  my $task = Task->new(task_list => $tl, id => 'mock_task_id_12345');

  lives_ok sub { $task->complete() }, 'Complete task lives';
  lives_ok sub { $task->uncomplete() }, 'Uncomplete task lives';

  return;
}

sub requires_id_complete : Tests(2) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  my $tl = $tasks_api->task_list(id => mock_task_list_id());
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
