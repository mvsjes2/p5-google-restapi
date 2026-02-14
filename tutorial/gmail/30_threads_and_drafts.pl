#!/usr/bin/env perl

# This tutorial demonstrates Gmail thread and draft operations:
# - Creating a draft
# - Getting draft details
# - Updating a draft
# - Sending a draft
# - Listing threads
# - Getting thread details
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/gmail/30_threads_and_drafts.pl
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

# create a draft.
start("Creating a draft message.");
my $draft = $gmail_api->draft()->create(
  to      => $my_email,
  subject => 'Google::RestApi Draft Tutorial Test',
  body    => 'This is a draft created by the tutorial.',
);
my $draft_id = $draft->draft_id();
end("Draft created with ID: $draft_id.");

# get draft details.
start("Getting the draft details.");
my $details = $draft->get();
end("Draft details:\n" . Dump($details));

# update the draft.
start("Updating the draft content.");
$draft->update(
  to      => $my_email,
  subject => 'Google::RestApi Draft Tutorial Test (Updated)',
  body    => 'This is an updated draft created by the tutorial.',
);
my $updated = $draft->get();
end("Updated draft:\n" . Dump($updated));

# send the draft.
start("Sending the draft.");
$draft->send();
end("Draft sent successfully.");

# list threads (1 page of 5).
start("Listing your threads (1 page of up to 5).");
my @threads = $gmail_api->threads(max_pages => 1, params => { maxResults => 5 });
end("Found " . scalar(@threads) . " thread(s):\n" . Dump(\@threads));

# get a thread (use the first one from the list).
if (@threads) {
  my $thread_id = $threads[0]->{id};
  start("Getting details of thread: $thread_id.");
  my $thread = $gmail_api->thread(id => $thread_id);
  my $thread_details = $thread->get(format => 'metadata');
  end("Thread details:\n" . Dump($thread_details));
}

message('green', "\nThreads and drafts tutorial complete!");

message('blue', "We are done, here are some api stats:\n", Dump($gmail_api->rest_api()->stats()));
