package Test::Google::RestApi::TasksApi1;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::TasksApi1';
use aliased 'Google::RestApi::TasksApi1::TaskList';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(4) {
  my $self = shift;

  throws_ok sub { TasksApi1->new() },
    qr/api/i,
    'Constructor without api should throw';

  ok my $tasks = TasksApi1->new(api => mock_rest_api()), 'Constructor should succeed';
  isa_ok $tasks, TasksApi1, 'Constructor returns';
  can_ok $tasks, qw(api task_list create_task_list list_task_lists);

  return;
}

sub task_list_factory : Tests(2) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();
  ok my $tl = $tasks_api->task_list(id => 'some_id'), 'TaskList factory should succeed';
  isa_ok $tl, TaskList, 'TaskList factory returns';

  return;
}

sub create_and_delete_task_list : Tests(3) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();

  my $tl = $tasks_api->create_task_list(title => 'Test Task List');
  isa_ok $tl, TaskList, 'Create returns TaskList object';
  ok my $tl_id = $tl->task_list_id(), 'TaskList has ID';

  lives_ok sub { $tl->delete() }, 'Delete task list lives';

  return;
}

sub list_task_lists : Tests(2) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();

  my @lists = $tasks_api->list_task_lists();
  ok scalar(@lists) >= 1, 'List should return at least one task list';
  ok $lists[0]->{id}, 'Task list has an ID';

  return;
}

sub list_task_lists_max_pages : Tests(2) {
  my $self = shift;

  my $tasks_api = mock_tasks_api();

  my @lists = $tasks_api->list_task_lists(max_pages => 1);
  ok scalar(@lists) >= 1, 'List with max_pages should return results';
  ok $lists[0]->{id}, 'Task list has an ID';

  return;
}

1;
