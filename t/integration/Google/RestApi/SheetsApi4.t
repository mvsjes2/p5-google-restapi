use Test::Integration::Setup;

use Test::Most tests => 3;

use aliased 'Google::RestApi::SheetsApi4';
use aliased 'Google::RestApi::SheetsApi4::Spreadsheet';

# init_logger($DEBUG);

my ($sheets, $spreadsheet, @spreadsheets);
isa_ok $sheets = SheetsApi4->new(api => rest_api()), SheetsApi4, "New sheets API object";
isa_ok $spreadsheet = $sheets->create_spreadsheet(title => spreadsheet_name()), Spreadsheet, "New spreadsheet object";
is $sheets->delete_spreadsheet($spreadsheet->spreadsheet_id()), 1, "Deleting spreadsheet";
