package Google::RestApi::DriveApi3::Permission;

our $VERSION = '1.1.0';

use Google::RestApi::Setup;

sub new {
  my $class = shift;
  state $check = compile_named(
    file => HasApi,
    id   => Str, { optional => 1 },
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  my %p = @_;
  my $uri = "permissions";
  $uri .= "/$self->{id}" if $self->{id};
  $uri .= "/$p{uri}" if $p{uri};
  delete $p{uri};
  return $self->file()->api(%p, uri => $uri);
}

sub create {
  my $self = shift;
  state $check = compile_named(
    role              => Str,
    type              => Str,
    email_address     => Str, { optional => 1 },
    domain            => Str, { optional => 1 },
    send_notification => Bool, { default => 0 },
    email_message     => Str, { optional => 1 },
    transfer_ownership => Bool, { default => 0 },
    _extra_           => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  my %params;
  $params{sendNotificationEmail} = delete $p->{send_notification} ? 'true' : 'false';
  $params{emailMessage} = delete $p->{email_message} if defined $p->{email_message};
  $params{transferOwnership} = delete $p->{transfer_ownership} ? 'true' : 'false';

  my %content = (
    role => delete $p->{role},
    type => delete $p->{type},
  );
  $content{emailAddress} = delete $p->{email_address} if defined $p->{email_address};
  $content{domain} = delete $p->{domain} if defined $p->{domain};

  DEBUG(sprintf("Creating permission on file '%s'", $self->file()->file_id()));
  my $result = $self->file()->api(
    uri     => 'permissions',
    method  => 'post',
    params  => \%params,
    content => \%content,
  );
  return ref($self)->new(file => $self->file(), id => $result->{id});
}

sub get {
  my $self = shift;
  state $check = compile_named(
    fields => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  LOGDIE "Permission ID required for get()" unless $self->{id};

  my %params;
  $params{fields} = $p->{fields} if defined $p->{fields};

  return $self->api(params => \%params);
}

sub update {
  my $self = shift;
  state $check = compile_named(
    role               => Str,
    transfer_ownership => Bool, { default => 0 },
    _extra_            => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  LOGDIE "Permission ID required for update()" unless $self->{id};

  my %params;
  $params{transferOwnership} = delete $p->{transfer_ownership} ? 'true' : 'false';

  my %content = (
    role => delete $p->{role},
  );

  DEBUG(sprintf("Updating permission '%s' on file '%s'", $self->{id}, $self->file()->file_id()));
  return $self->api(
    method  => 'patch',
    params  => \%params,
    content => \%content,
  );
}

sub delete {
  my $self = shift;

  LOGDIE "Permission ID required for delete()" unless $self->{id};

  DEBUG(sprintf("Deleting permission '%s' from file '%s'", $self->{id}, $self->file()->file_id()));
  return $self->api(method => 'delete');
}

sub permission_id { shift->{id}; }
sub file { shift->{file}; }

1;

__END__

=head1 NAME

Google::RestApi::DriveApi3::Permission - Permission object for Google Drive files.

=head1 SYNOPSIS

 # Get a permission object
 my $perm = $file->permission(id => 'permission_id');

 # Get permission details
 my $details = $perm->get();

 # Create a new permission
 my $new_perm = $file->permission()->create(
   role  => 'reader',
   type  => 'user',
   email_address => 'user@example.com',
 );

 # Make file publicly readable
 $file->permission()->create(
   role => 'reader',
   type => 'anyone',
 );

 # Update permission
 $perm->update(role => 'writer');

 # Delete permission
 $perm->delete();

=head1 DESCRIPTION

Represents a permission on a Google Drive file. Supports creating, reading,
updating, and deleting permissions.

=head1 METHODS

=head2 create(role => $role, type => $type, ...)

Creates a new permission. Required parameters:
- role: 'owner', 'organizer', 'fileOrganizer', 'writer', 'commenter', 'reader'
- type: 'user', 'group', 'domain', 'anyone'

Optional parameters:
- email_address: For 'user' or 'group' type
- domain: For 'domain' type
- send_notification: Send email notification (default: false)
- email_message: Custom message for notification
- transfer_ownership: Transfer ownership (default: false)

=head2 get(fields => $fields)

Gets permission details. Requires permission ID.

=head2 update(role => $role)

Updates the permission role. Requires permission ID.

=head2 delete()

Deletes the permission. Requires permission ID.

=head2 permission_id()

Returns the permission ID.

=head2 file()

Returns the parent File object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
