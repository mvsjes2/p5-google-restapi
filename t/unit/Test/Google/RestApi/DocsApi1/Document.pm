package Test::Google::RestApi::DocsApi1::Document;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::DocsApi1';
use aliased 'Google::RestApi::DocsApi1::Document';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _setup_live_document : Tests(startup) {
  my $self = shift;
  return unless $ENV{GOOGLE_RESTAPI_CONFIG};
  my $docs = mock_docs_api();
  my $doc = $docs->create_document(title => 'Mock Document');
  $self->{_live_doc} = $doc;
  return;
}

sub _teardown_live_document : Tests(shutdown) {
  my $self = shift;
  if ($self->{_live_doc}) {
    my $docs = mock_docs_api();
    $docs->delete_document($self->{_live_doc}->document_id());
  }
  return;
}

sub _doc_id {
  my $self = shift;
  return $self->{_live_doc} ? $self->{_live_doc}->document_id() : mock_document_id();
}

sub _mock_document {
  my $self = shift;
  my $docs = mock_docs_api();
  return $docs->open_document(id => $self->_doc_id());
}

sub _constructor : Tests(4) {
  my $self = shift;

  throws_ok sub { Document->new() },
    qr/docs_api|Wrong number of parameters/i,
    'Constructor without docs_api should throw';

  my $docs = mock_docs_api();
  ok my $doc = Document->new(docs_api => $docs, id => $self->_doc_id()),
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
  is $doc->document_id(), $self->_doc_id(), 'document_id returns correct ID';
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

sub replace_all_text : Tests(4) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->replace_all_text(find => 'old', replacement => 'new');
  my @requests = $doc->batch_requests();
  is $requests[0]->{replaceAllText}->{replaceText}, 'new', 'Replace all text request is correct';
  is $requests[0]->{replaceAllText}->{containsText}->{matchCase}, JSON::MaybeXS::true(), 'match_case defaults to true';

  # Reset and test with match_case => 0
  $doc = $self->_mock_document();
  $doc->replace_all_text(find => 'old', replacement => 'new', match_case => 0);
  @requests = $doc->batch_requests();
  is $requests[0]->{replaceAllText}->{containsText}->{matchCase}, JSON::MaybeXS::false(), 'match_case false produces JSON false';
  is $requests[0]->{replaceAllText}->{containsText}->{text}, 'old', 'Find text is correct';

  return;
}

sub insert_text_with_segment_id : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->insert_text(text => 'Header text', index => 1, segment_id => 'kix.abc123');
  my @requests = $doc->batch_requests();
  is $requests[0]->{insertText}->{location}->{segmentId}, 'kix.abc123',
    'insert_text includes segmentId when provided';
  is $requests[0]->{insertText}->{text}, 'Header text', 'insert_text text is correct';

  return;
}

sub delete_content : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my %range = (startIndex => 1, endIndex => 10);
  $doc->delete_content(range => \%range);
  my @requests = $doc->batch_requests();
  is $requests[0]->{deleteContentRange}->{range}->{startIndex}, 1, 'delete_content startIndex is correct';
  is $requests[0]->{deleteContentRange}->{range}->{endIndex}, 10, 'delete_content endIndex is correct';

  return;
}

sub update_text_style : Tests(3) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my %range = (startIndex => 1, endIndex => 5);
  my %style = (bold => JSON::MaybeXS::true());
  $doc->update_text_style(range => \%range, style => \%style, fields => 'bold');
  my @requests = $doc->batch_requests();
  is $requests[0]->{updateTextStyle}->{fields}, 'bold', 'update_text_style fields is correct';
  is $requests[0]->{updateTextStyle}->{textStyle}->{bold}, JSON::MaybeXS::true(), 'update_text_style style is correct';
  is $requests[0]->{updateTextStyle}->{range}->{startIndex}, 1, 'update_text_style range is correct';

  return;
}

sub update_paragraph_style : Tests(3) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my %range = (startIndex => 1, endIndex => 10);
  my %style = (alignment => 'CENTER');
  $doc->update_paragraph_style(range => \%range, style => \%style, fields => 'alignment');
  my @requests = $doc->batch_requests();
  is $requests[0]->{updateParagraphStyle}->{fields}, 'alignment', 'update_paragraph_style fields is correct';
  is $requests[0]->{updateParagraphStyle}->{paragraphStyle}->{alignment}, 'CENTER', 'update_paragraph_style style is correct';
  is $requests[0]->{updateParagraphStyle}->{range}->{startIndex}, 1, 'update_paragraph_style range is correct';

  return;
}

