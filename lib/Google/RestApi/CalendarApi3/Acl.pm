package Google::RestApi::CalendarApi3::Acl;

our $VERSION = '2.0.0';

use Google::RestApi::Setup;

sub new {
  my $class = shift;
  state $check = compile_named(
    calendar => HasApi,
    id       => Str, { optional => 1 },
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  my %p = @_;
  my $uri = "acl";
  $uri .= "/$self->{id}" if $self->{id};
  $uri .= "/$p{uri}" if $p{uri};
  delete $p{uri};
  return $self->calendar()->api(%p, uri => $uri);
}

sub create {
  my $self = shift;
  state $check = compile_named(
    role        => Str,
    scope_type  => Str,
    scope_value => Str, { optional => 1 },
    _extra_     => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  my %content = (
    role  => delete $p->{role},
    scope => {
      type => delete $p->{scope_type},
    },
  );
  $content{scope}{value} = delete $p->{scope_value} if defined $p->{scope_value};

  DEBUG(sprintf("Creating ACL rule on calendar '%s'", $self->calendar()->calendar_id()));
  my $result = $self->calendar()->api(
    uri     => 'acl',
    method  => 'post',
    content => \%content,
  );
  return ref($self)->new(calendar => $self->calendar(), id => $result->{id});
}

sub get {
  my $self = shift;
  state $check = compile_named(
    fields => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  LOGDIE "ACL ID required for get()" unless $self->{id};

  my %params;
  $params{fields} = $p->{fields} if defined $p->{fields};

  return $self->api(params => \%params);
}

sub update {
  my $self = shift;
  state $check = compile_named(
    role    => Str,
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  LOGDIE "ACL ID required for update()" unless $self->{id};

  my %content = (
    role => delete $p->{role},
  );

  DEBUG(sprintf("Updating ACL rule '%s' on calendar '%s'", $self->{id}, $self->calendar()->calendar_id()));
  return $self->api(
    method  => 'patch',
    content => \%content,
  );
}

sub delete {
  my $self = shift;

  LOGDIE "ACL ID required for delete()" unless $self->{id};

  DEBUG(sprintf("Deleting ACL rule '%s' from calendar '%s'", $self->{id}, $self->calendar()->calendar_id()));
  return $self->api(method => 'delete');
}

sub acl_id { shift->{id}; }
sub calendar { shift->{calendar}; }

1;

__END__

=head1 NAME

Google::RestApi::CalendarApi3::Acl - ACL (Access Control) object for Google Calendar.

=head1 SYNOPSIS

 # Get an ACL rule
 my $acl = $calendar->acl(id => 'rule_id');
 my $details = $acl->get();

 # Create a new ACL rule
 my $new_acl = $calendar->acl()->create(
   role        => 'reader',
   scope_type  => 'user',
   scope_value => 'user@example.com',
 );

 # Update ACL rule
 $acl->update(role => 'writer');

 # Delete ACL rule
 $acl->delete();

=head1 DESCRIPTION

Represents an access control rule on a Google Calendar. Supports creating,
reading, updating, and deleting ACL rules.

=head1 METHODS

=head2 create(role => $role, scope_type => $type, scope_value => $value)

Creates a new ACL rule. Required parameters:

=over

=item * role: 'none', 'freeBusyReader', 'reader', 'writer', 'owner'

=item * scope_type: 'default', 'user', 'group', 'domain'

=item * scope_value: Email address or domain (optional for 'default' type)

=back

=head2 get(fields => $fields)

Gets ACL rule details. Requires ACL ID.

=head2 update(role => $role)

Updates the ACL rule role. Requires ACL ID.

=head2 delete()

Deletes the ACL rule. Requires ACL ID.

=head2 acl_id()

Returns the ACL rule ID.

=head2 calendar()

Returns the parent Calendar object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
