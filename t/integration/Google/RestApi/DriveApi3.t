use Test::Integration::Setup;

use Test::Most tests => 6;

use aliased 'Google::RestApi::DriveApi3';
use aliased 'Google::RestApi::DriveApi3::About';
use aliased 'Google::RestApi::DriveApi3::Changes';

init_logger;

my $drive_api;

# Test DriveApi3 construction
isa_ok $drive_api = DriveApi3->new(api => rest_api()), DriveApi3, "New Drive API object";

# Test About resource
my $about;
isa_ok $about = $drive_api->about(), About, "About factory returns About object";

my $user;
ok $user = $about->user(), "Should get user info";
ok $user->{emailAddress}, "User has email address";

# Test Changes resource
my $changes;
isa_ok $changes = $drive_api->changes(), Changes, "Changes factory returns Changes object";

my $token;
ok $token = $changes->get_start_page_token(), "Should get start page token";
