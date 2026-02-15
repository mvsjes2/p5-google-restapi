package Tutorial::Utils;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib";

use File::Temp qw(tempdir);
use Log::Log4perl qw(:easy get_logger);
use Term::ANSIColor;
use Test::More;
use YAML::Any qw(Dump LoadFile);

use aliased "Google::RestApi";
use aliased "Google::RestApi::SheetsApi4";
use aliased "Google::RestApi::DriveApi3";
use aliased "Google::RestApi::CalendarApi3";
use aliased "Google::RestApi::GmailApi1";
use aliased "Google::RestApi::TasksApi1";
use aliased "Google::RestApi::DocsApi1";

use Exporter qw(import);
our @EXPORT_OK = qw(
  rest_api sheets_api drive_api calendar_api gmail_api tasks_api docs_api
  spreadsheet_name calendar_name gmail_label_name tasks_list_name docs_document_name
  message start end end_go start_note
  show_api
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub rest_api { RestApi->new(@_, config_file => config_file()); }
sub sheets_api { SheetsApi4->new(api => rest_api(), @_); }
sub drive_api { DriveApi3->new(api => rest_api(), @_); }
sub calendar_api { CalendarApi3->new(api => rest_api(), @_); }
sub gmail_api { GmailApi1->new(api => rest_api(), @_); }
sub tasks_api { TasksApi1->new(api => rest_api(), @_); }
sub docs_api { DocsApi1->new(api => rest_api(), @_); }

# point GOOGLE_RESTAPI_CONFIG to a file that contains the OAuth2 access config
# for integration and tutorials to run. unit tests are mocked so is not needed
# for them.
sub config_file {
  my $config_file = $ENV{GOOGLE_RESTAPI_CONFIG} or do {
    message('red', "No testing config file found: set env var GOOGLE_RESTAPI_CONFIG first.");
    message('yellow', "Run 'bin/google_restapi_oauth_token_creator' and set your env var 'GOOGLE_RESTAPI_CONFIG' " .
        "to point to the config file it creates (e.g. 'GOOGLE_RESTAPI_CONFIG=~/.google/sheets.yaml $0'. " .
        "Taking you to the perldoc now.");
    end();
    exec 'perldoc ../../bin/google_restapi_oauth_token_creator';
  };
  return $config_file;
}

# standard tutorial spreadsheet name.
sub spreadsheet_name { 'google_restapi_sheets_tutorial'; }

# standard tutorial calendar name.
sub calendar_name { 'google_restapi_calendar_tutorial'; }

# standard tutorial gmail label name.
sub gmail_label_name { 'google_restapi_gmail_tutorial'; }

# standard tutorial tasks list name.
sub tasks_list_name { 'google_restapi_tasks_tutorial'; }

# standard tutorial docs document name.
sub docs_document_name { 'google_restapi_docs_tutorial'; }

# used by tutorial to interact with the user as each step in the tutorial is performed.
sub message { print color(shift), @_, color('reset'), "\n"; }
sub start { message('yellow', @_, ".."); }
sub end { message('green', @_, " Press enter to continue.\n"); <>; }
sub end_go { message('green', @_, "\n"); }

sub start_note {
  my $spreadsheet_name = spreadsheet_name();
  end(
    "NOTE:\n" .
    "Before running this script, you must have already run @_.\n" .
    "If more than one spreadsheet exists called '$spreadsheet_name', you must run 99_delete_all and start over again with 10_spreadsheet.pl."
  );
  return;
}

sub show_api {
  my $trans = shift;

  # if debug logging is turned on no sense in repeating the same info.
  my $logger = get_logger();
  return if $logger->level() <= $DEBUG;

  my %dump = (
    request  => $trans->{request},
    response => $trans->{decoded_response},
  );
  warn color('magenta'), "Sent request to api:\n", color('reset'), Dump(\%dump);
  return;
}

1;
