#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::RealBin/lib";
use lib "$FindBin::RealBin/../t/lib";
use lib "$FindBin::RealBin/../lib";

use Tutorial::Setup;

init_logger($TRACE) if $ENV{DEBUG};

my $name = spreadsheet_name();
my $sheets_api = sheets_api();
$sheets_api->rest_api()->api_callback(\&show_api);

start("Now we will delete all the spreadsheets we created by listing all spreadsheets deleting any named $name.");
my $count = $sheets_api->delete_all_spreadsheets_by_filters(["name = '$name'", "name = '${name}_copy'", "name = '${name}_drive_copy'"]);
end("Delete complete, deleted $count spreadsheets.");

# clean up calendars.
my $cal_name = calendar_name();
start("Now we will delete all calendars named '$cal_name'.");
my $cal_api = calendar_api();
$cal_api->rest_api()->api_callback(\&show_api);
my @calendars = $cal_api->list_calendars();
my $cal_count = 0;
for my $cal (@calendars) {
  if ($cal->{summary} && $cal->{summary} eq $cal_name) {
    $cal_api->calendar(id => $cal->{id})->delete();
    $cal_count++;
  }
}
end_go("Calendar delete complete, deleted $cal_count calendar(s).");

# clean up gmail labels.
my $gmail_label = gmail_label_name();
start("Now we will delete any Gmail labels named '$gmail_label' or '${gmail_label}_updated'.");
my $gmail = gmail_api();
$gmail->rest_api()->api_callback(\&show_api);
my @gmail_labels = $gmail->labels();
my $gmail_count = 0;
for my $label (@gmail_labels) {
  if ($label->{name} && ($label->{name} eq $gmail_label || $label->{name} eq "${gmail_label}_updated")
      && $label->{type} eq 'user') {
    $gmail->label(id => $label->{id})->delete();
    $gmail_count++;
  }
}
end_go("Gmail label delete complete, deleted $gmail_count label(s).");

# clean up task lists.
my $tasks_name = tasks_list_name();
start("Now we will delete any task lists named '$tasks_name' or '${tasks_name}_updated'.");
my $tasks = tasks_api();
$tasks->rest_api()->api_callback(\&show_api);
my @task_lists = $tasks->list_task_lists();
my $tasks_count = 0;
for my $tl (@task_lists) {
  if ($tl->{title} && ($tl->{title} eq $tasks_name || $tl->{title} eq "${tasks_name}_updated")) {
    $tasks->task_list(id => $tl->{id})->delete();
    $tasks_count++;
  }
}
end_go("Task list delete complete, deleted $tasks_count task list(s).");

message('blue', "We are done, here are some api stats:\n", Dump($sheets_api->stats()));
