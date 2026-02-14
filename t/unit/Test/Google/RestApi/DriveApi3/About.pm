package Test::Google::RestApi::DriveApi3::About;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::DriveApi3::About';

use parent 'Test::Unit::TestBase';

init_logger;

sub _constructor : Tests(2) {
  my $self = shift;

  ok my $about = About->new(drive_api => mock_drive_api()),
    'Constructor should succeed';
  isa_ok $about, About, 'Constructor returns';

  return;
}

sub get : Tests(2) {
  my $self = shift;

  my $about = mock_drive_api()->about();
  my $info = $about->get();
  ok $info, 'Get returns about info';
  ok $info->{user}, 'About info has user';

  return;
}

sub user : Tests(2) {
  my $self = shift;

  my $about = mock_drive_api()->about();
  my $user = $about->user();
  ok $user, 'User returns user info';
  ok $user->{emailAddress}, 'User has email address';

  return;
}

sub storage_quota : Tests(2) {
  my $self = shift;

  my $about = mock_drive_api()->about();
  my $quota = $about->storage_quota();
  ok $quota, 'Storage quota returns info';
  ok defined $quota->{usage}, 'Quota has usage';

  return;
}

sub export_formats : Tests(1) {
  my $self = shift;

  my $about = mock_drive_api()->about();
  my $formats = $about->export_formats();
  ok $formats, 'Export formats returns info';

  return;
}

1;
