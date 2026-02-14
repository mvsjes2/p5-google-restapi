package Google::RestApi::CalendarApi3;

our $VERSION = '1.2.0';

use Google::RestApi::Setup;

use Readonly;
use URI;

use aliased 'Google::RestApi::CalendarApi3::Calendar';
use aliased 'Google::RestApi::CalendarApi3::CalendarList';
use aliased 'Google::RestApi::CalendarApi3::Colors';
use aliased 'Google::RestApi::CalendarApi3::Settings';

Readonly our $Calendar_Endpoint => 'https://www.googleapis.com/calendar/v3';
Readonly our $Calendar_Id       => '[a-zA-Z0-9._@-]+';

sub new {
  my $class = shift;
  state $check = compile_named(
    api      => HasApi,
    endpoint => Str, { default => $Calendar_Endpoint },
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  state $check = compile_named(
    uri     => Str, { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  my $uri = "$self->{endpoint}/";
  $uri .= delete $p->{uri} if defined $p->{uri};
  return $self->{api}->api(%$p, uri => $uri);
}

sub calendar {
  my $self = shift;
  state $check = compile_named(
    id => Str,
  );
  my $p = $check->(@_);
  return Calendar->new(calendar_api => $self, %$p);
}

sub calendar_list {
  my $self = shift;
  state $check = compile_named(
    id => Str, { optional => 1 },
  );
  my $p = $check->(@_);
  return CalendarList->new(calendar_api => $self, %$p);
}

sub colors { Colors->new(calendar_api => shift); }

sub settings {
  my $self = shift;
  state $check = compile_named(
    id => Str, { optional => 1 },
  );
  my $p = $check->(@_);
  return Settings->new(calendar_api => $self, %$p);
}

sub create_calendar {
  my $self = shift;
  state $check = compile_named(
    summary => Str,
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  my %content = (
    summary => delete $p->{summary},
  );

  DEBUG("Creating calendar '$content{summary}'");
  my $result = $self->api(
    uri     => 'calendars',
    method  => 'post',
    content => \%content,
  );
  return Calendar->new(calendar_api => $self, id => $result->{id});
}

sub list_calendars {
  my $self = shift;
  state $check = compile_named(
    params => HashRef, { default => {} },
  );
  my $p = $check->(@_);

  my $params = $p->{params};
  $params->{fields} //= 'items(id, summary)';
  $params->{fields} = 'nextPageToken, ' . $params->{fields};

  my @list;
  my $next_page_token;
  do {
    $params->{pageToken} = $next_page_token if $next_page_token;
    my $result = $self->api(uri => 'users/me/calendarList', params => $params);
    push(@list, $result->{items}->@*) if $result->{items};
    $next_page_token = $result->{nextPageToken};
  } until !$next_page_token;

  return @list;
}

sub freebusy {
  my $self = shift;
  state $check = compile_named(
    time_min => Str,
    time_max => Str,
    items    => ArrayRef[HashRef],
    _extra_  => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  my %content = (
    timeMin => delete $p->{time_min},
    timeMax => delete $p->{time_max},
    items   => delete $p->{items},
  );

  return $self->api(
    uri     => 'freeBusy',
    method  => 'post',
    content => \%content,
  );
}

sub rest_api { shift->{api}; }

1;

__END__

=head1 NAME

Google::RestApi::CalendarApi3 - API to Google Calendar API V3.

=head1 SYNOPSIS

=head2 Basic Setup

 use Google::RestApi;
 use Google::RestApi::CalendarApi3;

 # Create the REST API instance
 my $rest_api = Google::RestApi->new(
   config_file => '/path/to/config.yaml',
 );

 # Create the Calendar API instance
 my $cal_api = Google::RestApi::CalendarApi3->new(api => $rest_api);

=head2 Working with Calendars

 # Create a new calendar
 my $calendar = $cal_api->create_calendar(summary => 'My New Calendar');

 # Get an existing calendar (e.g. primary)
 my $primary = $cal_api->calendar(id => 'primary');
 my $metadata = $primary->get();

 # Update calendar metadata
 $primary->update(summary => 'Updated Name', description => 'New description');

 # List all calendars for the user
 my @calendars = $cal_api->list_calendars();

=head2 Working with Events

 my $calendar = $cal_api->calendar(id => 'primary');

 # Create a timed event
 my $event = $calendar->event()->create(
   summary => 'Team Meeting',
   start   => { dateTime => '2026-03-01T10:00:00-05:00' },
   end     => { dateTime => '2026-03-01T11:00:00-05:00' },
 );

 # Quick add an event using natural language
 my $quick = $calendar->event()->quick_add(text => 'Lunch with Bob tomorrow at noon');

 # List events
 my @events = $calendar->events();

 # Get/update/delete an event
 my $details = $event->get();
 $event->update(summary => 'Updated Meeting');
 $event->delete();

=head2 Access Control (ACL)

 # List ACL rules on a calendar
 my @rules = $calendar->acl_rules();

 # Create an ACL rule
 my $acl = $calendar->acl()->create(
   role       => 'reader',
   scope_type => 'user',
   scope_value => 'user@example.com',
 );

 # Delete an ACL rule
 $acl->delete();

=head2 Calendar List, Colors, and Settings

 # Calendar list (user's view of calendars)
 my $cl = $cal_api->calendar_list(id => 'primary');
 my $info = $cl->get();

 # Get available colors
 my $colors = $cal_api->colors();
 my $all = $colors->get();

 # Get a setting
 my $setting = $cal_api->settings(id => 'timezone');
 my $value = $setting->value();

=head1 DESCRIPTION

Google::RestApi::CalendarApi3 provides a Perl interface to the Google Calendar API V3.
It enables calendar management including:

=over 4

=item * Calendar CRUD operations (create, get, update, delete)

=item * Event management (create, get, update, delete, quick add)

=item * Access control (ACL) management

=item * Calendar list management (user's view of calendars)

=item * Colors and settings (read-only)

=item * Free/busy queries

=back

It is assumed that you are familiar with the Google Calendar API:
L<https://developers.google.com/calendar/api/v3/reference>

=head2 Architecture

The API uses a hierarchical object model where child objects delegate API calls
to their parent:

 CalendarApi3 (top-level)
   |-- calendar(id => ...)       -> Calendar
   |     |-- event(id => ...)    -> Event
   |     |-- acl(id => ...)      -> Acl
   |-- calendar_list(id => ...)  -> CalendarList
   |-- colors()                  -> Colors
   |-- settings(id => ...)       -> Settings

Each object provides CRUD operations appropriate to its resource type.

=head1 NAVIGATION

=over

=item * L<Google::RestApi::CalendarApi3> - This module (top-level Calendar API)

=item * L<Google::RestApi::CalendarApi3::Calendar> - Calendar operations

=item * L<Google::RestApi::CalendarApi3::Event> - Event management

=item * L<Google::RestApi::CalendarApi3::Acl> - Access control rules

=item * L<Google::RestApi::CalendarApi3::CalendarList> - Calendar list management

=item * L<Google::RestApi::CalendarApi3::Colors> - Available colors

=item * L<Google::RestApi::CalendarApi3::Settings> - User settings

=back

=head1 SUBROUTINES

=head2 new(%args)

Creates a new CalendarApi3 instance.

 my $cal_api = Google::RestApi::CalendarApi3->new(api => $rest_api);

%args consists of:

=over

=item * C<api> L<Google::RestApi>: Required. A configured RestApi instance.

=item * C<endpoint> <string>: Optional. Override the default Calendar API endpoint.

=back

=head2 api(%args)

Low-level method to make API calls. You would not normally call this directly
unless making a Google API call not currently supported by this framework.

%args consists of:

=over

=item * C<uri> <string>: Path segments to append to the Calendar endpoint.

=item * C<%args>: Additional arguments passed to L<Google::RestApi>'s api() (content, params, method, etc).

=back

Returns the response hash from the Google API.

=head2 calendar(%args)

Returns a Calendar object for the given calendar ID.

 my $cal = $cal_api->calendar(id => 'primary');
 my $cal = $cal_api->calendar(id => 'user@gmail.com');

%args consists of:

=over

=item * C<id> <string>: Required. The calendar ID (e.g. 'primary' or an email address).

=back

=head2 calendar_list(%args)

Returns a CalendarList object for managing the user's view of calendars.

 my $cl = $cal_api->calendar_list(id => 'primary');

%args consists of:

=over

=item * C<id> <string>: Optional. The calendar ID. Required for get/update/delete.

=back

=head2 colors()

Returns a Colors object for querying available calendar and event colors.

 my $colors = $cal_api->colors();
 my $all = $colors->get();

=head2 settings(%args)

Returns a Settings object for querying user settings.

 my $setting = $cal_api->settings(id => 'timezone');
 my $value = $setting->value();

%args consists of:

=over

=item * C<id> <string>: Optional. The setting ID. Required for get/value.

=back

=head2 create_calendar(%args)

Creates a new calendar.

 my $cal = $cal_api->create_calendar(summary => 'My Calendar');

%args consists of:

=over

=item * C<summary> <string>: Required. The name for the calendar.

=back

Returns a Calendar object for the created calendar.

=head2 list_calendars(%args)

Lists all calendars visible to the user. Handles pagination automatically.

 my @calendars = $cal_api->list_calendars();

Returns a list of calendar hashrefs with id and summary.

=head2 freebusy(%args)

Queries free/busy information for a set of calendars.

 my $result = $cal_api->freebusy(
   time_min => '2026-03-01T00:00:00Z',
   time_max => '2026-03-02T00:00:00Z',
   items    => [{ id => 'primary' }],
 );

%args consists of:

=over

=item * C<time_min> <string>: Required. Start of the time range (RFC3339).

=item * C<time_max> <string>: Required. End of the time range (RFC3339).

=item * C<items> <arrayref>: Required. List of calendar IDs to query.

=back

=head1 SEE ALSO

=over

=item * L<Google::RestApi> - The underlying REST API client

=item * L<Google::RestApi::DriveApi3> - Google Drive API (related module)

=item * L<Google::RestApi::SheetsApi4> - Google Sheets API (related module)

=item * L<https://developers.google.com/calendar/api/v3/reference> - Google Calendar API Reference

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