sub insert_table : Tests(3) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->insert_table(index => 1, rows => 3, columns => 4);
  my @requests = $doc->batch_requests();
  is $requests[0]->{insertTable}->{rows}, 3, 'insert_table rows is correct';
  is $requests[0]->{insertTable}->{columns}, 4, 'insert_table columns is correct';
  is $requests[0]->{insertTable}->{location}->{index}, 1, 'insert_table location is correct';

  return;
}

sub insert_table_with_segment_id : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->insert_table(index => 1, rows => 2, columns => 2, segment_id => 'kix.seg1');
  my @requests = $doc->batch_requests();
  is $requests[0]->{insertTable}->{location}->{segmentId}, 'kix.seg1',
    'insert_table includes segmentId when provided';

  return;
}

sub insert_inline_image : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->insert_inline_image(index => 1, uri => 'https://example.com/img.png');
  my @requests = $doc->batch_requests();
  is $requests[0]->{insertInlineImage}->{uri}, 'https://example.com/img.png', 'insert_inline_image uri is correct';
  ok !exists $requests[0]->{insertInlineImage}->{objectSize}, 'No objectSize when width/height omitted';

  return;
}

sub insert_inline_image_with_size : Tests(3) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my %width = (magnitude => 200, unit => 'PT');
  my %height = (magnitude => 100, unit => 'PT');
  $doc->insert_inline_image(index => 1, uri => 'https://example.com/img.png', width => \%width, height => \%height);
  my @requests = $doc->batch_requests();
  ok $requests[0]->{insertInlineImage}->{objectSize}, 'objectSize present when width/height provided';
  is $requests[0]->{insertInlineImage}->{objectSize}->{width}->{magnitude}, 200, 'Width magnitude is correct';
  is $requests[0]->{insertInlineImage}->{objectSize}->{height}->{magnitude}, 100, 'Height magnitude is correct';

  return;
}

sub insert_inline_image_with_segment_id : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->insert_inline_image(index => 1, uri => 'https://example.com/img.png', segment_id => 'kix.seg1');
  my @requests = $doc->batch_requests();
  is $requests[0]->{insertInlineImage}->{location}->{segmentId}, 'kix.seg1',
    'insert_inline_image includes segmentId when provided';

  return;
}

sub create_paragraph_bullets : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my %range = (startIndex => 1, endIndex => 20);
  $doc->create_paragraph_bullets(range => \%range, bullet_preset => 'BULLET_DISC_CIRCLE_SQUARE');
  my @requests = $doc->batch_requests();
  is $requests[0]->{createParagraphBullets}->{bulletPreset}, 'BULLET_DISC_CIRCLE_SQUARE',
    'create_paragraph_bullets preset is correct';
  is $requests[0]->{createParagraphBullets}->{range}->{startIndex}, 1,
    'create_paragraph_bullets range is correct';

  return;
}

sub delete_paragraph_bullets : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my %range = (startIndex => 1, endIndex => 20);
  $doc->delete_paragraph_bullets(range => \%range);
  my @requests = $doc->batch_requests();
  is $requests[0]->{deleteParagraphBullets}->{range}->{startIndex}, 1,
    'delete_paragraph_bullets startIndex is correct';
  is $requests[0]->{deleteParagraphBullets}->{range}->{endIndex}, 20,
    'delete_paragraph_bullets endIndex is correct';

  return;
}

sub create_named_range : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my %range = (startIndex => 1, endIndex => 10);
  $doc->create_named_range(name => 'my_range', range => \%range);
  my @requests = $doc->batch_requests();
  is $requests[0]->{createNamedRange}->{name}, 'my_range', 'create_named_range name is correct';
  is $requests[0]->{createNamedRange}->{range}->{startIndex}, 1, 'create_named_range range is correct';

  return;
}

sub delete_named_range : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->delete_named_range('range_id_123');
  my @requests = $doc->batch_requests();
  is $requests[0]->{deleteNamedRange}->{namedRangeId}, 'range_id_123', 'delete_named_range ID is correct';

  return;
}

