package Test::Google::RestApi::DriveApi3::File;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::DriveApi3::File';
use aliased 'Google::RestApi::DriveApi3::Permission';
use aliased 'Google::RestApi::DriveApi3::Revision';
use aliased 'Google::RestApi::DriveApi3::Comment';

use parent 'Test::Unit::TestBase';

init_logger;

sub _constructor : Tests(4) {
  my $self = shift;

  throws_ok sub { File->new(drive => mock_drive_api()) },
    qr/id/i,
    'Constructor without id should throw';

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();

  ok my $file = File->new(drive => mock_drive_api(), id => $file_id),
    'Constructor should succeed';
  isa_ok $file, File, 'Constructor returns';
  is $file->file_id(), $file_id, 'File has correct ID';

  return;
}

sub get : Tests(3) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  my $metadata = $file->get();
  ok $metadata, 'Get should return metadata';
  is $metadata->{id}, $file_id, 'Metadata has correct file ID';
  ok $metadata->{name}, 'Metadata has file name';

  return;
}

sub get_with_fields : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  my $metadata = $file->get(fields => 'id,name,mimeType');
  ok $metadata->{mimeType}, 'Get with fields returns mimeType';
  like $metadata->{mimeType}, qr/spreadsheet/, 'MimeType contains spreadsheet';

  return;
}

sub copy : Tests(3) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  my $copy = $file->copy(name => 'test_copy_' . time());
  isa_ok $copy, File, 'Copy returns File object';
  ok $copy->file_id(), 'Copy has file ID';
  isnt $copy->file_id(), $file_id, 'Copy has different ID than original';

  # Clean up
  $copy->delete();

  return;
}

sub permissions : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  my @perms = $file->permissions();
  ok scalar(@perms) >= 1, 'File has at least one permission';
  ok $perms[0]->{id}, 'Permission has ID';

  return;
}

sub permission_factory : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  ok my $perm = $file->permission(), 'Permission factory without ID should succeed';
  isa_ok $perm, Permission, 'Permission factory returns';

  return;
}

sub revision_factory : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  ok my $rev = $file->revision(), 'Revision factory without ID should succeed';
  isa_ok $rev, Revision, 'Revision factory returns';

  return;
}

sub comment_factory : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  ok my $comment = $file->comment(), 'Comment factory without ID should succeed';
  isa_ok $comment, Comment, 'Comment factory returns';

  return;
}

1;
