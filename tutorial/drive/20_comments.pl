#!/usr/bin/env perl

# This tutorial demonstrates Drive API comments and replies:
# - Creating comments on a file
# - Replying to comments
# - Listing and reading comments
# - Cleaning up
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/drive/20_comments.pl
# Add DEBUG=1 for verbose API logging.
#
# NOTE: Run 10_file_operations.pl first to create the tutorial spreadsheet.

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../../t/lib";
use lib "$FindBin::RealBin/../../lib";

use Tutorial::Setup;

init_logger($TRACE) if $ENV{DEBUG};

my $name = spreadsheet_name();
my $sheets_api = sheets_api();
my $drive = drive_api(api => $sheets_api->rest_api());

my $spreadsheet_name = spreadsheet_name();
end(
  "NOTE:\n" .
  "Before running this script, you must have already run 10_file_operations.pl.\n" .
  "If more than one spreadsheet exists called '$spreadsheet_name', you must run ../99_delete_all.pl and start over again with 10_file_operations.pl."
);

# find our tutorial spreadsheet.
start("Opening the tutorial spreadsheet '$name'.");
my $ss = $sheets_api->open_spreadsheet(name => $name);
my $file_id = $ss->spreadsheet_id();
my $file = $drive->file(id => $file_id);
end("Spreadsheet opened, ID: $file_id.");

$sheets_api->rest_api()->api_callback(\&show_api);

# create a comment.
start("Now we'll add a comment to the file.");
my $comment = $file->comment()->create(
  content => 'This spreadsheet was created by the tutorial.',
);
my $comment_id = $comment->comment_id();
end("Comment created with ID: $comment_id.");

# read back the comment.
start("Now we'll read the comment back.");
my $details = $comment->get();
end("Comment details:\n" . Dump($details));

# reply to the comment.
start("Now we'll add a reply to the comment.");
my $reply = $comment->reply()->create(
  content => 'Thanks for noting that!',
);
my $reply_id = $reply->reply_id();
end("Reply created with ID: $reply_id.");

# read back the reply.
start("Now we'll read the reply back.");
my $reply_details = $reply->get();
end("Reply details:\n" . Dump($reply_details));

# list all comments on the file.
start("Now we'll list all comments on the file.");
my @comments = $file->comments();
end("File has " . scalar(@comments) . " comment(s):\n" . Dump(\@comments));

# clean up: delete the comment (also deletes its replies).
start("Now we'll delete the comment (this also removes its replies).");
$comment->delete();
end("Comment and replies deleted.");

message('green', "\nRun ../99_delete_all.pl to clean up the tutorial spreadsheet.\n");

message('blue', "We are done, here are some api stats:\n", Dump($sheets_api->stats()));
