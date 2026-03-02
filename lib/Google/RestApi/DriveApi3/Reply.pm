package Google::RestApi::DriveApi3::Reply;

our $VERSION = '1.1.0';

use Google::RestApi::Setup;

use parent 'Google::RestApi::SubResource';

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      comment => HasApi,
      id      => Str, { optional => 1 },
    ],
  );
  return bless $check->(@_), $class;
}

sub _uri_base { 'replies' }
sub _parent_accessor { 'comment' }

sub create {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      content => Str,
      action  => Str, { optional => 1 },
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  my %content = (
    content => delete $p->{content},
  );
  $content{action} = delete $p->{action} if defined $p->{action};

  DEBUG(sprintf("Creating reply on comment '%s'", $self->comment()->comment_id()));
  my $result = $self->comment()->api(
    uri     => 'replies',
    method  => 'post',
    params  => { fields => 'id, content, author, createdTime' },
    content => \%content,
  );
  return ref($self)->new(comment => $self->comment(), id => $result->{id});
}

sub get {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields          => Str, { default => 'id,content,author,createdTime,modifiedTime' },
      include_deleted => Bool, { default => 0 },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('get');

  my %params = (
    fields => $p->{fields},
  );
  $params{includeDeleted} = $p->{include_deleted} ? 'true' : 'false';

  return $self->api(params => \%params);
}

sub update {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      content => Str,
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  $self->require_id('update');

  my %content = (
    content => delete $p->{content},
  );

  DEBUG(sprintf("Updating reply '%s'", $self->{id}));
  return $self->api(
    method  => 'patch',
    content => \%content,
  );
}

sub delete {
  my $self = shift;

  $self->require_id('delete');

  DEBUG(sprintf("Deleting reply '%s'", $self->{id}));
  return $self->api(method => 'delete');
}

sub reply_id { shift->{id}; }
sub comment { shift->{comment}; }
sub file { shift->comment()->file(); }

1;

__END__

=head1 NAME

Google::RestApi::DriveApi3::Reply - Reply object for Google Drive comments.

=head1 SYNOPSIS

 # List all replies to a comment
 my @replies = $comment->replies();

 # Get a specific reply
 my $reply = $comment->reply(id => 'reply_id');
 my $details = $reply->get();

 # Create a new reply
 my $new_reply = $comment->reply()->create(
   content => 'Thanks for the feedback!',
 );

 # Create a reply that resolves the comment
 $comment->reply()->create(
   content => 'Fixed!',
   action  => 'resolve',
 );

 # Update reply
 $reply->update(content => 'Updated reply text');

 # Delete reply
 $reply->delete();

=head1 DESCRIPTION

Represents a reply to a comment on a Google Drive file. Supports creating,
reading, updating, and deleting replies.

=head1 METHODS

=head2 create(content => $text, action => $action)

Creates a new reply.

Parameters:
- content: The reply text (required)
- action: Optional action - 'resolve' or 'reopen'

=head2 get(fields => $fields, include_deleted => $bool)

Gets reply details. Requires reply ID.

=head2 update(content => $text)

Updates the reply content. Requires reply ID.

=head2 delete()

Deletes the reply. Requires reply ID.

=head2 reply_id()

Returns the reply ID.

=head2 comment()

Returns the parent Comment object.

=head2 file()

Returns the File object (via comment).

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
