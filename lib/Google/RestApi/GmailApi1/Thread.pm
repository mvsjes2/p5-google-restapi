package Google::RestApi::GmailApi1::Thread;

our $VERSION = '1.2.0';

use Google::RestApi::Setup;

sub new {
  my $class = shift;
  state $check = compile_named(
    gmail_api => HasApi,
    id        => Str, { optional => 1 },
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  my %p = @_;
  my $uri = "threads";
  $uri .= "/$self->{id}" if $self->{id};
  $uri .= "/$p{uri}" if $p{uri};
  delete $p{uri};
  return $self->gmail_api()->api(%p, uri => $uri);
}

sub get {
  my $self = shift;
  state $check = compile_named(
    format => Str, { optional => 1 },
    fields => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  LOGDIE "Thread ID required for get()" unless $self->{id};

  my %params;
  $params{format} = $p->{format} if defined $p->{format};
  $params{fields} = $p->{fields} if defined $p->{fields};

  return $self->api(params => \%params);
}

sub modify {
  my $self = shift;
  state $check = compile_named(
    add_label_ids    => ArrayRef[Str], { default => [] },
    remove_label_ids => ArrayRef[Str], { default => [] },
  );
  my $p = $check->(@_);

  LOGDIE "Thread ID required for modify()" unless $self->{id};

  my %content;
  $content{addLabelIds} = $p->{add_label_ids} if $p->{add_label_ids}->@*;
  $content{removeLabelIds} = $p->{remove_label_ids} if $p->{remove_label_ids}->@*;

  DEBUG(sprintf("Modifying thread '%s'", $self->{id}));
  return $self->api(
    uri     => 'modify',
    method  => 'post',
    content => \%content,
  );
}

sub trash {
  my $self = shift;

  LOGDIE "Thread ID required for trash()" unless $self->{id};

  DEBUG(sprintf("Trashing thread '%s'", $self->{id}));
  return $self->api(uri => 'trash', method => 'post');
}

sub untrash {
  my $self = shift;

  LOGDIE "Thread ID required for untrash()" unless $self->{id};

  DEBUG(sprintf("Untrashing thread '%s'", $self->{id}));
  return $self->api(uri => 'untrash', method => 'post');
}

sub delete {
  my $self = shift;

  LOGDIE "Thread ID required for delete()" unless $self->{id};

  DEBUG(sprintf("Deleting thread '%s'", $self->{id}));
  return $self->api(method => 'delete');
}

sub thread_id { shift->{id}; }
sub gmail_api { shift->{gmail_api}; }

1;

__END__

=head1 NAME

Google::RestApi::GmailApi1::Thread - Thread object for Gmail.

=head1 SYNOPSIS

 # Get a thread
 my $thread = $gmail_api->thread(id => 'thread_id');
 my $details = $thread->get();

 # Modify thread labels
 $thread->modify(
   add_label_ids    => ['STARRED'],
   remove_label_ids => ['UNREAD'],
 );

 # Trash/untrash
 $thread->trash();
 $thread->untrash();

 # Permanently delete
 $thread->delete();

=head1 DESCRIPTION

Represents a Gmail thread. Supports reading, modifying labels, trashing,
and deleting threads.

=head1 METHODS

=head2 get(format => $format, fields => $fields)

Gets thread details including all messages. Requires thread ID.

Format can be 'full', 'metadata', or 'minimal'.

=head2 modify(add_label_ids => \@ids, remove_label_ids => \@ids)

Modifies the labels on all messages in the thread. Requires thread ID.

=head2 trash()

Moves the thread to trash. Requires thread ID.

=head2 untrash()

Removes the thread from trash. Requires thread ID.

=head2 delete()

Permanently deletes the thread. Requires thread ID.

=head2 thread_id()

Returns the thread ID.

=head2 gmail_api()

Returns the parent GmailApi1 object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
