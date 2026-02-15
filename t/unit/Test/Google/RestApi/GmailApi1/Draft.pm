package Test::Google::RestApi::GmailApi1::Draft;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::GmailApi1::Draft';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(3) {
  my $self = shift;

  my $gmail = mock_gmail_api();

  ok my $draft = Draft->new(gmail_api => $gmail),
    'Constructor without id should succeed';
  isa_ok $draft, Draft, 'Constructor returns';

  ok Draft->new(gmail_api => $gmail, id => 'draft123'),
    'Constructor with id should succeed';

  return;
}

sub requires_id : Tests(4) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my $draft = Draft->new(gmail_api => $gmail);

  throws_ok sub { $draft->get() },
    qr/Draft ID required/i,
    'get() without ID should throw';

  throws_ok sub { $draft->update(to => 'a@b.com', subject => 'x', body => 'y') },
    qr/Draft ID required/i,
    'update() without ID should throw';

  throws_ok sub { $draft->send() },
    qr/Draft ID required/i,
    'send() without ID should throw';

  throws_ok sub { $draft->delete() },
    qr/Draft ID required/i,
    'delete() without ID should throw';

  return;
}

sub create_get_and_delete : Tests(4) {
  my $self = shift;

  my $gmail = mock_gmail_api();

  my $draft = $gmail->draft()->create(
    to      => 'test@example.com',
    subject => 'Test Draft',
    body    => 'Draft body text',
  );
  isa_ok $draft, Draft, 'Create returns Draft object';
  ok my $draft_id = $draft->draft_id(), 'Draft has ID';

  my $details = $draft->get();
  ok $details, 'Get returns draft details';

  lives_ok sub { $draft->delete() }, 'Delete draft lives';

  return;
}

1;
