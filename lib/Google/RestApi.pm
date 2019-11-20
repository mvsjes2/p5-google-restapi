package Google::RestApi;

use strict;
use warnings;

our $VERSION = '0.3';

use 5.010_000;

use autodie;
use File::Basename;
use Furl;
use JSON;
use Hash::Merge;
use Sub::Retry;
use Storable qw(dclone retrieve);
use Time::Out qw(timeout);
use Type::Params qw(compile compile_named);
use Types::Standard qw(Str StrMatch Int ArrayRef HashRef CodeRef slurpy Any);
use URI;
use URI::QueryParam;
use WWW::Google::Cloud::Auth::ServiceAccount;
use YAML::Any qw(Dump LoadFile);

use Google::RestApi::OAuth2;
use Google::RestApi::Utils qw(named_extra);

no autovivification;

do 'Google/RestApi/logger_init.pl';

sub new {
  my $class = shift;

  state $check = compile_named(
    config_file          => Str, { optional => 1 },
    service_account_file => Str, { optional => 1 },
    _extra_              => slurpy Any,
  );
  my $self = named_extra($check->(@_));


  if ($self->{config_file}) {
    my $config = eval { LoadFile($self->{config_file}) };
    die "Unable to load config file '$self->{config_file}': $@" if $@;
    $self = Hash::Merge::merge($self, $config);
  } elsif ($self->{service_account_file}) {
    die "Unable to find Service Account JSON file at: $self->{service_account_file}" unless -e $self->{service_account_file};
  }



  state $check2 = compile_named(
    config_file          => Str, { optional => 1 },
    client_id            => Str, { optional => 1 },
    client_secret        => Str, { optional => 1 },
    token_file           => Str, { optional => 1 },
    service_account_file => Str, { optional => 1 },
    timeout              => Int, { default => 120 },
    throttle             => Int->where('$_ > -1'), { default => 0 },
    post_process         => CodeRef, { optional => 1 },
  );
  $self = $check2->(%$self);

  if ($self->{service_account_file}) {
    my $auth = WWW::Google::Cloud::Auth::ServiceAccount->new(
       credentials_path => $self->{service_account_file},
       scope => join( ' ', # undocumented feature of WWW::Google::Cloud::Auth::ServiceAccount-
        'https://www.googleapis.com/auth/drive',
        'https://www.googleapis.com/auth/spreadsheets',
       ),
    );
    $self->{service_account_auth} = $auth;
    die "Service Account Auth did not work" unless $self->{service_account_auth}->get_token();
  } else {
    $self->{token_file} = dirname($self->{config_file}) . "/$self->{token_file}"
      if !-f $self->{token_file} && $self->{config_file};
    die "Token file not found: '$self->{token_file}'"
      if !-f $self->{token_file};
  }

  return bless $self, $class;
}

sub api {
  my $self = shift;

  state $check = compile_named(
    uri     => Str,
    method  => StrMatch[qr/^(get|head|put|patch|post|delete)$/i], { default => 'get' },
    headers => ArrayRef[Str], { default => [] },
    params  => HashRef, { default => {} },
    content => 1, { optional => 1 },
  );
  my $p = $check->(@_);

  $self->_stat( $p->{method}, 'total' );
  $p->{method} = uc($p->{method});

  my ($package, $line, $i) = ('', '', 0);
  do {
    ($package, undef, $line) = caller(++$i);
  } while($package && $package =~ m|Google::RestApi|);
  $p->{caller} = {
    package => $package,
    line    => $line,
  };
  DEBUG("Rest API request:\n", Dump($p));

  my $uri = $p->{uri};
  my $content = $p->{content};

  my @headers;
  push(@headers, 'Content-Type' => 'application/json') if $content;
  push(@headers, @{ $p->{headers} });

  $uri = URI->new($uri);
  $uri->query_form_hash($p->{params});
  DEBUG("Rest API URI: $p->{method} ", $uri->as_string());
  my $req = HTTP::Request->new(
    $p->{method}, $uri->as_string(), \@headers,
    $content ? encode_json($content) : (),
  );

  my $api_response = $self->_api($req);
  if (!$api_response) {
    $self->_stat('error');
    LOGDIE("Rest API failure: Nothing returned from request:\n", Dump({called => $p}));
  }
  if (!$api_response->is_success()) {
    $self->_stat('error');
    my $error = {
      code    => $api_response->code(),
      message => $api_response->message(),
      status  => $api_response->status_line(),
      called  => $p,
    };
    $error->{response} = eval { decode_json($api_response->decoded_content()); };
    LOGDIE("Rest API failure:\n", Dump($error));
  }

  my $api_content = $api_response->decoded_content();
  $api_content = $api_content ? decode_json($api_content) : 1;

  $self->{post_process}->(
    content  => $api_content,
    response => $api_response,
    called   => $p,
  ) if $self->{post_process};
  DEBUG("Rest API response:\n", Dump($api_content));

  # used for integration tests to avoid google 403's.
  sleep($self->{throttle}) if $self->{throttle};

  return wantarray ? ($api_content, $api_response, $p) : $api_content;
}

