package Google::RestApi;

our $VERSION = '0.7';

use Google::RestApi::Setup;

use File::Basename;
use Furl;
use JSON;
use Log::Log4perl qw(get_logger);
use Module::Load qw(load);
use Scalar::Util qw(blessed);
use Retry::Backoff 'retry';
use Storable qw(dclone);
use Time::Out qw(timeout);
use Try::Tiny;
use URI;
use URI::QueryParam;

sub new {
  my $class = shift;

  my $self = merge_config_file(@_);
  state $check = compile_named(
    config_file  => ReadableFile, { optional => 1 },
    auth         => HashRef | Object,
    throttle     => PositiveOrZeroInt, { default => 0 },
    timeout      => Int, { default => 120 },
  );
  $self = $check->(%$self);

  $self->{ua} = Furl->new(timeout => $self->{timeout});

  return bless $self, $class;
}

# TODO: this is a very long routine.
sub api {
  my $self = shift;

  state $check = compile_named(
    uri     => StrMatch[qr(^https://)],
    method  => StrMatch[qr/^(get|head|put|patch|post|delete)$/i], { default => 'get' },
    params  => HashRef[Str|ArrayRef[Str]], { default => {} },
    headers => ArrayRef[Str], { default => [] },
    content => 0,
  );
  my $request = $check->(@_);

  # reset our transaction for this new one.
  $self->{transaction} = {};

  $self->_stat( $request->{method}, 'total' );
  $request->{method} = uc($request->{method});

  my ($package, $line, $i) = ('', '', 0);
  do {
    ($package, undef, $line) = caller(++$i);
  } while($package && $package =~ m|Google::RestApi|);
  $request->{caller} = {
    package => $package,
    line    => $line,
  };
  DEBUG("Rest API request:\n", Dump($request));

  my $base_uri = $request->{uri};
  my $request_content = $request->{content};
  my $request_json = defined $request_content ? encode_json($request_content) : (),

  my @headers;
  push(@headers, 'Content-Type' => 'application/json') if $request_json;
  push(@headers, @{ $request->{headers} });
  push(@headers, @{ $self->auth()->headers() });

  # some (outdated) auth mechanisms may allow auth info in the params.
  my %params = (%{ $request->{params} }, %{ $self->auth()->params() });
  my $uri = URI->new($base_uri);
  $uri->query_form_hash(\%params);
  $request->{uri_string} = $uri->as_string();
  DEBUG("Rest API URI: $request->{method} => $request->{uri_string}");

  my $req = HTTP::Request->new(
    $request->{method}, $request->{uri_string}, \@headers, $request_json
  );
  my ($response, $tries, $last_error) = $self->_api($req);
  $self->{transaction} = {
    request => $request,
    tries   => $tries,
    ($response   ? (response => $response)   : ()),
    ($last_error ? (error    => $last_error) : ()),
  };

  if ($response) {
    my $decoded_content = $response->decoded_content();
    my $decoded_response = $decoded_content ? decode_json($decoded_content) : 1;
    $self->{transaction}->{decoded_response} = $decoded_response;
    DEBUG("Rest API response:\n", Dump( $decoded_response ));
  }

  $self->_post_process();

  if (!$response || !$response->is_success()) {
    $self->_stat('error');
    LOGDIE("Rest API failure:\n", Dump( $self->transaction() ));
  }

  my $logger = get_logger('response.content');
  if ($logger) {
    $logger->info("Rest API URI: $request->{method} => $request->{uri_string}\n");
    $logger->info("Request JSON:\n$request_json\n") if $request_json;
    $logger->info("Response JSON:\n" . ($response->content() ? $response->content() : "''") . "\n\n");
  }

  # used for to avoid google 403's and 429's as with integration tests.
  sleep($self->{throttle}) if $self->{throttle};

  return $self->{transaction}->{decoded_response};
}

sub _api {
  my ($self, $req) = @_;

  # default is exponential backoff, initial delay 1.
  my $tries = 0;
  my $last_error;
  my $response = retry
    sub {
      # timeout is in the ua too, but i've seen requests to spreadsheets
      # completely hang if the request isn't constructed correctly.
      timeout $self->{timeout} => sub { $self->{ua}->request($req); };
    },
    retry_if => sub {
      my $h = shift;
      my $r = $h->{attempt_result};   # Furl::Response
      if (!$r) {
        $last_error = $@ || "Unknown error";
        WARN("API call error: $last_error");
        return 1;
      }
      $last_error = $r->status_line() if !$r->is_success();
      if ($r->code() =~ /^(403|429|50[0234])$/) {
        WARN("Retrying: $last_error");
        return 1;
      }
      return; # we're accepting the response.
    },
    on_success   => sub { $tries++; },
    on_failure   => sub { $tries++; },
    max_attempts => 4;   # override default max_attempts 10.
  return ($response, $tries, $last_error);
}

# convert a plain hash auth to an object if a hash was passed.
sub auth {
  my $self = shift;

  if (!blessed($self->{auth})) {
    # turn OAuth2Client into Google::RestApi::Auth::OAuth2Client etc.
    my $class = __PACKAGE__ . "::Auth::" . delete $self->{auth}->{class};
    load $class;
    # add the path to the base config file so auth hash doesn't have
    # to store the full path name for things like token_file etc.
    $self->{auth}->{config_dir} = dirname($self->{config_file})
      if $self->{config_file};
    $self->{auth} = $class->new(%{ $self->{auth} });
  }

  return $self->{auth};
}

sub _post_process {
  my $self = shift;
  return if !$self->{post_process};
  try {
    $self->{post_process}->( $self->transaction() );
  } catch {
    my $err = $_;
    FATAL("Post process died: $err");
  };
  return;
}

sub post_process {
  my $self = shift;
  state $check = compile(CodeRef, { optional => 1 });
  my ($post_process) = $check->(@_);
  my $prev_post_process = delete $self->{post_process};
  $self->{post_process} = $post_process if $post_process;
  return $prev_post_process;
}

sub _stat {
  my $self = shift;
  my @stats = @_;
  foreach (@stats) {
    $_ = lc;
    $self->{stats}->{$_} //= 0;
    $self->{stats}->{$_}++;
  }
  return;
}

sub stats {
  my $self = shift;
  my $stats = dclone($self->{stats} || {});
  return $stats;
}

sub transaction { shift->{transaction} || {}; }

1;

__END__

=head1 NAME

Google::RestApi - Connection to Google REST APIs (currently Drive and Sheets).

=head1 SYNOPSIS

=over

  use Google::RestApi;
  $rest_api = Google::RestApi->new(
    config_file   => <path_to_config_file>,
    auth          => <object|hashref>,
    timeout       => <int>,
    throttle      => <int>,
    post_process  => <coderef>,
  );

  $response = $rest_api->api(
    uri     => <google_api_url>,
    method  => get|head|put|patch|post|delete,
    headers => [],
    params  => <query_params>,
    content => <data_for_body>,
  );

  use Google::RestApi::SheetsApi4;
  $sheets_api = Google::RestApi::SheetsApi4->new(api => $rest_api);
  $sheet = $sheets_api->open_spreadsheet(title => "payroll");

  use Google::RestApi::DriveApi3;
  $drive = Google::RestApi::DriveApi3->new(api => $rest_api);
  $file = $drive->file(id => 'xxxx');
  $copy = $file->copy(title => 'my-copy-of-xxx');

  print YAML::Any::Dump($rest_api->stats());

=back

=head1 DESCRIPTION

Google Rest API is the foundation class used by the included Drive
and Sheets APIs. It is used to send API requests to the Google API
endpoint on behalf of the underlying API classes (Sheets and Drive).

=head1 SUBROUTINES

=over

=item new(config_file => <path_to_config_file>, auth => <object|hash>, post_process => <coderef>, throttle => <int>);

 config_file: Optional YAML configuration file that can specify any
   or all of the following args:
 auth: A hashref to create the specified auth class, or (outside the config file) an instance of the blessed class itself.
 post_process: A coderef to call after each API call.
 throttle: Used in development to sleep the number of seconds
   specified between API calls to avoid threshhold errors from Google.

You can specify any of the arguments in the optional YAML config file.
Any passed-in arguments will override what is in the config file.

The 'auth' arg can specify a pre-blessed class of one of the Google::RestApi::Auth::*
classes, or, for convenience sake, you can specify a hash of the required
arguments to create an instance of that class:
  auth:
    class: OAuth2Client
    client_id: xxxxxx
    client_secret: xxxxxx
    token_file: <path_to_token_file>

Note that the auth hash itself can also contain a config_file:
  auth:
    class: OAuth2Client
    config_file: <path_to_oauth_config_file>

This allows you the option to keep the auth file in a separate, more secure place.

=item api(uri => <uri_string>, method => <http_method_string>,
  headers => <headers_string_array>, params => <query_parameters_hash>,
  content => <body_hash>);

The ultimate Google API call for the underlying classes. Handles timeouts
and retries etc.

 uri: The Google API endpoint such as https://www.googleapis.com/drive/v3
   along with any path segments added.
 method: The http method being used get|head|put|patch|post|delete.
 headers: Array ref of http headers.
 params: Http query params to be added to the uri.
 content: The body being sent for post/put etc. Will be encoded to JSON.

You would not normally call this directly unless you were
making a Google API call not currently supported by this API
framework.

=item stats();

Shows some statistics on how many get/put/post etc calls were made.
Useful for performance tuning during development.

=back

=head1 SEE ALSO

For specific use of this class, see:

 Google::RestApi::DriveApi3
 Google::RestApi::SheetsApi4

=head1 AUTHORS

=over

=item

Test User mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Test User. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
