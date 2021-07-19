package Test::Unit::TestBase;

use Test::Unit::Setup;

use Capture::Tiny qw(capture_stderr);
use File::Slurp qw(read_file);
use Module::Load qw(load);
use Scalar::Util qw(looks_like_number);
use Test::MockObject::Extra;
use Test::More;   # for diag only.

# need to use this so we can fake it (not sure why).
use Algorithm::Backoff::Exponential;

use parent 'Test::Class';

# init_logger($DEBUG);

sub setup : Tests(setup) {
  my $self = shift;
  $self->{fakes} = {};
  $self->{mock} = Test::MockObject::Extra->new();
  return;
}

sub teardown : Tests(teardown) {
  my $self = shift;
  $self->_unfake();
  return;
}

sub _unfake_http_auth { shift->_unfake('http_auth'); }
sub   _fake_http_auth {
  my $self = shift;
  $self->_fake('http_auth', 'Google::RestApi::Auth::OAuth2Client', 'headers', sub { []; });
  return;
}

sub _unfake_http_response { shift->_unfake('http_response'); }
sub   _fake_http_response {
  my $self = shift;
  my $p = validate_named(\@_,
    code     => Int|StrMatch[qr/^die$/], { default => 200 },
    response => Str|ReadableFile, { default => '{}' },
  );

  my $code = $p->{code};
  my $response = $p->{response};

  my %messages = (
    200 => 'Success',
    400 => 'Bad request',
    429 => 'Too many requests',
    500 => 'Server error',
    die => 'Furl died',
  );
  my $message = $messages{$code} or die "Message missing for code $code";
  
  $response = read_file($response) if -f $response;
  
  my $sub = looks_like_number($code) ?
    sub { Furl::Response->new(1, $code, $message, [], $response); }
    :
    sub { die $message; };
  $self->_fake('http_response', 'Furl', 'request', $sub);
  # this allows the tests to check on rest failures without having to wait for retries.
  # sets the right part of retry::backoff to only wait for .1 seconds between retries.
  $self->_fake('http_response', 'Algorithm::Backoff::Exponential', '_failure', sub { 0.1; });

  return;
}

sub _fake_http_responses {
  my $self = shift;
  my ($api, $responses) = @_;

  my $response = shift @$responses;
  if ($response) {
    $self->_fake_http_response(%$response);
    $api->post_process( sub { $self->_fake_http_responses($api, $responses); } );
  } else {
    $api->post_process();
  }

  return;
}

sub _fake {
  my $self = shift;
  my ($group, $module, $sub, $code) = @_;
  # diag "Faking $group => $module\n";
  $self->{fakes}->{$group}->{$module} = 1;
  $self->{mock}->fake_module($module, $sub => $code);
  return;
}

sub _unfake {
  my $self = shift;
  my ($group) = @_;

  # diag Dump($self->{fakes});
  my @groups;
  if ($group) {
    push(@groups, $group);
  } else {
    @groups = keys %{ $self->{fakes} };
  }

  my @modules = sort map { keys %{ $self->{fakes}->{$_} } } @groups;
  # diag "Unfaking and reloading modules: @modules\n" if @modules;
  for (@modules) {
    $self->{mock}->unfake_module($_);
    # can't seem to suppress 'subroutine redefined' with no warnings pragma.
    # have to capture and throw away stderr. sucks.
    capture_stderr( sub { load $_; } );
  }
  delete %{ $self->{fakes} }{@groups};
  return;
}

1;
