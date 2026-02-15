package Google::RestApi::TasksApi1::TaskList;

our $VERSION = '2.0.0';

use Google::RestApi::Setup;

use aliased 'Google::RestApi::TasksApi1::Task';

sub new {
  my $class = shift;
  state $check = compile_named(
    tasks_api => HasApi,
    id        => Str, { optional => 1 },
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  my %p = @_;
  my $uri = "users/\@me/lists";
  $uri .= "/$self->{id}" if $self->{id};
  $uri .= "/$p{uri}" if $p{uri};
  delete $p{uri};
  return $self->tasks_api()->api(%p, uri => $uri);
}

sub get {
  my $self = shift;
  state $check = compile_named(
    fields => Str, { optional => 1 },
    params => HashRef, { default => {} },
  );
  my $p = $check->(@_);

  LOGDIE "TaskList ID required for get()" unless $self->{id};

  my $params = $p->{params};
  $params->{fields} = $p->{fields} if defined $p->{fields};

  return $self->api(params => $params);
}

sub update {
  my $self = shift;
  state $check = compile_named(
    title   => Str, { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  LOGDIE "TaskList ID required for update()" unless $self->{id};

  my %content;
  $content{title} = delete $p->{title} if defined $p->{title};

  DEBUG(sprintf("Updating task list '%s'", $self->{id}));
  return $self->api(
    method  => 'patch',
    content => \%content,
  );
}

sub delete {
  my $self = shift;

  LOGDIE "TaskList ID required for delete()" unless $self->{id};

  DEBUG(sprintf("Deleting task list '%s'", $self->{id}));
  return $self->api(method => 'delete');
}

sub task {
  my $self = shift;
  state $check = compile_named(
    id => Str, { optional => 1 },
  );
  my $p = $check->(@_);
  return Task->new(task_list => $self, %$p);
}

sub tasks {
  my $self = shift;
  state $check = compile_named(
    max_pages     => Int, { default => 1 },
    page_callback => CodeRef, { optional => 1 },
    params        => HashRef, { default => {} },
  );
  my $p = $check->(@_);

  LOGDIE "TaskList ID required for tasks()" unless $self->{id};

  my $params = $p->{params};
  $params->{fields} //= 'items(id, title, status, due)';
  $params->{fields} = 'nextPageToken, ' . $params->{fields};

  return paginate_api(
    api_call       => sub { $params->{pageToken} = $_[0] if $_[0]; $self->tasks_api()->api(uri => "lists/$self->{id}/tasks", params => $params); },
    result_key     => 'items',
    max_pages      => $p->{max_pages},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub create_task {
  my $self = shift;
  state $check = compile_named(
    title   => Str,
    notes   => Str, { optional => 1 },
    due     => Str, { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  LOGDIE "TaskList ID required for create_task()" unless $self->{id};

  my %content = (
    title => delete $p->{title},
  );
  $content{notes} = delete $p->{notes} if defined $p->{notes};
  $content{due} = delete $p->{due} if defined $p->{due};

  DEBUG(sprintf("Creating task '%s' on task list '%s'", $content{title}, $self->{id}));
  my $result = $self->tasks_api()->api(
    uri     => "lists/$self->{id}/tasks",
    method  => 'post',
    content => \%content,
  );
  return Task->new(task_list => $self, id => $result->{id});
}

sub clear {
  my $self = shift;

  LOGDIE "TaskList ID required for clear()" unless $self->{id};

  DEBUG(sprintf("Clearing completed tasks from task list '%s'", $self->{id}));
  return $self->tasks_api()->api(
    uri    => "lists/$self->{id}/clear",
    method => 'post',
  );
}

sub task_list_id { shift->{id}; }
sub tasks_api { shift->{tasks_api}; }

1;

__END__

=head1 NAME

Google::RestApi::TasksApi1::TaskList - Task list object for Google Tasks.

=head1 SYNOPSIS

 my $tl = $tasks_api->task_list(id => 'task_list_id');

 # Get task list metadata
 my $metadata = $tl->get();

 # Update task list
 $tl->update(title => 'New Name');

 # Delete task list
 $tl->delete();

 # Tasks
 my @tasks = $tl->tasks();
 my $task = $tl->task(id => 'task_id');
 $tl->create_task(
   title => 'Buy groceries',
   notes => 'Milk, eggs, bread',
   due   => '2026-03-01T00:00:00.000Z',
 );

 # Clear completed tasks
 $tl->clear();

=head1 DESCRIPTION

Represents a Google Task List with full CRUD operations and task management.

=head1 METHODS

=head2 get(fields => $fields, params => \%params)

Retrieves task list metadata. Requires task list ID.

=head2 update(title => $title)

Updates task list metadata. Requires task list ID.

=head2 delete()

Permanently deletes the task list. Requires task list ID.

=head2 task(id => $id)

Returns a Task object. Without id, can be used to create new tasks.

=head2 tasks(max_pages => $n, page_callback => $coderef)

Lists all tasks on the task list. Requires task list ID. C<max_pages> limits
the number of pages fetched (default 1). Set to 0 for unlimited.
Supports C<page_callback>, see L<Google::RestApi/PAGE CALLBACKS>.

=head2 create_task(title => $title, notes => $notes, due => $due)

Creates a new task on the task list. Requires task list ID.

=head2 clear()

Clears all completed tasks from the task list. Requires task list ID.

=head2 task_list_id()

Returns the task list ID.

=head2 tasks_api()

Returns the parent TasksApi1 object.

=head1 AUTHORS

=over

=item

Test User mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Test User. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
