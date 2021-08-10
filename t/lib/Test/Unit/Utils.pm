package Test::Unit::Utils;

use strict;
use warnings;

use FindBin;
use aliased "Google::RestApi";
use aliased "Google::RestApi::SheetsApi4";
use aliased "Google::RestApi::SheetsApi4::Spreadsheet";
use aliased "Google::RestApi::SheetsApi4::Worksheet";

use Exporter qw(import);
our @EXPORT_OK = qw(
  fake_uri_responses_file fake_response_json_file fake_config_file fake_token_file
  fake_rest_api fake_sheets_api
  fake_spreadsheet fake_spreadsheet_name fake_spreadsheet_name2 fake_spreadsheet_id fake_spreadsheet_uri
  fake_worksheet fake_worksheet_name fake_worksheet_id fake_worksheet_uri
  drive_endpoint sheets_endpoint
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub fake_uri_responses_file { "$FindBin::RealBin/etc/uri_responses/" . shift . ".yaml"; }
sub fake_response_json_file { "$FindBin::RealBin/etc/uri_responses/" . shift . ".json"; }
sub fake_config_file { "$FindBin::RealBin/etc/rest_config.yaml"; }
sub fake_token_file { "$FindBin::RealBin/etc/rest_config.token"; }
sub fake_rest_api { RestApi->new(@_, config_file => fake_config_file()); }
sub fake_sheets_api { SheetsApi4->new(@_, api => fake_rest_api()); }
sub fake_spreadsheet { Spreadsheet->new(@_, sheets_api => fake_sheets_api(), id => fake_spreadsheet_id()); }
sub fake_spreadsheet_id { 'fake_spreadsheet_id1'; }
sub fake_spreadsheet_name { 'fake_spreadsheet1'; }
sub fake_spreadsheet_name2 { 'fake_spreadsheet2'; }
sub fake_spreadsheet_uri { SheetsApi4->Spreadsheet_Uri . '/' . fake_spreadsheet_id(); }
sub fake_worksheet { Worksheet->new(@_, spreadsheet => fake_spreadsheet(), id => fake_worksheet_id()); }
sub fake_worksheet_id { 0; }
sub fake_worksheet_name { 'Sheet1'; }
sub fake_worksheet_uri { fake_spreadsheet_uri() . "&gid=" . fake_worksheet_id(); }

sub sheets_endpoint { SheetsApi4->Sheets_Endpoint; }

1;
