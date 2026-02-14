#!/usr/bin/env perl

# This tutorial demonstrates Gmail API basic operations:
# - Getting user profile
# - Listing labels
# - Creating and deleting a custom label
# - Listing messages
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/gmail/10_gmail_basics.pl
# Add DEBUG=1 for verbose API logging.

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../../t/lib";
use lib "$FindBin::RealBin/../../lib";

use Tutorial::Setup;

init_logger($TRACE) if $ENV{DEBUG};

my $gmail_api = gmail_api();

# clean up any labels from previous runs.
my $label_name = gmail_label_name();
start("Cleaning up any labels from previous tutorial runs.");
my @existing = $gmail_api->labels();
for my $label (@existing) {
  if ($label->{name} && ($label->{name} eq $label_name || $label->{name} eq "${label_name}_updated")
      && $label->{type} eq 'user') {
    $gmail_api->label(id => $label->{id})->delete();
  }
}
end("Cleanup complete.");

# now set a callback to display the api request/response.
$gmail_api->rest_api()->api_callback(\&show_api);

# get user profile.
start("Getting your Gmail profile.");
my $profile = $gmail_api->profile();
end("Profile:\n" . Dump($profile));

# list labels.
start("Listing your labels.");
my @labels = $gmail_api->labels();
end("You have " . scalar(@labels) . " label(s):\n" . Dump(\@labels));

# create a custom label.
start("Creating a custom label named '$label_name'.");
my $label = $gmail_api->label()->create(name => $label_name);
my $label_id = $label->label_id();
end("Label created with ID: $label_id.");

# get label details.
start("Getting the label's details.");
my $details = $label->get();
end("Label details:\n" . Dump($details));

# update the label.
start("Updating the label name.");
$label->update(name => "${label_name}_updated");
my $updated = $label->get();
end("Updated label:\n" . Dump($updated));

# list messages (just 2 pages of 5).
start("Listing your messages (2 pages of up to 5).");
my @messages = $gmail_api->messages(max_pages => 2, params => { maxResults => 5 });
end("Found " . scalar(@messages) . " message(s):\n" . Dump(\@messages));

# delete the label.
start("Now we'll delete the label we created.");
$label->delete();
end("Label deleted.");

message('green', "\nGmail basics tutorial complete!");
message('green', "Proceed to 20_send_and_read.pl to see message operations.\n");

message('blue', "We are done, here are some api stats:\n", Dump($gmail_api->rest_api()->stats()));
