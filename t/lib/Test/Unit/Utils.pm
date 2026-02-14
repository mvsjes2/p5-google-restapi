package Test::Unit::Utils;

use strict;
use warnings;

use FindBin;
use File::Spec::Functions qw( catfile );
use Module::Load qw( load );

use Exporter qw(import);
our @EXPORT_OK = qw(
  mock_config_file mock_token_file
  mock_spreadsheet_name mock_spreadsheet_name2
  mock_worksheet_id mock_worksheet_name
  mock_rest_api mock_sheets_api mock_drive_api mock_calendar_api mock_gmail_api
  mock_file_id mock_file_name mock_calendar_id
  drive_endpoint sheets_endpoint calendar_endpoint gmail_endpoint
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub mock_config_file { $ENV{GOOGLE_RESTAPI_CONFIG} ? $ENV{GOOGLE_RESTAPI_CONFIG} : catfile($FindBin::RealBin, qw(etc rest_config.yaml)); }
sub mock_token_file { catfile($FindBin::RealBin, qw(etc rest_config.token)); }
sub mock_spreadsheet_name { 'mock_spreadsheet1'; }
sub mock_spreadsheet_name2 { 'mock_spreadsheet2'; }
sub mock_worksheet_id { 0; }
sub mock_worksheet_name { 'Sheet1'; }

# require these ones so that errors in them don't prevent other tests from running.
sub mock_rest_api { _load_and_new('Google::RestApi', config_file => mock_config_file(), @_); }
sub mock_sheets_api { _load_and_new('Google::RestApi::SheetsApi4', api => mock_rest_api(), @_); }
sub mock_drive_api { _load_and_new('Google::RestApi::DriveApi3', api => mock_rest_api(), @_); }
sub mock_calendar_api { _load_and_new('Google::RestApi::CalendarApi3', api => mock_rest_api(), @_); }
sub mock_gmail_api { _load_and_new('Google::RestApi::GmailApi1', api => mock_rest_api(), @_); }
sub mock_file_id { 'mock_file_id_12345'; }
sub mock_file_name { 'mock_file_name'; }
sub mock_calendar_id { 'mock_calendar_id@group.calendar.google.com'; }

sub drive_endpoint { $Google::RestApi::DriveApi3::Drive_Endpoint; }
sub sheets_endpoint { $Google::RestApi::SheetsApi4::Sheets_Endpoint; }
sub calendar_endpoint { $Google::RestApi::CalendarApi3::Calendar_Endpoint; }
sub gmail_endpoint { $Google::RestApi::GmailApi1::Gmail_Endpoint; }

sub _load_and_new {
  my $class = shift;
  load $class;
  return $class->new(@_);
}

1;
