package Test::Google::RestApi::GmailApi1::Thread;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::GmailApi1::Thread';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(3) {
  my $self = shift;

  my $gmail = mock_gmail_api();

  ok my $thread = Thread->new(gmail_api => $gmail),
    'Constructor without id should succeed';
  isa_ok $thread, Thread, 'Constructor returns';

  ok Thread->new(gmail_api => $gmail, id => 'thread123'),
    'Constructor with id should succeed';

  return;
}

sub requires_id : Tests(5) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my $thread = Thread->new(gmail_api => $gmail);

  throws_ok sub { $thread->get() },
    qr/Thread ID required/i,
    'get() without ID should throw';

  throws_ok sub { $thread->modify(add_label_ids => ['STARRED']) },
    qr/Thread ID required/i,
    'modify() without ID should throw';

  throws_ok sub { $thread->trash() },
    qr/Thread ID required/i,
    'trash() without ID should throw';

  throws_ok sub { $thread->untrash() },
    qr/Thread ID required/i,
    'untrash() without ID should throw';

  throws_ok sub { $thread->delete() },
    qr/Thread ID required/i,
    'delete() without ID should throw';

  return;
}

sub get_and_modify : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my $thread = $gmail->thread(id => 'mock_thread_id_001');

  my $details = $thread->get();
  ok $details, 'Get returns thread details';

  lives_ok sub {
    $thread->modify(
      add_label_ids    => ['STARRED'],
      remove_label_ids => ['UNREAD'],
    );
  }, 'Modify thread lives';

  return;
}

sub trash_and_delete : Tests(3) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my $thread = $gmail->thread(id => 'mock_thread_id_001');

  lives_ok sub { $thread->trash() }, 'Trash thread lives';
  lives_ok sub { $thread->untrash() }, 'Untrash thread lives';
  lives_ok sub { $thread->delete() }, 'Delete thread lives';

  return;
}

1;
