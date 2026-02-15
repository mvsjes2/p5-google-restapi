#!/usr/bin/env perl

# This tutorial demonstrates Tasks API organization:
# - Creating subtasks (move with parent)
# - Reordering tasks (move with previous)
# - Clearing completed tasks
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/tasks/30_organize_tasks.pl
# Add DEBUG=1 for verbose API logging.

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../../t/lib";
use lib "$FindBin::RealBin/../../lib";

use Tutorial::Setup;

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
start("Creating a task list named '$name' for organization demo.");
my $task_list = $tasks_api->create_task_list(title => $name);
my $tl_id = $task_list->task_list_id();
end("Task list created with ID: $tl_id.");

# now set a callback to display the api request/response.
$tasks_api->rest_api()->api_callback(\&show_api);

# create several tasks.
start("Creating three tasks: 'Plan project', 'Write code', 'Write tests'.");
my $task1 = $task_list->create_task(title => 'Plan project');
my $task2 = $task_list->create_task(title => 'Write code');
my $task3 = $task_list->create_task(title => 'Write tests');
end("Tasks created:\n  1: " . $task1->task_id() . " (Plan project)\n  2: " . $task2->task_id() . " (Write code)\n  3: " . $task3->task_id() . " (Write tests)");

# make 'Write code' a subtask of 'Plan project'.
start("Making 'Write code' a subtask of 'Plan project' by moving with parent.");
$task2->move(parent => $task1->task_id());
my @tasks = $task_list->tasks();
end("Tasks after making subtask:\n" . Dump(\@tasks));

# reorder: move 'Write tests' after 'Plan project' (before 'Write code').
start("Moving 'Write tests' after 'Plan project' using previous parameter.");
$task3->move(previous => $task1->task_id());
@tasks = $task_list->tasks();
end("Tasks after reorder:\n" . Dump(\@tasks));

# complete some tasks and clear.
start("Completing 'Write code' and then clearing completed tasks.");
$task2->complete();
$task_list->clear();
@tasks = $task_list->tasks();
end("Tasks after clearing completed:\n" . Dump(\@tasks));

# clean up.
start("Deleting remaining tasks and the task list.");
# delete remaining tasks individually.
for my $t (@tasks) {
  $task_list->task(id => $t->{id})->delete();
}
$task_list->delete();
end("Cleanup complete.");

message('green', "\nTask organization tutorial complete!");
message('green', "All tasks tutorials finished.\n");

message('blue', "We are done, here are some api stats:\n", Dump($tasks_api->rest_api()->stats()));
