package Google::RestApi::DriveApi3::Drive;

our $VERSION = '1.1.0';

use Google::RestApi::Setup;

use parent 'Google::RestApi::SubResource';

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      drive_api => HasApi,
      id        => Str, { optional => 1 },
    ],
  );
  return bless $check->(@_), $class;
}

sub _uri_base { 'drives' }
sub _parent_accessor { 'drive_api' }

sub get {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields                  => Str, { optional => 1 },
      use_domain_admin_access => Bool, { default => 0 },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('get');

  my %params;
  $params{fields} = $p->{fields} if defined $p->{fields};
  $params{useDomainAdminAccess} = 'true' if $p->{use_domain_admin_access};

  return $self->api(params => \%params);
}

sub update {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      name                    => Str, { optional => 1 },
      color_rgb               => Str, { optional => 1 },
      theme_id                => Str, { optional => 1 },
      background_image_file   => HashRef, { optional => 1 },
      restrictions            => HashRef, { optional => 1 },
      use_domain_admin_access => Bool, { default => 0 },
      _extra_                 => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  $self->require_id('update');

  my %params;
  $params{useDomainAdminAccess} = 'true' if delete $p->{use_domain_admin_access};

  my %content;
  $content{name} = delete $p->{name} if defined $p->{name};
  $content{colorRgb} = delete $p->{color_rgb} if defined $p->{color_rgb};
  $content{themeId} = delete $p->{theme_id} if defined $p->{theme_id};
  $content{backgroundImageFile} = delete $p->{background_image_file}
    if defined $p->{background_image_file};
  $content{restrictions} = delete $p->{restrictions} if defined $p->{restrictions};

  DEBUG(sprintf("Updating shared drive '%s'", $self->{id}));
  return $self->api(
    method  => 'patch',
    params  => \%params,
    content => \%content,
  );
}

sub delete {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      use_domain_admin_access => Bool, { default => 0 },
      allow_item_deletion     => Bool, { default => 0 },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('delete');

  my %params;
  $params{useDomainAdminAccess} = 'true' if $p->{use_domain_admin_access};
  $params{allowItemDeletion} = 'true' if $p->{allow_item_deletion};

  DEBUG(sprintf("Deleting shared drive '%s'", $self->{id}));
  return $self->api(method => 'delete', params => \%params);
}

sub hide {
  my $self = shift;

  $self->require_id('hide');

  DEBUG(sprintf("Hiding shared drive '%s'", $self->{id}));
  return $self->api(uri => 'hide', method => 'post');
}

sub unhide {
  my $self = shift;

  $self->require_id('unhide');

  DEBUG(sprintf("Unhiding shared drive '%s'", $self->{id}));
  return $self->api(uri => 'unhide', method => 'post');
}

sub drive_id { shift->{id}; }
sub drive_api { shift->{drive_api}; }

1;

__END__

=head1 NAME

Google::RestApi::DriveApi3::Drive - Shared Drive object for Google Drive.

=head1 SYNOPSIS

 # List shared drives
 my @drives = $drive_api->list_drives();

 # Create a new shared drive
 my $sd = $drive_api->create_drive(
   name       => 'Team Drive',
   request_id => 'unique-request-id',
 );

 # Get a shared drive
 my $sd = $drive_api->shared_drive(id => 'drive_id');
 my $info = $sd->get();

 # Update shared drive
 $sd->update(
   name         => 'New Name',
   restrictions => { adminManagedRestrictions => \1 },
 );

 # Hide/unhide from default view
 $sd->hide();
 $sd->unhide();

 # Delete shared drive
 $sd->delete();

=head1 DESCRIPTION

Represents a Google Shared Drive (formerly Team Drive). Supports
getting, updating, deleting, and hiding shared drives.

=head1 METHODS

=head2 get(fields => $fields, use_domain_admin_access => $bool)

Gets shared drive metadata. Requires drive ID.

=head2 update(name => $name, ...)

Updates shared drive settings. Requires drive ID.

Options:
- name: New name for the drive
- color_rgb: Color as hex RGB (e.g., '#FF0000')
- theme_id: Theme ID
- background_image_file: Background image settings
- restrictions: Access restrictions hashref
- use_domain_admin_access: Use admin access

=head2 delete(use_domain_admin_access => $bool, allow_item_deletion => $bool)

Deletes the shared drive. Requires drive ID.

=head2 hide()

Hides the shared drive from the default view. Requires drive ID.

=head2 unhide()

Restores the shared drive to the default view. Requires drive ID.

=head2 drive_id()

Returns the shared drive ID.

=head2 drive_api()

Returns the parent DriveApi3 object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
