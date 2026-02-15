package Test::Google::RestApi::DriveApi3;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::DriveApi3';
use aliased 'Google::RestApi::DriveApi3::File';
use aliased 'Google::RestApi::DriveApi3::About';
use aliased 'Google::RestApi::DriveApi3::Changes';
use aliased 'Google::RestApi::DriveApi3::Drive';

use parent 'Test::Unit::TestBase';

init_logger;

sub _constructor : Tests(4) {
  my $self = shift;

  throws_ok sub { DriveApi3->new() },
    qr/api/i,
    'Constructor without api should throw';

  ok my $drive = DriveApi3->new(api => mock_rest_api()), 'Constructor should succeed';
  isa_ok $drive, DriveApi3, 'Constructor returns';
  can_ok $drive, qw(api list file about changes shared_drive list_drives
                    create_drive generate_ids empty_trash upload_endpoint);

  return;
}

sub file_factory : Tests(3) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $file_id = $ss->spreadsheet_id();

  ok my $file = mock_drive_api()->file(id => $file_id), 'File factory should succeed';
  isa_ok $file, File, 'File factory returns';
  is $file->file_id(), $file_id, 'File has correct ID';

  return;
}

sub about : Tests(4) {
  my $self = shift;

  my $drive = mock_drive_api();
  ok my $about = $drive->about(), 'About factory should succeed';
  isa_ok $about, About, 'About factory returns';

  my $user = $about->user();
  ok $user, 'Should get user info';
  ok $user->{emailAddress}, 'User has email address';

  return;
}

sub changes : Tests(3) {
  my $self = shift;

  my $drive = mock_drive_api();
  ok my $changes = $drive->changes(), 'Changes factory should succeed';
  isa_ok $changes, Changes, 'Changes factory returns';

  my $token = $changes->get_start_page_token();
  ok $token, 'Should get start page token';

  return;
}

sub list : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $drive = mock_drive_api();

  my @files = $drive->list(filter => "name = '" . mock_spreadsheet_name() . "'");
  ok scalar(@files) >= 1, 'List should return at least one file';
  ok $files[0]->{id}, 'File has an ID';

  return;
}

sub list_max_pages : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $drive = mock_drive_api();

  my @files = $drive->list(filter => "name = '" . mock_spreadsheet_name() . "'", max_pages => 1);
  ok scalar(@files) >= 1, 'List with max_pages should return results';
  ok $files[0]->{id}, 'File has an ID';

  return;
}

sub list_page_callback_stop : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $drive = mock_drive_api();

  my $callback_called = 0;
  my @files = $drive->list(
    filter        => "name = '" . mock_spreadsheet_name() . "'",
    page_callback => sub { $callback_called++; return 0; },
  );
  ok $callback_called == 1, 'Callback was called once';
  ok scalar(@files) >= 1, 'Should return first page results despite stopping';

  return;
}

sub list_page_callback_continue : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $drive = mock_drive_api();

  # Create a second spreadsheet so there are 2 files to paginate over.
  my $ss2 = mock_sheets_api()->create_spreadsheet(title => mock_spreadsheet_name());

  my $callback_called = 0;
  my @files = $drive->list(
    filter        => "name = '" . mock_spreadsheet_name() . "'",
    params        => { pageSize => 1 },
    page_callback => sub { $callback_called++; return 1; },
  );
  ok $callback_called == 2, 'Callback was called for both pages';
  ok scalar(@files) >= 2, 'Should return results from both pages';

  mock_sheets_api()->delete_spreadsheet($ss2->spreadsheet_id());

  return;
}

sub list_drives_max_pages : Tests(1) {
  my $self = shift;

  my $drive = mock_drive_api();
  my @drives = $drive->list_drives(max_pages => 1);
  ok defined(\@drives), 'list_drives with max_pages accepts param';

  return;
}

sub shared_drive_factory : Tests(2) {
  my $self = shift;

  my $drive = mock_drive_api();
  ok my $sd = $drive->shared_drive(id => 'test_drive_id'), 'Shared drive factory should succeed';
  isa_ok $sd, Drive, 'Shared drive factory returns';

  return;
}

1;
