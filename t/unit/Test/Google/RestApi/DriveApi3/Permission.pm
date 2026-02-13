package Test::Google::RestApi::DriveApi3::Permission;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::DriveApi3::File';
use aliased 'Google::RestApi::DriveApi3::Permission';

use parent 'Test::Unit::TestBase';

init_logger;

sub _constructor : Tests(3) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  ok my $perm = Permission->new(file => $file),
    'Constructor without id should succeed';
  isa_ok $perm, Permission, 'Constructor returns';

  ok Permission->new(file => $file, id => 'perm123'),
    'Constructor with id should succeed';

  return;
}

sub requires_id : Tests(3) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);
  my $perm = Permission->new(file => $file);

  throws_ok sub { $perm->get() },
    qr/Permission ID required/i,
    'get() without ID should throw';

  throws_ok sub { $perm->update(role => 'reader') },
    qr/Permission ID required/i,
    'update() without ID should throw';

  throws_ok sub { $perm->delete() },
    qr/Permission ID required/i,
    'delete() without ID should throw';

  return;
}

sub create_and_delete : Tests(4) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();
  my $file = mock_drive_api()->file(id => $file_id);

  # Create a public permission
  my $perm = $file->permission()->create(
    role => 'reader',
    type => 'anyone',
  );
  isa_ok $perm, Permission, 'Create returns Permission object';
  ok my $perm_id = $perm->permission_id(), 'Permission has ID';

  # Get the permission
  my $details = $perm->get();
  ok $details, 'Get returns permission details';

  # Delete the permission
  lives_ok sub { $perm->delete() }, 'Delete permission lives';

  return;
}

1;
