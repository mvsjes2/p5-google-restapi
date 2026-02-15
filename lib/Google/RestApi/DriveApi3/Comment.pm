package Google::RestApi::DriveApi3::Comment;

our $VERSION = '1.1.0';

use Google::RestApi::Setup;

use aliased 'Google::RestApi::DriveApi3::Reply';

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
  my $uri = "comments";
  $uri .= "/$self->{id}" if $self->{id};
  $uri .= "/$p{uri}" if $p{uri};
  delete $p{uri};
  return $self->file()->api(%p, uri => $uri);
}

sub create {
  my $self = shift;
  state $check = compile_named(
    content        => Str,
    anchor         => Str, { optional => 1 },
    quoted_content => Str, { optional => 1 },
    _extra_        => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  my %content = (
    content => delete $p->{content},
  );
  $content{anchor} = delete $p->{anchor} if defined $p->{anchor};
  $content{quotedFileContent}{value} = delete $p->{quoted_content} if defined $p->{quoted_content};

  DEBUG(sprintf("Creating comment on file '%s'", $self->file()->file_id()));
  my $result = $self->file()->api(
    uri     => 'comments',
    method  => 'post',
    params  => { fields => 'id, content, author, createdTime' },
    content => \%content,
  );
  return ref($self)->new(file => $self->file(), id => $result->{id});
}

sub get {
  my $self = shift;
  state $check = compile_named(
    fields          => Str, { default => 'id,content,author,createdTime,modifiedTime' },
    include_deleted => Bool, { default => 0 },
  );
  my $p = $check->(@_);

  LOGDIE "Comment ID required for get()" unless $self->{id};

  my %params = (
    fields => $p->{fields},
  );
  $params{includeDeleted} = $p->{include_deleted} ? 'true' : 'false';

  return $self->api(params => \%params);
}

sub update {
  my $self = shift;
  state $check = compile_named(
    content => Str,
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  LOGDIE "Comment ID required for update()" unless $self->{id};

  my %content = (
    content => delete $p->{content},
  );

  DEBUG(sprintf("Updating comment '%s' on file '%s'", $self->{id}, $self->file()->file_id()));
  return $self->api(
    method  => 'patch',
    content => \%content,
  );
}

sub delete {
  my $self = shift;

  LOGDIE "Comment ID required for delete()" unless $self->{id};

  DEBUG(sprintf("Deleting comment '%s' from file '%s'", $self->{id}, $self->file()->file_id()));
  return $self->api(method => 'delete');
}

sub reply {
  my $self = shift;
  state $check = compile_named(
    id => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  LOGDIE "Comment ID required for reply()" unless $self->{id};

  return Reply->new(comment => $self, %$p);
}

sub replies {
  my $self = shift;
  state $check = compile_named(
    fields          => Str, { optional => 1 },
    include_deleted => Bool, { default => 0 },
    max_pages       => Int, { default => 0 },
    page_callback   => CodeRef, { optional => 1 },
    params          => HashRef, { default => {} },
  );
  my $p = $check->(@_);

  LOGDIE "Comment ID required for replies()" unless $self->{id};

  my $params = $p->{params};
  $params->{fields} //= 'replies(id, content, author, createdTime)';
  $params->{fields} = 'nextPageToken, ' . $params->{fields};
  $params->{includeDeleted} = $p->{include_deleted} ? 'true' : 'false';

  return paginate_api(
    api_call       => sub { $params->{pageToken} = $_[0] if $_[0]; $self->api(uri => 'replies', params => $params); },
    result_key     => 'replies',
    max_pages      => $p->{max_pages},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub comment_id { shift->{id}; }
sub file { shift->{file}; }

1;

__END__

=head1 NAME

Google::RestApi::DriveApi3::Comment - Comment object for Google Drive files.

=head1 SYNOPSIS

 # List all comments
 my @comments = $file->comments();

 # Get a specific comment
 my $comment = $file->comment(id => 'comment_id');
 my $details = $comment->get();

 # Create a new comment
 my $new_comment = $file->comment()->create(
   content => 'Great work on this document!',
 );

 # Update comment
 $comment->update(content => 'Updated comment text');

 # Delete comment
 $comment->delete();

 # Work with replies
 my @replies = $comment->replies();
 my $reply = $comment->reply()->create(content => 'Thanks!');

=head1 DESCRIPTION

Represents a comment on a Google Drive file. Supports creating, reading,
updating, and deleting comments, as well as managing replies.

=head1 METHODS

=head2 create(content => $text, ...)

Creates a new comment. Required parameter: content.

Optional parameters:
- anchor: JSON string specifying anchor location
- quoted_content: The text being quoted

=head2 get(fields => $fields, include_deleted => $bool)

Gets comment details. Requires comment ID.

=head2 update(content => $text)

Updates the comment content. Requires comment ID.

=head2 delete()

Deletes the comment. Requires comment ID.

=head2 reply(id => $id)

Returns a Reply object. Without id, can create new replies.

=head2 replies(include_deleted => $bool, max_pages => $n, page_callback => $coderef)

Lists all replies to the comment. C<max_pages> limits the number of pages
fetched (default 0 = unlimited). Supports C<page_callback>,
see L<Google::RestApi/PAGE CALLBACKS>.

=head2 comment_id()

Returns the comment ID.

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