sub post_process {
  my $self = shift;
  state $check = compile(CodeRef, { optional => 1 });
  my ($process) = $check->(@_);
  if (!$process) {
    delete $self->{post_process};
    return;
  }
  $self->{post_process} = $process;
  return;
}

sub _stat {
  my $self = shift;
  my @stats = @_;
  $_ = lc for @stats;
  foreach (@stats) {
    $self->{stats}->{$_} //= 0;
    $self->{stats}->{$_}++;
  }
  return;
}

sub _api {
  my ($self, $req) = @_;

  my $res = retry 3, 1.0,
    sub {
      # timeout is in the ua too, but i've seen requests to spreadsheets completely hang.
      timeout $self->{timeout} => sub {
        $self->ua()->request($req);
      };
    },
    sub {
      my $r = shift;
      if (!$r) {
        WARN("Not an HTTP::Response: $@");
        return 1;      # 1 = do retry
      } elsif ($r->status_line() =~ /^500\s+Internal Response/i or $r->code =~ /^50[234]$/) {
        WARN('Retrying: %s', $r->status_line());
        return 1;
      }
      return;
    };

  return $res;
}

sub ua {
  my $self = shift;
  if (!$self->{ua}) {
    my $access_token = $self->access_token();
    $self->{ua} = Furl->new(
      headers => [ Authorization => "Bearer $access_token" ],
      timeout => $self->{timeout},
    );
  }
  return $self->{ua};
}

sub access_token {
  my $self = shift;
  return $self->{access_token} = $self->{service_account_auth}->get_token() if $self->{service_account_auth}; 
  return $self->{access_token} if $self->{access_token};

  state $check = compile_named(
    scope => ArrayRef, { optional => 1 },
  );
  my $p = $check->(@_);

  my $oauth2 = Google::RestApi::OAuth2->new(
    client_id     => $self->{client_id},
    client_secret => $self->{client_secret},
    $p->{scope} ? (scope => $p->{scope}) : (),
    #scope         => [qw(
    #  https://www.googleapis.com/auth/drive
    #  https://www.googleapis.com/auth/spreadsheets
    #)],
  );
  $oauth2->access_token(
    auto_refresh  => 1,
    refresh_token => retrieve($self->{token_file})->{refresh_token},
  );
  $oauth2->refresh_token();
  $self->{access_token} = $oauth2->access_token()->access_token();
  INFO("Successfully attained access token");

  return $self->{access_token};
}

sub stats {
  my $self = shift;
  my $stats = $self->{stats} || {};
  $stats = dclone($stats);
  return $stats;
}

1;

__END__

=head1 NAME

Google::RestApi - Connection to Google REST APIs (currently Drive and Sheets).

=head1 SYNOPSIS

=over

  use Google::RestApi;
  $rest_api = Google::RestApi->new(
    config_file          => <path_to_config_file>,
    client_id            => <oauth2_client_id>,
    client_secret        => <oath2_secret>,
    token_file           => <path_to_token_file>,
    service_account_file => <path_to_service_account_file>,
    timeout              => <int>,
    throttle             => <int>,
    post_process         => <coderef>,
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
and Sheets APIs. It is used to establish an OAuth2 handshake, and
send API requests to the Google API endpoint on behalf of the
underlying API classes (Sheets and Drive).

Once you have established the OAuth2 handshake, you would not
use this class much, it would be used indirectly by the Drive/Sheets
API classes.

=head1 SUBROUTINES

=over

=item new(config_file => <path_to_config_file>, client_id => <str>, client_secret => <str>, token_file => <path_to_token_file>, post_process => <coderef>, throttle => <int>);

 config_file: Optional YAML configuration file that can specify any
   or all of the following args:
 client_id: The OAuth2 client id you got from Google.
 client_secret: The OAuth2 client secret you got from Google.
 token_file: The file path to the previously saved token (see OAUTH2
   SETUP below). If a config_file is passed, the dirname of the config
   file is tried to find the token_file (same directory) if only the
   token file name is passed.
 service_account_file: Alternatively, a Google Service Account can be used.
   This is the path to the provided JSON file.
 post_process: A coderef to call after each API call.
 throttle: Used in development to sleep the number of seconds
   specified between API calls to avoid threshhold errors from Google.

You can specify any of the arguments in the optional YAML config file.
Any passed in arguments will override what is in the config file.
   
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

=head1 OAUTH2 SETUP

This class depends on first creating an OAuth2 token session file
that you point to via the 'token_file' config param passed via 'new'.
See bin/google_restapi_session_creator and follow the instructions to
save your token file.

=head1 SEE ALSO

For specific use of this class, see:

 Google::RestApi::SheetsApi4
 Google::RestApi::DriveApi3

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
