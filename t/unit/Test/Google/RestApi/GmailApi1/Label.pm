package Test::Google::RestApi::GmailApi1::Label;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::GmailApi1::Label';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(3) {
  my $self = shift;

  my $gmail = mock_gmail_api();

  ok my $label = Label->new(gmail_api => $gmail),
    'Constructor without id should succeed';
  isa_ok $label, Label, 'Constructor returns';

  ok Label->new(gmail_api => $gmail, id => 'Label_1'),
    'Constructor with id should succeed';

  return;
}

sub requires_id : Tests(3) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my $label = Label->new(gmail_api => $gmail);

  throws_ok sub { $label->get() },
    qr/Label ID required/i,
    'get() without ID should throw';

  throws_ok sub { $label->update(name => 'test') },
    qr/Label ID required/i,
    'update() without ID should throw';

  throws_ok sub { $label->delete() },
    qr/Label ID required/i,
    'delete() without ID should throw';

  return;
}

sub create_and_delete : Tests(4) {
  my $self = shift;

  my $gmail = mock_gmail_api();

  my $label = $gmail->label()->create(name => 'Test Label');
  isa_ok $label, Label, 'Create returns Label object';
  ok my $label_id = $label->label_id(), 'Label has ID';

  my $details = $label->get();
  ok $details, 'Get returns label details';

  lives_ok sub { $label->delete() }, 'Delete label lives';

  return;
}

1;
