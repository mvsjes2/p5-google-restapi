package Test::Google::RestApi::DocsApi1::Document;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::DocsApi1';
use aliased 'Google::RestApi::DocsApi1::Document';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _mock_document {
  my $self = shift;
  my $docs = mock_docs_api();
  return $docs->open_document(id => mock_document_id());
}

sub _constructor : Tests(4) {
  my $self = shift;

  throws_ok sub { Document->new() },
    qr/docs_api/i,
    'Constructor without docs_api should throw';

  my $docs = mock_docs_api();
  ok my $doc = Document->new(docs_api => $docs, id => mock_document_id()),
    'Constructor should succeed';
  isa_ok $doc, Document, 'Constructor returns';
  can_ok $doc, qw(api document_id get submit_requests
                    insert_text delete_content replace_all_text
                    update_text_style update_paragraph_style
                    insert_table insert_inline_image
                    create_paragraph_bullets delete_paragraph_bullets
                    create_named_range delete_named_range
                    create_header create_footer delete_header delete_footer
                    insert_page_break insert_section_break
                    update_document_style
                    docs_api rest_api);

  return;
}

sub document_id : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();
  is $doc->document_id(), mock_document_id(), 'document_id returns correct ID';
  return;
}

sub get_document : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();
  my $result = $doc->get();
  ok $result, 'Get returns data';
  is $result->{title}, 'Mock Document', 'Get returns title';
  return;
}

sub batch_request_queuing : Tests(3) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my @requests = $doc->batch_requests();
  is scalar @requests, 0, 'No requests queued initially';

  $doc->insert_text(text => 'Hello', index => 1);
  @requests = $doc->batch_requests();
  is scalar @requests, 1, 'One request queued after insert_text';

  $doc->insert_text(text => ' World', index => 6);
  @requests = $doc->batch_requests();
  is scalar @requests, 2, 'Two requests queued after second insert_text';

  return;
}

sub no_merge : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  # Docs requests should never merge (position-sensitive)
  $doc->insert_text(text => 'A', index => 1);
  $doc->insert_text(text => 'B', index => 2);
  my @requests = $doc->batch_requests();
  is scalar @requests, 2, 'Two insert_text requests are not merged';
  is $requests[0]->{insertText}->{text}, 'A', 'First request preserved';

  return;
}

sub chaining : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my $result = $doc->insert_text(text => 'Hello', index => 1)
                    ->insert_text(text => ' World', index => 6);
  isa_ok $result, Document, 'Chaining returns Document';

  return;
}

sub submit_requests : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->insert_text(text => 'Hello World', index => 1);
  my $result = $doc->submit_requests();
  ok $result, 'submit_requests returns result';
  ok $result->{replies}, 'Result contains replies';

  return;
}

sub submit_empty : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my $result = $doc->submit_requests();
  ok !$result, 'submit_requests with no queued requests returns undef';

  return;
}

sub replace_all_text : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->replace_all_text(find => 'old', replacement => 'new');
  my @requests = $doc->batch_requests();
  is $requests[0]->{replaceAllText}->{replaceText}, 'new', 'Replace all text request is correct';

  return;
}

1;