sub create_header : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->create_header(type => 'DEFAULT');
  my @requests = $doc->batch_requests();
  is $requests[0]->{createHeader}->{type}, 'DEFAULT', 'create_header type is correct';
  ok !exists $requests[0]->{createHeader}->{sectionBreakLocation},
    'No sectionBreakLocation when omitted';

  return;
}

sub create_header_with_section_break : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my %location = (index => 5);
  $doc->create_header(type => 'DEFAULT', section_break_location => \%location);
  my @requests = $doc->batch_requests();
  is $requests[0]->{createHeader}->{sectionBreakLocation}->{index}, 5,
    'create_header includes sectionBreakLocation when provided';

  return;
}

sub create_footer : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->create_footer(type => 'DEFAULT');
  my @requests = $doc->batch_requests();
  is $requests[0]->{createFooter}->{type}, 'DEFAULT', 'create_footer type is correct';
  ok !exists $requests[0]->{createFooter}->{sectionBreakLocation},
    'No sectionBreakLocation when omitted';

  return;
}

sub create_footer_with_section_break : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my %location = (index => 5);
  $doc->create_footer(type => 'DEFAULT', section_break_location => \%location);
  my @requests = $doc->batch_requests();
  is $requests[0]->{createFooter}->{sectionBreakLocation}->{index}, 5,
    'create_footer includes sectionBreakLocation when provided';

  return;
}

sub delete_header : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->delete_header('header_id_123');
  my @requests = $doc->batch_requests();
  is $requests[0]->{deleteHeader}->{headerId}, 'header_id_123', 'delete_header ID is correct';

  return;
}

sub delete_footer : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->delete_footer('footer_id_123');
  my @requests = $doc->batch_requests();
  is $requests[0]->{deleteFooter}->{footerId}, 'footer_id_123', 'delete_footer ID is correct';

  return;
}

sub insert_page_break : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->insert_page_break(index => 5);
  my @requests = $doc->batch_requests();
  is $requests[0]->{insertPageBreak}->{location}->{index}, 5, 'insert_page_break index is correct';
  ok !exists $requests[0]->{insertPageBreak}->{location}->{segmentId},
    'No segmentId when omitted';

  return;
}

sub insert_page_break_with_segment_id : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->insert_page_break(index => 5, segment_id => 'kix.seg1');
  my @requests = $doc->batch_requests();
  is $requests[0]->{insertPageBreak}->{location}->{segmentId}, 'kix.seg1',
    'insert_page_break includes segmentId when provided';

  return;
}

sub insert_section_break : Tests(3) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->insert_section_break(index => 10, type => 'NEXT_PAGE');
  my @requests = $doc->batch_requests();
  is $requests[0]->{insertSectionBreak}->{sectionType}, 'NEXT_PAGE', 'insert_section_break type is correct';
  is $requests[0]->{insertSectionBreak}->{location}->{index}, 10, 'insert_section_break index is correct';
  ok !exists $requests[0]->{insertSectionBreak}->{location}->{segmentId},
    'No segmentId when omitted';

  return;
}

sub insert_section_break_with_segment_id : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();

  $doc->insert_section_break(index => 10, type => 'NEXT_PAGE', segment_id => 'kix.seg1');
  my @requests = $doc->batch_requests();
  is $requests[0]->{insertSectionBreak}->{location}->{segmentId}, 'kix.seg1',
    'insert_section_break includes segmentId when provided';

  return;
}

sub update_document_style : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  my %style = (marginTop => { magnitude => 72, unit => 'PT' });
  $doc->update_document_style(style => \%style, fields => 'marginTop');
  my @requests = $doc->batch_requests();
  is $requests[0]->{updateDocumentStyle}->{fields}, 'marginTop', 'update_document_style fields is correct';
  is $requests[0]->{updateDocumentStyle}->{documentStyle}->{marginTop}->{magnitude}, 72,
    'update_document_style style is correct';

  return;
}

sub accessors : Tests(2) {
  my $self = shift;
  my $doc = $self->_mock_document();

  isa_ok $doc->docs_api(), 'Google::RestApi::DocsApi1', 'docs_api returns DocsApi1';
  isa_ok $doc->rest_api(), 'Google::RestApi', 'rest_api returns RestApi';

  return;
}

sub get_with_fields : Tests(1) {
  my $self = shift;
  my $doc = $self->_mock_document();
  my $result = $doc->get(fields => 'title');
  ok $result, 'Get with fields returns data';

  return;
}

1;
