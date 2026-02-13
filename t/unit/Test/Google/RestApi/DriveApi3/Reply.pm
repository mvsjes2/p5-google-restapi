package Test::Google::RestApi::DriveApi3::Reply;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::DriveApi3::File';
use aliased 'Google::RestApi::DriveApi3::Comment';
use aliased 'Google::RestApi::DriveApi3::Reply';

use parent 'Test::Unit::TestBase';

init_logger;

sub _constructor : Tests(3) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);
  my $comment = $file->comment()->create(content => 'Test comment');

  ok my $reply = Reply->new(comment => $comment),
    'Constructor without id should succeed';
  isa_ok $reply, Reply, 'Constructor returns';

  ok Reply->new(comment => $comment, id => 'reply123'),
    'Constructor with id should succeed';

  # Clean up
  $comment->delete();

  return;
}

sub requires_id : Tests(3) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);
  my $comment = $file->comment()->create(content => 'Test comment');
  my $reply = Reply->new(comment => $comment);

  throws_ok sub { $reply->get() },
    qr/Reply ID required/i,
    'get() without ID should throw';

  throws_ok sub { $reply->update(content => 'test') },
    qr/Reply ID required/i,
    'update() without ID should throw';

  throws_ok sub { $reply->delete() },
    qr/Reply ID required/i,
    'delete() without ID should throw';

  # Clean up
  $comment->delete();

  return;
}

sub create_and_delete : Tests(4) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  # Create a comment first
  my $comment = $file->comment()->create(
    content => 'Test comment for reply',
  );

  # Create a reply
  my $reply = $comment->reply()->create(
    content => 'Test reply from unit tests',
  );
  isa_ok $reply, Reply, 'Create returns Reply object';
  ok my $reply_id = $reply->reply_id(), 'Reply has ID';

  # Get the reply
  my $details = $reply->get();
  ok $details, 'Get returns reply details';

  # Delete the reply
  lives_ok sub { $reply->delete() }, 'Delete reply lives';

  # Clean up comment
  $comment->delete();

  return;
}

sub accessors : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);
  my $comment = $file->comment()->create(content => 'Test comment');
  my $reply = Reply->new(comment => $comment, id => 'reply123');

  is $reply->comment(), $comment, 'comment() returns parent comment';
  is $reply->file()->file_id(), $file_id, 'file() returns parent file via comment';

  # Clean up
  $comment->delete();

  return;
}

1;
