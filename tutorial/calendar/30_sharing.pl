#!/usr/bin/env perl

# This tutorial demonstrates Calendar API ACL (sharing) operations:
# - Creating a calendar
# - Adding ACL rules (sharing)
# - Listing/updating/deleting ACL rules
# - Cleanup
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/calendar/30_sharing.pl
# Add DEBUG=1 for verbose API logging.

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../../t/lib";
use lib "$FindBin::RealBin/../../lib";

use Tutorial::Setup;

init_logger($TRACE) if $ENV{DEBUG};

my $name = calendar_name();
my $cal_api = calendar_api();

# clean up any failed previous runs.
start("Cleaning up any calendars from previous tutorial runs.");
my @existing = $cal_api->list_calendars();
for my $cal (@existing) {
  if ($cal->{summary} && $cal->{summary} eq $name) {
    $cal_api->calendar(id => $cal->{id})->delete();
  }
}
end("Cleanup complete.");

# create a calendar for this tutorial.
start("Creating a calendar named '$name' for ACL operations.");
my $calendar = $cal_api->create_calendar(summary => $name);
my $cal_id = $calendar->calendar_id();
end("Calendar created with ID: $cal_id.");

# now set a callback to display the api request/response.
$cal_api->rest_api()->api_callback(\&show_api);

# list current ACL rules.
start("Listing current ACL rules on the calendar.");
my @rules = $calendar->acl_rules();
end("Calendar has " . scalar(@rules) . " ACL rule(s):\n" . Dump(\@rules));

# add an ACL rule to make the calendar publicly readable.
start("Adding a 'freeBusyReader' ACL rule for the default (public) scope.");
my $acl = $calendar->acl()->create(
  role       => 'freeBusyReader',
  scope_type => 'default',
);
my $acl_id = $acl->acl_id();
end("ACL rule created with ID: $acl_id.");

# get the ACL rule details.
start("Getting the ACL rule details.");
my $acl_details = $acl->get();
end("ACL rule details:\n" . Dump($acl_details));

# list ACL rules again.
start("Listing ACL rules after adding the new rule.");
@rules = $calendar->acl_rules();
end("Calendar now has " . scalar(@rules) . " ACL rule(s):\n" . Dump(\@rules));

# update the ACL rule.
start("Updating the ACL rule to 'reader' role.");
$acl->update(role => 'reader');
my $updated = $acl->get();
end("Updated ACL rule:\n" . Dump($updated));

# delete the ACL rule.
start("Deleting the ACL rule.");
$acl->delete();
end("ACL rule deleted.");

# clean up the calendar.
start("Deleting the tutorial calendar.");
$calendar->delete();
end("Calendar deleted.");

message('green', "\nACL sharing tutorial complete!");
message('green', "Run 99_delete_all.pl to clean up any remaining tutorial resources.\n");

message('blue', "We are done, here are some api stats:\n", Dump($cal_api->rest_api()->stats()));
