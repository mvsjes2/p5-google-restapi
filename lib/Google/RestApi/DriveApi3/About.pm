package Google::RestApi::DriveApi3::About;

our $VERSION = '1.1.0';

use Google::RestApi::Setup;

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      drive_api => HasApi,
    ],
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  return $self->drive_api()->api(uri => 'about', @_);
}

sub get {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields => Str, { default => '*' },
    ],
  );
  my $p = $check->(@_);

  return $self->api(params => { fields => $p->{fields} });
}

sub user {
  my $self = shift;
  return $self->get(fields => 'user')->{user};
}

sub storage_quota {
  my $self = shift;
  return $self->get(fields => 'storageQuota')->{storageQuota};
}

sub export_formats {
  my $self = shift;
  return $self->get(fields => 'exportFormats')->{exportFormats};
}

sub import_formats {
  my $self = shift;
  return $self->get(fields => 'importFormats')->{importFormats};
}

sub max_upload_size {
  my $self = shift;
  return $self->get(fields => 'maxUploadSize')->{maxUploadSize};
}

sub app_installed {
  my $self = shift;
  return $self->get(fields => 'appInstalled')->{appInstalled};
}

sub drive_api { shift->{drive_api}; }

1;

__END__

=head1 NAME

Google::RestApi::DriveApi3::About - About information for Google Drive.

=head1 SYNOPSIS

 my $about = $drive->about();

 # Get all about info
 my $info = $about->get();

 # Get specific information
 my $user = $about->user();
 my $quota = $about->storage_quota();
 my $exports = $about->export_formats();
 my $imports = $about->import_formats();
 my $max_size = $about->max_upload_size();

=head1 DESCRIPTION

Provides access to user and storage information for Google Drive.

=head1 METHODS

=head2 get(fields => $fields)

Gets about information. Default returns all fields.

=head2 user()

Returns user information (displayName, emailAddress, etc).

=head2 storage_quota()

Returns storage quota information (limit, usage, usageInDrive, etc).

=head2 export_formats()

Returns supported export formats for Google Docs types.

=head2 import_formats()

Returns supported import formats.

=head2 max_upload_size()

Returns the maximum file upload size in bytes.

=head2 app_installed()

Returns whether the app is installed for the user.

=head2 drive_api()

Returns the parent DriveApi3 object.

=head1 AUTHORS

=over

=item

Test User mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Test User. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
