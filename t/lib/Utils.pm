package Utils;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib";

use File::Basename;
use File::Temp qw(tempdir);
use Log::Log4perl qw(:easy);
use Term::ANSIColor;
use Test::More;
use YAML::Any qw(Dump LoadFile);

use aliased "Google::RestApi";
use aliased "Google::RestApi::SheetsApi4";

use Exporter qw(import);

our @EXPORT_OK = qw(
  p
  init_logger
  debug_on debug_off
  $OFF $FATAL $WARN $ERROR $INFO $DEBUG $TRACE
  is_array is_hash
  rest_api
  rest_api_config
  sheets_api
  spreadsheet
  spreadsheet_name
  delete_all_spreadsheets
  message start end end_go
  show_api
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub p {
  diag Dump(\@_);
  return;
}

# if you want your own logger, specify the logger config file in GOOGLE_RESTAPI_LOGGER env var.
# else logger will be turned off.
sub init_logger {
  my $logger_conf = $ENV{GOOGLE_RESTAPI_LOGGER};
  if ($logger_conf) {
    Log::Log4perl->init($logger_conf);
  } else {
    Log::Log4perl->easy_init(shift || $OFF);
  }
  return;
}

# this is for log4perl.conf to call back to get the log file name.
sub log_file_name { tempdir() . "/google_restapi.log"; }

sub debug_on {
  Log::Log4perl->get_logger('')->level($DEBUG);
}

sub debug_off {
  Log::Log4perl->get_logger('')->level($OFF);
}

sub is_array {
  my ($array, $test_name) = @_;
  $array = $array->() if ref($array) eq 'CODE';
  is ref($array), 'ARRAY', "$test_name should return an array";
}

sub is_hash {
  my ($hash, $test_name) = @_;
  $hash = $hash->() if ref($hash) eq 'CODE';
  is ref($hash), 'HASH', "$test_name should return a hash";
}

sub delete_all_spreadsheets {
  shift->delete_all_spreadsheets(spreadsheet_name());
  return;
}

sub spreadsheet_name { 'google_restapi_sheets_testing'; }

sub spreadsheet {
  my $sheets = sheets_api();
  return $sheets->create_spreadsheet(title => spreadsheet_name());
}

sub sheets_api {
  my $api = rest_api(@_);
  return SheetsApi4->new(api => $api);
}

sub rest_api_config {
  my $config_file = $ENV{GOOGLE_RESTAPI_CONFIG}
    or die "No testing config file found: set env var GOOGLE_RESTAPI_CONFIG first";
  return $config_file;
}

# set throttle to 1 if you start getting 403's or 429's back from google.
sub rest_api { RestApi->new(@_, config_file => rest_api_config(), throttle => 1); }

sub message { print color(shift), @_, color('reset'), "\n"; }
sub start { message('yellow', @_, ".."); }
sub end { message('green', @_, " Press enter to continue.\n"); <>; }
sub end_go { message('green', @_, "\n"); }

sub show_api {
  my %p = @_;
  my %dump = (
    called           => $p{called},
    response_content => $p{content},
  );
  warn color('magenta'), "Sent request to api:\n", color('reset'), Dump(\%dump);

  return;
}

1;
