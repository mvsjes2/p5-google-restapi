#!/usr/bin/env perl

# This tutorial demonstrates Gmail message operations:
# - Sending a message (to yourself)
# - Reading the sent message
# - Modifying message labels
# - Trashing and untrashing
# - Deleting a message
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/gmail/20_send_and_read.pl
# Add DEBUG=1 for verbose API logging.

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../../t/lib";
use lib "$FindBin::RealBin/../../lib";

use Tutorial::Setup;

init_logger($TRACE) if $ENV{DEBUG};

my $gmail_api = gmail_api();
$gmail_api->rest_api()->api_callback(\&show_api);

# get user profile to find our email address.
start("Getting your email address from profile.");
my $profile = $gmail_api->profile();
my $my_email = $profile->{emailAddress};
end("Your email: $my_email");

# send a message to yourself.
start("Sending a test message to yourself.");
my $msg = $gmail_api->send_message(
  to      => $my_email,
  subject => 'Google::RestApi Gmail Tutorial Test',
  body    => "This is a test message sent by the Google::RestApi Gmail tutorial.\n\nYou can safely delete this.",
);
my $msg_id = $msg->message_id();
end("Message sent with ID: $msg_id.");

# read the sent message.
start("Reading the sent message.");
my $details = $msg->get();
end("Message details:\n" . Dump($details));

# modify labels - add STARRED, remove UNREAD.
start("Modifying message labels: adding STARRED, removing UNREAD.");
$msg->modify(
  add_label_ids    => ['STARRED'],
  remove_label_ids => ['UNREAD'],
);
my $modified = $msg->get(fields => 'id, labelIds');
end("Modified message labels:\n" . Dump($modified));

# trash the message.
start("Moving the message to trash.");
$msg->trash();
end("Message moved to trash.");

# untrash the message.
start("Removing the message from trash.");
$msg->untrash();
end("Message removed from trash.");

# trash the message again (cleanup). Permanent delete requires full mail scope.
start("Trashing the test message (cleanup).");
$msg->trash();
end("Message moved to trash (it will be auto-deleted after 30 days).");

message('green', "\nSend and read tutorial complete!");
message('green', "Proceed to 30_threads_and_drafts.pl to see thread and draft operations.\n");

message('blue', "We are done, here are some api stats:\n", Dump($gmail_api->rest_api()->stats()));
