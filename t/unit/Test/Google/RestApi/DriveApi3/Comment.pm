package Test::Google::RestApi::DriveApi3::Comment;

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

  ok my $comment = Comment->new(file => $file),
    'Constructor without id should succeed';
  isa_ok $comment, Comment, 'Constructor returns';

  ok Comment->new(file => $file, id => 'comment123'),
    'Constructor with id should succeed';

  return;
}

sub requires_id : Tests(4) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);
  my $comment = Comment->new(file => $file);

  throws_ok sub { $comment->get() },
    qr/Comment ID required/i,
    'get() without ID should throw';

  throws_ok sub { $comment->update(content => 'test') },
    qr/Comment ID required/i,
    'update() without ID should throw';

  throws_ok sub { $comment->delete() },
    qr/Comment ID required/i,
    'delete() without ID should throw';

  throws_ok sub { $comment->reply() },
    qr/Comment ID required/i,
    'reply() without ID should throw';

  return;
}

sub create_and_delete : Tests(4) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  # Create a comment
  my $comment = $file->comment()->create(
    content => 'Test comment from unit tests',
  );
  isa_ok $comment, Comment, 'Create returns Comment object';
  ok my $comment_id = $comment->comment_id(), 'Comment has ID';

  # Get the comment
  my $details = $comment->get();
  ok $details, 'Get returns comment details';

  # Delete the comment
  lives_ok sub { $comment->delete() }, 'Delete comment lives';

  return;
}

sub reply_factory : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  # Create a comment first
  my $comment = $file->comment()->create(
    content => 'Test comment for reply',
  );

  ok my $reply = $comment->reply(), 'Reply factory should succeed';
  isa_ok $reply, Reply, 'Reply factory returns';

  # Clean up
  $comment->delete();

  return;
}

1;
