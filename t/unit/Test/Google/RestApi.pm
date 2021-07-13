package Test::Google::RestApi;

use Test::MockObject::Extra;
use Test::Most;

use Utils qw(:all);

use aliased 'Google::RestApi';
use aliased 'Google::RestApi::Auth::OAuth2Client';

use parent 'Test::Class';

# init_logger($DEBUG);

sub class { 'Google::RestApi' }

sub startup : Tests(startup => 5) {
  my $self = shift;

  my $class = $self->class();
  use_ok $class;
  can_ok $class, 'new';

  throws_ok sub { $class->new(config_file => 'x'); }, qr/did not pass type constraint/i, 'Constructor from bad config file should throw';
  ok my $api = $class->new(config_file => fake_config_file()), 'Constructor from proper config_file should succeed';
  isa_ok $api, $class, 'Constructor returns';

  return;
}

sub api : Tests(17) {
  my $self = shift;

  my $class = $self->class();

  my $mock = Test::MockObject::Extra->new();
  $mock->fake_module('Google::RestApi::Auth::OAuth2Client', headers => sub { []; });

  my $api = $class->new(config_file => fake_config_file());
  throws_ok sub { $api->api(uri => 'x'); }, qr/did not pass type constraint/i, 'api: Bad uri should throw';

  _fake_furl($mock, 200, "Success");
  is_hash sub { $api->api(uri => 'https://x') }, 'api: Get 200';
  is $api->transaction()->{tries}, 1, 'api: 200 should have 1 try';
  is $api->transaction()->{error}, undef, 'api: Error should not be set';
  
  $api->api(uri => 'https://x', params => { fred => 'joe' });
  is $api->transaction()->{request}->{uri_string}, 'https://x?fred=joe', 'api: Build uri using params';
  
  throws_ok sub {
    $api->api(uri => 'https://x', params => { fred => { joe => 'pete' } });
  }, qr/did not pass type constraint/i, 'api: Bad params should throw';

  _fake_furl($mock, 400, "Bad request");
  throws_ok sub { $api->api(uri => 'https://x') }, qr/Bad request/i, 'api: Get 400 should throw';
  like $api->transaction()->{error}, qr/400 Bad request/i, 'api: Error should be set';
  is $api->transaction()->{tries}, 1, 'api: 400 should have 1 try';
  
  _fake_furl($mock, 429, "Too many requests");
  throws_ok sub { $api->api(uri => 'https://x') }, qr/Too many requests/i, 'api: Get 429 should throw';
  like $api->transaction()->{error}, qr/429 Too many requests/i, 'api: Error should be set';
  is $api->transaction()->{tries}, 4, 'api: 429 should have 4 tries';

  _fake_furl($mock, 500, "Server error");
  throws_ok sub { $api->api(uri => 'https://x') }, qr/Server error/i, 'api: Get 500 should throw';
  like $api->transaction()->{error}, qr/500 Server error/i, 'api: Error should be set';
  is $api->transaction()->{tries}, 4, 'api: 500 should have 4 tries';

  $mock->fake_module('Furl', request => sub { die "Furl died"; });
  throws_ok sub { $api->api(uri => 'https://x') }, qr/Furl died/i, 'api: Request that dies should throw';
  like $api->transaction()->{error}, qr/Furl died/i, 'api: Error should be set';
  
  $mock->unfake_module('Furl');
  $mock->unfake_module('Google::RestApi::Auth::OAuth2Client');
  
  return;
}

sub _fake_furl {
  my ($mock, $code, $message) = @_;
  $mock->fake_module('Furl',
    request => sub {
      Furl::Response->new(1, $code, $message, [], "{}");
    }
  );
  return;
}

sub auth : Tests(4) {
  my $self = shift;

  my $class = $self->class();

  my %auth = (
    auth => {
      class         => 'x',
      client_id     => 'x',
      client_secret => 'x',
      token_file    => 'x',
    },
  );

  my $api = $class->new(%auth);
  throws_ok sub { $api->auth(); }, qr/you may need to install/i, 'auth: Bad auth class should throw';
  $auth{auth}->{class} = 'OAuth2Client';

  $api = $class->new(%auth);
  throws_ok sub { $api->auth() }, qr/unable to resolve/i, 'auth: Bad token file should throw';

  $auth{auth}->{class} = 'OAuth2Client';
  $auth{auth}->{token_file} = fake_token_file();
  $api = $class->new(%auth);
  isa_ok $api->auth(), OAuth2Client, 'auth: Proper token file should be found';

  %auth = (
    auth => {
      class        => 'ServiceAccount',
      account_file => 'x',
      scope        => ['x'],
    },
  );

  $api = $class->new(%auth);
  throws_ok sub { $api->auth()->account_file() }, qr/unable to resolve/i, 'auth: Bad account file should throw';

  return;
}

1;
