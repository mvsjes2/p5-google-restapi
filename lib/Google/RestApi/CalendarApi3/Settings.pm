package Google::RestApi::CalendarApi3::Settings;

our $VERSION = '1.2.0';

use Google::RestApi::Setup;

sub new {
  my $class = shift;
  state $check = compile_named(
    calendar_api => HasApi,
    id           => Str, { optional => 1 },
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  my %p = @_;
  my $uri = "users/me/settings";
  $uri .= "/$self->{id}" if $self->{id};
  $uri .= "/$p{uri}" if $p{uri};
  delete $p{uri};
  return $self->calendar_api()->api(%p, uri => $uri);
}

sub get {
  my $self = shift;

  LOGDIE "Settings ID required for get()" unless $self->{id};

  return $self->api();
}

sub value {
  my $self = shift;
  return $self->get()->{value};
}

sub setting_id { shift->{id}; }
sub calendar_api { shift->{calendar_api}; }

1;

__END__

=head1 NAME

Google::RestApi::CalendarApi3::Settings - Settings object for Google Calendar.

=head1 SYNOPSIS

 # Get a specific setting
 my $setting = $cal_api->settings(id => 'timezone');
 my $details = $setting->get();

 # Get just the value
 my $tz = $setting->value();

=head1 DESCRIPTION

Provides access to user calendar settings (read-only).

=head1 METHODS

=head2 get()

Gets the setting details. Requires setting ID.

=head2 value()

Returns just the setting value. Requires setting ID.

=head2 setting_id()

Returns the setting ID.

=head2 calendar_api()

Returns the parent CalendarApi3 object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
