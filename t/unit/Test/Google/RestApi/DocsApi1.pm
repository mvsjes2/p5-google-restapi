package Test::Google::RestApi::DocsApi1;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::DocsApi1';
use aliased 'Google::RestApi::DocsApi1::Document';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(4) {
  my $self = shift;

  throws_ok sub { DocsApi1->new() },
    qr/api/i,
    'Constructor without api should throw';

  ok my $docs = DocsApi1->new(api => mock_rest_api()), 'Constructor should succeed';
  isa_ok $docs, DocsApi1, 'Constructor returns';
  can_ok $docs, qw(api create_document open_document delete_document
                    documents documents_by_filter
                    drive rest_api);

  return;
}

sub document_factory : Tests(2) {
  my $self = shift;

  my $docs = mock_docs_api();
  ok my $doc = $docs->open_document(id => mock_document_id()), 'Document factory should succeed';
  isa_ok $doc, Document, 'Document factory returns';

  return;
}

sub create_document : Tests(2) {
  my $self = shift;

  my $docs = mock_docs_api();
  ok my $doc = $docs->create_document(title => 'Test Document'), 'Create document should succeed';
  isa_ok $doc, Document, 'Create document returns';

  return;
}

sub page_callback : Tests(4) {
  my $self = shift;
  my $docs = mock_docs_api();

  my $callback_count = 0;
  my @documents = $docs->documents(
    name          => 'Test Document',
    page_callback => sub { $callback_count++; return 1; },
  );
  ok $callback_count > 0, "Page callback was called for documents()";
  ok scalar @documents >= 1, "Documents returned with page callback";

  $callback_count = 0;
  @documents = $docs->documents_by_filter(
    filter        => "name contains 'Test'",
    page_callback => sub { $callback_count++; return 1; },
  );
  ok $callback_count > 0, "Page callback was called for documents_by_filter()";
  ok scalar @documents >= 1, "Documents_by_filter returned with page callback";

  return;
}

1;
