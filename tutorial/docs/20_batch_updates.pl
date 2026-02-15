#!/usr/bin/env perl

# This tutorial demonstrates Docs API batch update operations:
# - Inserting text
# - Updating text style (bold, italic, color)
# - Updating paragraph style (alignment)
# - Find and replace
# - Inserting a table
# - Creating and deleting named ranges
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/docs/20_batch_updates.pl
# Add DEBUG=1 for verbose API logging.

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../../t/lib";
use lib "$FindBin::RealBin/../../lib";

use Tutorial::Setup;
use JSON::MaybeXS;

init_logger($TRACE) if $ENV{DEBUG};

my $name = docs_document_name();
my $docs_api = docs_api();

# clean up any documents from previous runs.
start("Cleaning up any documents from previous tutorial runs.");
$docs_api->delete_all_documents($name);
end("Cleanup complete.");

# create a fresh document.
start("Creating a new document named '$name'.");
my $doc = $docs_api->create_document(title => $name);
my $doc_id = $doc->document_id();
end("Document created with ID: $doc_id.");

# now set a callback to display the api request/response.
$docs_api->rest_api()->api_callback(\&show_api);

# insert some text. note: Docs API uses index-based positioning.
# index 1 is the start of the document body (after the section break).
# we insert in reverse order so indices don't shift.
start("Inserting text into the document.");
$doc->insert_text(text => "\n\nThis is a paragraph of body text that we will style later.", index => 1);
$doc->insert_text(text => "Hello from Google::RestApi::DocsApi1!", index => 1);
$doc->submit_requests();
end("Text inserted.");

# get the document to see the current content.
start("Getting the document to see its structure.");
my $content = $doc->get(fields => 'body');
end("Document body:\n" . Dump($content));

# bold the title text.
# "Hello from Google::RestApi::DocsApi1!" is 37 characters at indices 1-38.
start("Making the title text bold.");
$doc->update_text_style(
  range  => { startIndex => 1, endIndex => 38 },
  style  => { bold => JSON::MaybeXS::true },
  fields => 'bold',
);
$doc->submit_requests();
end("Title is now bold.");

# make the title larger by setting font size.
start("Setting the title font size to 18pt.");
$doc->update_text_style(
  range  => { startIndex => 1, endIndex => 38 },
  style  => { fontSize => { magnitude => 18, unit => 'PT' } },
  fields => 'fontSize',
);
$doc->submit_requests();
end("Title font size set.");

# center the title paragraph.
start("Centering the title paragraph.");
$doc->update_paragraph_style(
  range  => { startIndex => 1, endIndex => 38 },
  style  => { alignment => 'CENTER' },
  fields => 'alignment',
);
$doc->submit_requests();
end("Title centered.");

# find and replace text.
start("Replacing 'body text' with 'example text' using find and replace.");
$doc->replace_all_text(
  find        => 'body text',
  replacement => 'example text',
);
$doc->submit_requests();
end("Text replaced.");

# insert a table at the end of the document.
start("Getting document length to find the end index.");
my $doc_content = $doc->get(fields => 'body');
# find the last endIndex in the document body.
my @elements = @{ $doc_content->{body}->{content} };
my $end_index = $elements[-1]->{endIndex} - 1;
end("Document ends at index $end_index.");

start("Inserting a 3x2 table at the end of the document.");
$doc->insert_text(text => "\n", index => $end_index);
$doc->submit_requests();
# re-fetch to get updated indices after inserting the newline.
$doc_content = $doc->get(fields => 'body');
@elements = @{ $doc_content->{body}->{content} };
$end_index = $elements[-1]->{endIndex} - 1;
$doc->insert_table(index => $end_index, rows => 3, columns => 2);
$doc->submit_requests();
end("Table inserted.");

# create a named range on the title.
start("Creating a named range 'title_range' on the title text.");
$doc->create_named_range(
  name  => 'title_range',
  range => { startIndex => 1, endIndex => 38 },
);
$doc->submit_requests();
end("Named range created.");

# get the document to see named ranges.
start("Getting the document's named ranges.");
my $named = $doc->get(fields => 'namedRanges');
end("Named ranges:\n" . Dump($named));

# clean up: delete the document.
start("Deleting the tutorial document.");
$docs_api->delete_document($doc_id);
end("Document deleted.");

message('green', "\nBatch updates tutorial complete!");
message('green', "You've seen text insertion, styling, find/replace, tables, and named ranges.\n");

message('blue', "We are done, here are some api stats:\n", Dump($docs_api->rest_api()->stats()));
