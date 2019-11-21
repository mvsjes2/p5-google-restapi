package Google::RestApi::Auth::ServiceAccount;

use strict;
use warnings;

our $VERSION = '0.3';

use 5.010_000;

use autodie;
use File::Basename;
use Type::Params qw(compile_named);
use Types::Standard qw(Str ArrayRef);
use WWW::Google::Cloud::Auth::ServiceAccount;
use YAML::Any qw(Dump);

no autovivification;

use Google::RestApi::Utils qw(config_file);

use parent 'Google::RestApi::Auth';

do 'Google/RestApi/logger_init.pl';

sub new {
  my $class = shift;

  my $self = config_file(@_);
  state $check = compile_named(
    config_file        => Str, { optional => 1 },
    parent_config_file => Str, { optional => 1 },  # only used internally
    account_file       => Str,
    scope              => ArrayRef[Str],
  );
  $self = $check->(%$self);

  return bless $self, $class;
}

sub headers {
  my $self = shift;
  return $self->{headers} if $self->{headers};
  my $access_token = $self->access_token();
  $self->{headers} = [ Authorization => "Bearer $access_token" ];
  return $self->{headers};
}

sub access_token {
  my $self = shift;
  return $self->{access_token} if $self->{access_token};

  my $auth = WWW::Google::Cloud::Auth::ServiceAccount->new(
    credentials_path => $self->account_file(),
    # undocumented feature of WWW::Google::Cloud::Auth::ServiceAccount
    scope            => join(' ', @{ $self->{scope} }),
  );
  $self->{access_token} = $auth->get_token()
    or die "Service Account Auth failed";

  return $self->{access_token};
}

sub account_file {
  my $self = shift;
  return $self->{_account_file} if $self->{_account_file};

  # if account_file is a simple file name (no path) then assume it's in the
  # same directory as the config_file. if this has been constructed by
  # RestApi 'auth' hash, then that class would have stored its config
  # file as 'parent_config_file' to resolve the account file here.
  if (!-e $self->{account_file}) {
    my $config_file = $self->{config_file} || $self->{parent_config_file};
    $self->{account_file} = dirname($config_file) . "/$self->{account_file}"
      if $config_file;
  }

  die "Service account file not found or is not readable: '$self->{account_file}'"
    if !-f -r $self->{account_file};

  $self->{_account_file} = $self->{account_file};
  return $self->{_account_file};
}

1;

__END__

=head1 NAME

Google::RestApi::Auth::ServiceAccount - Service Account support for Google Rest APIs

=head1 SYNOPSIS

  use Google::RestApi::Auth::ServiceAccount;

  my $sa = Google::RestApi::Auth::ServiceAccount->new(
    account_file => <path_to_account_json_file>,
    scope        => ['http://spreadsheets.google.com/feeds/'],
  );
  # generate an access token from the code returned from Google:
  my $token = $sa->access_token($code);

=head1 AUTHOR

Test User E<lt>mvsjes@cpan.ork<gt>, copied and modifed from Net::Google::DataAPI::Auth::OAuth2.

=head1 SEE ALSO

L<OAuth2>

L<Google::DataAPI::Auth::OAuth2>

L<https://developers.google.com/accounts/docs/OAuth2> 

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
