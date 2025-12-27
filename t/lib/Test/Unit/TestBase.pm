package Test::Unit::TestBase;

# regenerate exchanges by setting the appropriate env vars, e.g:
# TEST_CLASS=Test::Google::RestApi::SheetsApi4 GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml \
# GOOGLE_RESTAPI_LOGGER=t/etc/log4perl.conf prove -v t/run_unit_tests.t

use Test::Unit::Setup;

use Carp qw(confess);
use File::Slurp qw(read_file);
use FindBin;
use Furl::Response;
use Hash::Merge qw(merge);
use HTTP::Status qw(:constants);
use Mock::MonkeyPatch;
use Module::Load qw(load);
use PerlX::Maybe;
use Sub::Override;
use Try::Tiny;
use YAML::Any qw(LoadFile);

use parent 'Test::Class';

# coordinate this with Google::RestApi::api.
sub startup : Tests(startup) {
  my $self = shift;

  my $module = ref($self);
  $module =~ s|::|/|g;
  my $exchange_path = "$FindBin::RealBin/unit/$module.pm.exchanges";

  if (my $appender = Log::Log4perl->appender_by_name('UnitTestCapture')) {
    $appender->file_switch($exchange_path);
  } elsif (-f $exchange_path) {
    # normalize the exchanges that we previously collected.
    for (LoadFile($exchange_path)) {
      my $source = delete $_->{source};
      push($self->{exchanges}->{$source}->@*, $_);
    }
  
    $self->_sub_override('Furl', 'request', sub {
      my $test_method;
      for (0..20) {
        my ($package, undef, undef, $subroutine) = caller($_);
        last unless $package;
        next unless $subroutine =~ /^Test::Google::RestApi::/;
        $test_method = $subroutine;
        last;
      }
      confess "Unable to locate test subroutine" unless $test_method;

      my $exchange = shift $self->{exchanges}->{$test_method}->@*
        or confess "Out of exchanges for $test_method";
      my $response = $exchange->{response};
      my $furl = Furl::Response->new(
        1, $response->{code}, $response->{message}, $response->{headers}, $response->{content},
      );
      return $furl;
    });

    # we don't need to process auth requests for local auths.
    $self->_sub_override('Google::RestApi::Auth::OAuth2Client', 'headers', sub { []; });

    # if we are not capturing exchanges, ensure that we don't send any network
    # traffic during our unit tests. this can happen if we don't have
    # 'Furl::request' overridden with a canned response.
    $self->_sub_override('Furl::HTTP', 'connect',
      sub { confess "For unit testing you need to capture exchanges first"; }
    );

    # this allows the tests to check on rest failures without having to wait for retries.
    # sets the right part of retry::backoff to only wait for .1 seconds between retries.
    # otherwise unit tests take ages to run.
    $self->_sub_override('Algorithm::Backoff::Exponential', '_failure', sub { 0.1; });
  }

  return;
}

sub shutdown : Tests(shutdown) { shift->_sub_restore(); return; }

sub create_mock_spreadsheets {
  my $self = shift;
  my @names = @_;
  push @names, mock_spreadsheet_name() unless @names;
  my $sheets_api = mock_sheets_api();
  $self->{mock_spreadsheets}{$_} = $sheets_api->create_spreadsheet(title => $_) for (@names);
  return scalar @names;
}

sub delete_mock_spreadsheets {
  my $self = shift;
  my $sheets_api = mock_sheets_api();
  $sheets_api->delete_spreadsheet($_->spreadsheet_id) for (values $self->{mock_spreadsheets}->%*);
  delete $self->{mock_spreadsheets};
  return;
}

sub mock_spreadsheet {
  my $self = shift;
  my $name = shift || mock_spreadsheet_name();
  return $self->{mock_spreadsheets}{$name};
}

sub mock_spreadsheet_id {
  my $self = shift;
  my $name = shift || mock_spreadsheet_name();
  return $self->{mock_spreadsheets}{$name}->spreadsheet_id;
}

sub mock_spreadsheet_uri {
  my $self = shift;
  my $name = shift || mock_spreadsheet_name();
  return $self->{mock_spreadsheets}{$name}->spreadsheet_uri;
}

sub mock_worksheet {
  my $self = shift;
  my $ss = $self->mock_spreadsheet(@_);
  return $ss->open_worksheet(id => 0);
}

sub mock_worksheet_uri {
  my $self = shift;
  my $name = shift || mock_worksheet_name();
  return $self->mock_worksheet->worksheet_uri;
}

sub mock_http_no_retries {
  my $self = shift;
  $self->_sub_override('Google::RestApi', 'max_attempts', sub { 1; });
  return;
}

sub _sub_override {
  my $self = shift;
  my ($module, $sub, $code) = @_;

  load($module);
  $self->{overrides} //= Sub::Override->new;
  $self->{overrides}->replace("${module}::${sub}" => $code);

  return;
}

# delete the references so the modules get restored.
sub _sub_restore {
  my $self = shift;
  delete $self->{overrides};
  return;
}

1;
