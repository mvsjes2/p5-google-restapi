#!/usr/bin/env perl

# This tutorial demonstrates Docs API basic operations:
# - Creating a new document
# - Getting document content
# - Listing documents via Drive
# - Deleting a document
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/docs/10_document_basics.pl
# Add DEBUG=1 for verbose API logging.

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../../t/lib";
use lib "$FindBin::RealBin/../../lib";

use Tutorial::Setup;

init_logger($TRACE) if $ENV{DEBUG};

my $name = docs_document_name();
my $docs_api = docs_api();

# clean up any documents from previous runs.
start("Cleaning up any documents from previous tutorial runs.");
$docs_api->delete_all_documents($name);
end("Cleanup complete.");

# now set a callback to display the api request/response.
$docs_api->rest_api()->api_callback(\&show_api);

# list existing documents.
start("Listing your Google Docs documents (first page via Drive).");
my @docs = $docs_api->documents();
end("You have " . scalar(@docs) . " document(s):\n" . Dump(\@docs));

# create a new document.
start("Creating a new document named '$name'.");
my $doc = $docs_api->create_document(title => $name);
my $doc_id = $doc->document_id();
end("Document created with ID: $doc_id.");

# get document content.
start("Getting the document's content.");
my $content = $doc->get();
end("Document content:\n" . Dump($content));

# get just the title field.
start("Getting just the document title.");
my $title_only = $doc->get(fields => 'title');
end("Title: $title_only->{title}");

# list documents again to see our new one.
start("Listing documents filtered by name '$name'.");
my @filtered = $docs_api->documents(name => $name);
end("Found " . scalar(@filtered) . " document(s) named '$name':\n" . Dump(\@filtered));

# delete the document.
start("Deleting the document we created.");
$docs_api->delete_document($doc_id);
end("Document deleted.");

message('green', "\nDocument basics tutorial complete!");
message('green', "Proceed to 20_batch_updates.pl to see batch update operations.\n");

message('blue', "We are done, here are some api stats:\n", Dump($docs_api->rest_api()->stats()));
