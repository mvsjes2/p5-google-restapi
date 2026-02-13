package Test::Google::RestApi::DriveApi3::Changes;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::DriveApi3::Changes';

use parent 'Test::Unit::TestBase';

init_logger;

sub _constructor : Tests(2) {
  my $self = shift;

  ok my $changes = Changes->new(drive_api => mock_drive_api()),
    'Constructor should succeed';
  isa_ok $changes, Changes, 'Constructor returns';

  return;
}

sub get_start_page_token : Tests(1) {
  my $self = shift;

  my $changes = mock_drive_api()->changes();
  my $token = $changes->get_start_page_token();
  ok $token, 'Get start page token returns a token';

  return;
}

sub list : Tests(2) {
  my $self = shift;

  my $changes = mock_drive_api()->changes();
  my $token = $changes->get_start_page_token();

  my $result = $changes->list(page_token => $token);
  ok $result, 'List returns result';
  ok exists $result->{newStartPageToken}, 'Result has newStartPageToken';

  return;
}

1;
