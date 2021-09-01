package Test::Unit::Utils;

use strict;
use warnings;

use FindBin;

use Exporter qw(import);
our @EXPORT_OK = qw(
  fake_uri_responses_file fake_response_json_file fake_config_file fake_token_file
  fake_spreadsheet_id fake_spreadsheet_name fake_spreadsheet_name2
  fake_worksheet_id fake_worksheet_name
  fake_rest_api fake_sheets_apifake_spreadsheet_uri fake_spreadsheet
  fake_worksheet_uri fake_worksheet
  drive_endpoint sheets_endpoint
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub fake_uri_responses_file { "$FindBin::RealBin/etc/uri_responses/" . shift . ".yaml"; }
sub fake_response_json_file { "$FindBin::RealBin/etc/uri_responses/" . shift . ".json"; }
sub fake_config_file { "$FindBin::RealBin/etc/rest_config.yaml"; }
sub fake_token_file { "$FindBin::RealBin/etc/rest_config.token"; }
sub fake_spreadsheet_id { 'fake_spreadsheet_id1'; }
sub fake_spreadsheet_name { 'fake_spreadsheet1'; }
sub fake_spreadsheet_name2 { 'fake_spreadsheet2'; }
sub fake_worksheet_id { 0; }
sub fake_worksheet_name { 'Sheet1'; }

# TODO: only import these on demand. change to 'require'.
sub fake_rest_api { Google::RestApi->new(config_file => fake_config_file(), @_); }
sub fake_sheets_api { Google::RestApi::SheetsApi4->new(api => fake_rest_api(), @_); }
sub fake_spreadsheet_uri { Google::RestApi::SheetsApi4->Spreadsheet_Uri . '/' . fake_spreadsheet_id(); }
sub fake_spreadsheet { Google::RestApi::SheetsApi4::Spreadsheet->new(sheets_api => fake_sheets_api(), id => fake_spreadsheet_id(), @_); }
sub fake_worksheet_uri { fake_spreadsheet_uri() . "&gid=" . fake_worksheet_id(); }
sub fake_worksheet { Google::RestApi::SheetsApi4::Worksheet->new(spreadsheet => fake_spreadsheet(), id => fake_worksheet_id(), @_); }

sub drive_endpoint { Google::RestApi::DriveApi3->Drive_Endpoint; }
sub sheets_endpoint { Google::RestApi::SheetsApi4->Sheets_Endpoint; }

1;
