#!/usr/bin/env perl

# This tutorial demonstrates Tasks API task operations:
# - Creating tasks with titles, notes, and due dates
# - Getting/updating/listing/deleting tasks
# - Completing and uncompleting tasks
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/tasks/20_task_operations.pl
# Add DEBUG=1 for verbose API logging.

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../../t/lib";
use lib "$FindBin::RealBin/../../lib";

use Tutorial::Setup;
use POSIX qw(strftime);

init_logger($TRACE) if $ENV{DEBUG};

my $name = tasks_list_name();
my $tasks_api = tasks_api();

# clean up any failed previous runs.
start("Cleaning up any task lists from previous tutorial runs.");
my @existing = $tasks_api->list_task_lists();
for my $tl (@existing) {
  if ($tl->{title} && $tl->{title} eq $name) {
    $tasks_api->task_list(id => $tl->{id})->delete();
  }
}
end("Cleanup complete.");

# create a task list for this tutorial.
start("Creating a task list named '$name' for task operations.");
my $task_list = $tasks_api->create_task_list(title => $name);
my $tl_id = $task_list->task_list_id();
end("Task list created with ID: $tl_id.");

# now set a callback to display the api request/response.
$tasks_api->rest_api()->api_callback(\&show_api);

# create a task with a due date.
my $tomorrow = strftime('%Y-%m-%dT00:00:00.000Z', gmtime(time + 86400));
start("Creating a task with a due date.");
my $task = $task_list->create_task(
  title => 'Buy groceries',
  notes => 'Milk, eggs, bread',
  due   => $tomorrow,
);
my $task_id = $task->task_id();
end("Task created with ID: $task_id.");

# get task details.
start("Getting the task details.");
my $details = $task->get();
end("Task details:\n" . Dump($details));

# update the task.
start("Updating the task title and notes.");
$task->update(
  title => 'Buy groceries and snacks',
  notes => 'Milk, eggs, bread, chips, cookies',
);
my $updated = $task->get();
end("Updated task:\n" . Dump($updated));

# create another task.
start("Creating a second task.");
my $task2 = $task_list->create_task(
  title => 'Clean the house',
);
end("Second task created with ID: " . $task2->task_id());

# list all tasks.
start("Listing all tasks on the task list.");
my @tasks = $task_list->tasks();
end("Task list has " . scalar(@tasks) . " task(s):\n" . Dump(\@tasks));

# complete a task.
start("Completing the first task.");
$task->complete();
my $completed = $task->get();
end("Completed task:\n" . Dump($completed));

# uncomplete the task.
start("Uncompleting the first task.");
$task->uncomplete();
my $uncompleted = $task->get();
end("Uncompleted task:\n" . Dump($uncompleted));

# delete tasks.
start("Deleting the tasks we created.");
$task->delete();
$task2->delete();
end("Tasks deleted.");

# clean up the task list.
start("Deleting the tutorial task list.");
$task_list->delete();
end("Task list deleted.");

message('green', "\nTask operations tutorial complete!");
message('green', "Proceed to 30_organize_tasks.pl to see task organization.\n");

message('blue', "We are done, here are some api stats:\n", Dump($tasks_api->rest_api()->stats()));
