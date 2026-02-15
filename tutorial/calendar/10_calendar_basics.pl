#!/usr/bin/env perl

# This tutorial demonstrates Calendar API basic operations:
# - Listing calendars
# - Creating a new calendar
# - Getting/updating calendar metadata
# - Showing available colors
# - Deleting a calendar
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/calendar/10_calendar_basics.pl
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

# now set a callback to display the api request/response.
$cal_api->rest_api()->api_callback(\&show_api);

# list the user's calendars.
start("Listing your calendars.");
my @calendars = $cal_api->list_calendars();
end("You have " . scalar(@calendars) . " calendar(s):\n" . Dump(\@calendars));

# create a new calendar.
start("Creating a new calendar named '$name'.");
my $calendar = $cal_api->create_calendar(summary => $name);
my $cal_id = $calendar->calendar_id();
end("Calendar created with ID: $cal_id.");

# get calendar metadata.
start("Getting the calendar's metadata.");
my $metadata = $calendar->get();
end("Calendar metadata:\n" . Dump($metadata));

# update calendar metadata.
start("Updating the calendar's description and location.");
$calendar->update(
  summary     => $name,
  description => 'Created by Google::RestApi Calendar tutorial',
  location    => 'Sydney, Australia',
);
my $updated = $calendar->get();
end("Updated calendar:\n" . Dump($updated));

# show available colors.
start("Fetching available calendar and event colors.");
my $colors = $cal_api->colors();
my $all_colors = $colors->get();
end("Available colors:\n" . Dump($all_colors));

# delete the calendar.
start("Now we'll delete the calendar we created.");
$calendar->delete();
end("Calendar '$name' deleted.");

message('green', "\nCalendar basics tutorial complete!");
message('green', "Proceed to 20_events.pl to see event operations.\n");

message('blue', "We are done, here are some api stats:\n", Dump($cal_api->rest_api()->stats()));
