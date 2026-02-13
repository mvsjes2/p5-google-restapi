package Test::Google::RestApi::DriveApi3::Drive;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::DriveApi3::Drive';

use parent 'Test::Unit::TestBase';

init_logger;

sub _constructor : Tests(3) {
  my $self = shift;

  ok my $drive = Drive->new(drive_api => mock_drive_api()),
    'Constructor without id should succeed';
  isa_ok $drive, Drive, 'Constructor returns';

  ok Drive->new(drive_api => mock_drive_api(), id => 'drive123'),
    'Constructor with id should succeed';

  return;
}

sub requires_id : Tests(4) {
  my $self = shift;

  my $drive = Drive->new(drive_api => mock_drive_api());

  throws_ok sub { $drive->get() },
    qr/Drive ID required/i,
    'get() without ID should throw';

  throws_ok sub { $drive->update(name => 'test') },
    qr/Drive ID required/i,
    'update() without ID should throw';

  throws_ok sub { $drive->delete() },
    qr/Drive ID required/i,
    'delete() without ID should throw';

  throws_ok sub { $drive->hide() },
    qr/Drive ID required/i,
    'hide() without ID should throw';

  return;
}

# Note: Creating/deleting shared drives requires special permissions
# These tests only verify the constructor and validation logic

1;
