package Test::Google::RestApi::DriveApi3::Revision;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::DriveApi3::File';
use aliased 'Google::RestApi::DriveApi3::Revision';

use parent 'Test::Unit::TestBase';

init_logger;

sub _constructor : Tests(3) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  ok my $rev = Revision->new(file => $file),
    'Constructor without id should succeed';
  isa_ok $rev, Revision, 'Constructor returns';

  ok Revision->new(file => $file, id => 'rev123'),
    'Constructor with id should succeed';

  return;
}

sub requires_id : Tests(3) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);
  my $rev = Revision->new(file => $file);

  throws_ok sub { $rev->get() },
    qr/Revision ID required/i,
    'get() without ID should throw';

  throws_ok sub { $rev->update(keep_forever => 1) },
    qr/Revision ID required/i,
    'update() without ID should throw';

  throws_ok sub { $rev->delete() },
    qr/Revision ID required/i,
    'delete() without ID should throw';

  return;
}

sub list_revisions : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  my @revisions = $file->revisions();
  ok scalar(@revisions) >= 1, 'File has at least one revision';
  ok $revisions[0]->{id}, 'Revision has ID';

  return;
}

1;
