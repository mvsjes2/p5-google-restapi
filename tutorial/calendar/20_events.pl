#!/usr/bin/env perl

# This tutorial demonstrates Calendar API event operations:
# - Creating timed and all-day events
# - Quick add events
# - Getting/updating/listing/deleting events
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/calendar/20_events.pl
# Add DEBUG=1 for verbose API logging.

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../../t/lib";
use lib "$FindBin::RealBin/../../lib";

use Tutorial::Setup;
use POSIX qw(strftime);

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
start("Creating a calendar named '$name' for event operations.");
my $calendar = $cal_api->create_calendar(summary => $name);
my $cal_id = $calendar->calendar_id();
end("Calendar created with ID: $cal_id.");

# now set a callback to display the api request/response.
$cal_api->rest_api()->api_callback(\&show_api);

# create a timed event.
my $tomorrow = strftime('%Y-%m-%d', localtime(time + 86400));
start("Creating a timed event for tomorrow ($tomorrow).");
my $event = $calendar->event()->create(
  summary => 'Tutorial Meeting',
  start   => { dateTime => "${tomorrow}T10:00:00", timeZone => 'Australia/Sydney' },
  end     => { dateTime => "${tomorrow}T11:00:00", timeZone => 'Australia/Sydney' },
  description => 'Created by Google::RestApi Calendar tutorial',
);
my $event_id = $event->event_id();
end("Event created with ID: $event_id.");

# get event details.
start("Getting the event details.");
my $details = $event->get();
end("Event details:\n" . Dump($details));

# update the event.
start("Updating the event summary and adding a location.");
$event->update(
  summary  => 'Updated Tutorial Meeting',
  location => 'Conference Room A',
);
my $updated = $event->get();
end("Updated event:\n" . Dump($updated));

# create an all-day event.
start("Creating an all-day event.");
my $allday = $calendar->event()->create(
  summary => 'Tutorial All-Day Event',
  start   => { date => $tomorrow },
  end     => { date => $tomorrow },
);
end("All-day event created with ID: " . $allday->event_id());

# quick add an event.
start("Quick adding an event with natural language.");
my $quick = $calendar->event()->quick_add(
  text => "Lunch with team next Friday at 12pm",
);
end("Quick add event created with ID: " . $quick->event_id());

# list all events.
start("Listing all events on the calendar.");
my @events = $calendar->events();
end("Calendar has " . scalar(@events) . " event(s):\n" . Dump(\@events));

# delete events.
start("Deleting the events we created.");
$event->delete();
$allday->delete();
$quick->delete();
end("Events deleted.");

# clean up the calendar.
start("Deleting the tutorial calendar.");
$calendar->delete();
end("Calendar deleted.");

message('green', "\nEvent operations tutorial complete!");
message('green', "Proceed to 30_sharing.pl to see ACL operations.\n");

message('blue', "We are done, here are some api stats:\n", Dump($cal_api->rest_api()->stats()));
