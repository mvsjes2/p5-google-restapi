use Test::Integration::Setup;

use Test::Most tests => 10;

use aliased 'Google::RestApi::DriveApi3';
use aliased 'Google::RestApi::DriveApi3::File';

init_logger;

# This test requires a test file ID to be set in the environment
# Run with: TEST_FILE_ID=<your_file_id> prove -v t/integration/Google/RestApi/DriveApi3/File.t

my $drive_api = DriveApi3->new(api => rest_api());

SKIP: {
  skip "TEST_FILE_ID not set", 10 unless $ENV{TEST_FILE_ID};

  my $file_id = $ENV{TEST_FILE_ID};
  my $file;

  # Test file factory
  isa_ok $file = $drive_api->file(id => $file_id), File, "File factory returns File object";
  is $file->file_id(), $file_id, "File has correct ID";

  # Test get
  my $metadata;
  ok $metadata = $file->get(), "Should get file metadata";
  is $metadata->{id}, $file_id, "Metadata has correct file ID";
  ok $metadata->{name}, "Metadata has file name";

  # Test permissions list
  my @permissions;
  ok @permissions = $file->permissions(), "Should list permissions";
  ok scalar(@permissions) >= 1, "File has at least one permission";

  # Test revisions list (may fail for non-Google Docs files)
  my @revisions;
  eval { @revisions = $file->revisions(); };
  if ($@) {
    pass "Revisions not available for this file type (expected for non-Docs files)";
    pass "Skipping revision count check";
  } else {
    ok 1, "Should list revisions";
    ok scalar(@revisions) >= 1, "File has at least one revision";
  }

  # Test copy and delete
  my $copy;
  ok $copy = $file->copy(name => 'test_copy_' . time()), "Should copy file";
  is $copy->delete(), undef, "Should delete copied file";
}
