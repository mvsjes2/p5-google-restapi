#!/usr/bin/env perl

# This tutorial demonstrates Docs API document structure operations:
# - Creating headers and footers
# - Inserting page breaks
# - Updating document style (margins, page size)
# - Paragraph bullets
# - Deleting content
# - Chaining multiple requests
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/docs/30_structure.pl
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

# create a fresh document.
start("Creating a new document named '$name'.");
my $doc = $docs_api->create_document(title => $name);
my $doc_id = $doc->document_id();
end("Document created with ID: $doc_id.");

# now set a callback to display the api request/response.
$docs_api->rest_api()->api_callback(\&show_api);

# create a default header.
start("Creating a default header.");
$doc->create_header(type => 'DEFAULT');
$doc->submit_requests();
end("Header created.");

# create a default footer.
start("Creating a default footer.");
$doc->create_footer(type => 'DEFAULT');
$doc->submit_requests();
end("Footer created.");

# get the document to see headers/footers.
start("Getting the document to see header/footer IDs.");
my $content = $doc->get(fields => 'headers,footers');
end("Headers and footers:\n" . Dump($content));

# add some content with chained requests.
# chaining: each method returns $self so calls can be linked together.
start("Inserting content using chained requests.");
$doc->insert_text(text => "Third item\n", index => 1)
    ->insert_text(text => "Second item\n", index => 1)
    ->insert_text(text => "First item\n", index => 1)
    ->insert_text(text => "Shopping List\n", index => 1);
$doc->submit_requests();
end("Content inserted via chaining.");

# add bullet points to the list items (indices 16 onwards, after "Shopping List\n").
# first, get the document to find the right indices.
start("Getting document to find content indices.");
$content = $doc->get(fields => 'body');
end("Document body:\n" . Dump($content));

# the list items start after "Shopping List\n" (15 chars) at index 16
# and end before the final newline.
start("Adding bullet points to the list items.");
$doc->create_paragraph_bullets(
  range         => { startIndex => 16, endIndex => 49 },
  bullet_preset => 'BULLET_DISC_CIRCLE_SQUARE',
);
$doc->submit_requests();
end("Bullets added.");

# insert a page break after the list.
start("Inserting a page break after the list.");
$content = $doc->get(fields => 'body');
my @elements = @{ $content->{body}->{content} };
my $end_index = $elements[-1]->{endIndex} - 1;
$doc->insert_page_break(index => $end_index);
$doc->submit_requests();
end("Page break inserted.");

# insert text on the second page.
start("Inserting text on the second page.");
$content = $doc->get(fields => 'body');
@elements = @{ $content->{body}->{content} };
$end_index = $elements[-1]->{endIndex} - 1;
$doc->insert_text(text => "This is page two content.", index => $end_index);
$doc->submit_requests();
end("Page two content inserted.");

# update document style — set margins.
start("Updating document margins to 1 inch (72pt) all around.");
$doc->update_document_style(
  style  => {
    marginTop    => { magnitude => 72, unit => 'PT' },
    marginBottom => { magnitude => 72, unit => 'PT' },
    marginLeft   => { magnitude => 72, unit => 'PT' },
    marginRight  => { magnitude => 72, unit => 'PT' },
  },
  fields => 'marginTop,marginBottom,marginLeft,marginRight',
);
$doc->submit_requests();
end("Margins updated.");

# remove the bullets.
start("Removing bullet points from the list.");
$doc->delete_paragraph_bullets(
  range => { startIndex => 16, endIndex => 49 },
);
$doc->submit_requests();
end("Bullets removed.");

# get the headers to find the header ID for deletion.
start("Getting header ID for deletion.");
$content = $doc->get(fields => 'headers');
my @header_ids = keys %{ $content->{headers} || {} };
end("Header IDs: " . join(', ', @header_ids));

# delete the header.
if (@header_ids) {
  start("Deleting the header.");
  $doc->delete_header($header_ids[0]);
  $doc->submit_requests();
  end("Header deleted.");
}

# get the footers to find the footer ID for deletion.
start("Getting footer ID for deletion.");
$content = $doc->get(fields => 'footers');
my @footer_ids = keys %{ $content->{footers} || {} };
end("Footer IDs: " . join(', ', @footer_ids));

# delete the footer.
if (@footer_ids) {
  start("Deleting the footer.");
  $doc->delete_footer($footer_ids[0]);
  $doc->submit_requests();
  end("Footer deleted.");
}

# clean up: delete the document.
start("Deleting the tutorial document.");
$docs_api->delete_document($doc_id);
end("Document deleted.");

message('green', "\nDocument structure tutorial complete!");
message('green', "You've seen headers, footers, page breaks, bullets, margins, and chaining.\n");

message('blue', "We are done, here are some api stats:\n", Dump($docs_api->rest_api()->stats()));
