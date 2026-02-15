package Google::RestApi::CalendarApi3::Calendar;

our $VERSION = '1.2.0';

use Google::RestApi::Setup;

use aliased 'Google::RestApi::CalendarApi3::Event';
use aliased 'Google::RestApi::CalendarApi3::Acl';

sub new {
  my $class = shift;
  state $check = compile_named(
    calendar_api => HasApi,
    id           => Str,
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  my %p = @_;
  my $uri = "calendars/$self->{id}";
  $uri .= "/$p{uri}" if $p{uri};
  delete $p{uri};
  return $self->calendar_api()->api(%p, uri => $uri);
}

sub get {
  my $self = shift;
  state $check = compile_named(
    fields => Str, { optional => 1 },
    params => HashRef, { default => {} },
  );
  my $p = $check->(@_);

  my $params = $p->{params};
  $params->{fields} = $p->{fields} if defined $p->{fields};

  return $self->api(params => $params);
}

sub update {
  my $self = shift;
  state $check = compile_named(
    summary     => Str, { optional => 1 },
    description => Str, { optional => 1 },
    location    => Str, { optional => 1 },
    time_zone   => Str, { optional => 1 },
    _extra_     => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  my %content;
  $content{summary} = delete $p->{summary} if defined $p->{summary};
  $content{description} = delete $p->{description} if defined $p->{description};
  $content{location} = delete $p->{location} if defined $p->{location};
  $content{timeZone} = delete $p->{time_zone} if defined $p->{time_zone};

  DEBUG(sprintf("Updating calendar '%s'", $self->{id}));
  return $self->api(
    method  => 'put',
    content => \%content,
  );
}

sub delete {
  my $self = shift;
  DEBUG(sprintf("Deleting calendar '%s'", $self->{id}));
  return $self->api(method => 'delete');
}

sub clear {
  my $self = shift;
  DEBUG(sprintf("Clearing calendar '%s'", $self->{id}));
  return $self->api(uri => 'clear', method => 'post');
}

sub event {
  my $self = shift;
  state $check = compile_named(
    id => Str, { optional => 1 },
  );
  my $p = $check->(@_);
  return Event->new(calendar => $self, %$p);
}

sub events {
  my $self = shift;
  state $check = compile_named(
    fields        => Str, { optional => 1 },
    max_pages     => Int, { default => 0 },
    page_callback => CodeRef, { optional => 1 },
    params        => HashRef, { default => {} },
  );
  my $p = $check->(@_);

  my $params = $p->{params};
  $params->{fields} //= 'items(id, summary, start, end)';
  $params->{fields} = 'nextPageToken, ' . $params->{fields};

  return paginate_api(
    api_call       => sub { $params->{pageToken} = $_[0] if $_[0]; $self->api(uri => 'events', params => $params); },
    result_key     => 'items',
    max_pages      => $p->{max_pages},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub acl {
  my $self = shift;
  state $check = compile_named(
    id => Str, { optional => 1 },
  );
  my $p = $check->(@_);
  return Acl->new(calendar => $self, %$p);
}

sub acl_rules {
  my $self = shift;
  state $check = compile_named(
    fields        => Str, { optional => 1 },
    max_pages     => Int, { default => 0 },
    page_callback => CodeRef, { optional => 1 },
    params        => HashRef, { default => {} },
  );
  my $p = $check->(@_);

  my $params = $p->{params};
  $params->{fields} //= 'items(id, role, scope)';
  $params->{fields} = 'nextPageToken, ' . $params->{fields};

  return paginate_api(
    api_call       => sub { $params->{pageToken} = $_[0] if $_[0]; $self->api(uri => 'acl', params => $params); },
    result_key     => 'items',
    max_pages      => $p->{max_pages},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub calendar_id { shift->{id}; }
sub calendar_api { shift->{calendar_api}; }

1;

__END__

=head1 NAME

Google::RestApi::CalendarApi3::Calendar - Calendar object for Google Calendar.

=head1 SYNOPSIS

 my $calendar = $cal_api->calendar(id => 'primary');

 # Get calendar metadata
 my $metadata = $calendar->get();

 # Update calendar
 $calendar->update(summary => 'New Name', description => 'New description');

 # Delete calendar
 $calendar->delete();

 # Clear all events (primary calendar only)
 $calendar->clear();

 # Events
 my @events = $calendar->events();
 my $event = $calendar->event(id => 'event_id');
 $calendar->event()->create(
   summary => 'Meeting',
   start => { dateTime => '2026-03-01T10:00:00Z' },
   end   => { dateTime => '2026-03-01T11:00:00Z' },
 );

 # ACL rules
 my @rules = $calendar->acl_rules();
 my $acl = $calendar->acl(id => 'rule_id');

=head1 DESCRIPTION

Represents a Google Calendar with full CRUD operations, event management,
and access control.

=head1 METHODS

=head2 get(fields => $fields, params => \%params)

Retrieves calendar metadata.

=head2 update(summary => $name, description => $desc, ...)

Updates calendar metadata. Supports summary, description, location,
and time_zone parameters.

=head2 delete()

Permanently deletes the calendar.

=head2 clear()

Clears all events from a calendar. Only works on the primary calendar.

=head2 event(id => $id)

Returns an Event object. Without id, can be used to create new events.

=head2 events(max_pages => $n)

Lists all events on the calendar. C<max_pages> limits the number of pages
fetched (default 0 = unlimited).

=head2 acl(id => $id)

Returns an Acl object. Without id, can be used to create new ACL rules.

=head2 acl_rules(max_pages => $n)

Lists all ACL rules on the calendar. C<max_pages> limits the number of pages
fetched (default 0 = unlimited).

=head2 calendar_id()

Returns the calendar ID.

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
