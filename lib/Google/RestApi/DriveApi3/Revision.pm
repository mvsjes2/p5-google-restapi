package Google::RestApi::DriveApi3::Revision;

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
  my $uri = "revisions";
  $uri .= "/$self->{id}" if $self->{id} && !$p{uri};
  $uri .= "/$p{uri}" if $p{uri};
  delete $p{uri};
  return $self->file()->api(%p, uri => $uri);
}

sub get {
  my $self = shift;
  state $check = compile_named(
    fields            => Str, { optional => 1 },
    acknowledge_abuse => Bool, { default => 0 },
  );
  my $p = $check->(@_);

  LOGDIE "Revision ID required for get()" unless $self->{id};

  my %params;
  $params{fields} = $p->{fields} if defined $p->{fields};
  $params{acknowledgeAbuse} = 'true' if $p->{acknowledge_abuse};

  return $self->api(params => \%params);
}

sub update {
  my $self = shift;
  state $check = compile_named(
    keep_forever              => Bool, { optional => 1 },
    publish_auto              => Bool, { optional => 1 },
    published                 => Bool, { optional => 1 },
    published_outside_domain  => Bool, { optional => 1 },
    _extra_                   => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  LOGDIE "Revision ID required for update()" unless $self->{id};

  my %content;
  $content{keepForever} = $p->{keep_forever} ? \1 : \0 if defined $p->{keep_forever};
  $content{publishAuto} = $p->{publish_auto} ? \1 : \0 if defined $p->{publish_auto};
  $content{published} = $p->{published} ? \1 : \0 if defined $p->{published};
  $content{publishedOutsideDomain} = $p->{published_outside_domain} ? \1 : \0
    if defined $p->{published_outside_domain};

  DEBUG(sprintf("Updating revision '%s' on file '%s'", $self->{id}, $self->file()->file_id()));
  return $self->api(
    method  => 'patch',
    content => \%content,
  );
}

sub delete {
  my $self = shift;

  LOGDIE "Revision ID required for delete()" unless $self->{id};

  DEBUG(sprintf("Deleting revision '%s' from file '%s'", $self->{id}, $self->file()->file_id()));
  return $self->api(method => 'delete');
}

sub revision_id { shift->{id}; }
sub file { shift->{file}; }

1;

__END__

=head1 NAME

Google::RestApi::DriveApi3::Revision - Revision object for Google Drive files.

=head1 SYNOPSIS

 # List all revisions
 my @revisions = $file->revisions();

 # Get a specific revision
 my $rev = $file->revision(id => 'revision_id');
 my $details = $rev->get();

 # Update revision settings
 $rev->update(keep_forever => 1);

 # Delete a revision
 $rev->delete();

=head1 DESCRIPTION

Represents a revision of a Google Drive file. Supports reading, updating,
and deleting revisions.

=head1 METHODS

=head2 get(fields => $fields, acknowledge_abuse => $bool)

Gets revision details. Requires revision ID.

=head2 update(keep_forever => $bool, ...)

Updates revision settings. Requires revision ID.

Options:
- keep_forever: Whether to keep this revision forever
- publish_auto: Whether future revisions auto-publish
- published: Whether this revision is published
- published_outside_domain: Whether published outside domain

=head2 delete()

Deletes the revision. Requires revision ID.

=head2 revision_id()

Returns the revision ID.

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
