package Test::Google::RestApi::GmailApi1::Attachment;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::GmailApi1::Attachment';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my $msg = $gmail->message(id => 'mock_msg_id_001');

  ok my $att = Attachment->new(message => $msg, id => 'att_001'),
    'Constructor with id should succeed';
  isa_ok $att, Attachment, 'Constructor returns';

  return;
}

sub requires_message_id : Tests(1) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my $msg = Google::RestApi::GmailApi1::Message->new(gmail_api => $gmail);

  throws_ok sub { $msg->attachment(id => 'att_001') },
    qr/Message ID required/i,
    'attachment() without message ID should throw';

  return;
}

1;
