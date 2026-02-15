#!/usr/bin/env perl

# This tutorial demonstrates Tasks API task list operations:
# - Listing task lists
# - Creating a new task list
# - Getting/updating task list metadata
# - Deleting a task list
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/tasks/10_task_list_basics.pl
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

# now set a callback to display the api request/response.
$tasks_api->rest_api()->api_callback(\&show_api);

# list the user's task lists.
start("Listing your task lists.");
my @lists = $tasks_api->list_task_lists();
end("You have " . scalar(@lists) . " task list(s):\n" . Dump(\@lists));

# create a new task list.
start("Creating a new task list named '$name'.");
my $task_list = $tasks_api->create_task_list(title => $name);
my $tl_id = $task_list->task_list_id();
end("Task list created with ID: $tl_id.");

# get task list metadata.
start("Getting the task list's metadata.");
my $metadata = $task_list->get();
end("Task list metadata:\n" . Dump($metadata));

# update task list metadata.
start("Updating the task list's title.");
$task_list->update(title => "${name}_updated");
my $updated = $task_list->get();
end("Updated task list:\n" . Dump($updated));

# delete the task list.
start("Now we'll delete the task list we created.");
$task_list->delete();
end("Task list deleted.");

message('green', "\nTask list basics tutorial complete!");
message('green', "Proceed to 20_task_operations.pl to see task operations.\n");

message('blue', "We are done, here are some api stats:\n", Dump($tasks_api->rest_api()->stats()));
