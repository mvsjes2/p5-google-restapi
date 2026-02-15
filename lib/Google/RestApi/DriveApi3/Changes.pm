package Google::RestApi::DriveApi3::Changes;

our $VERSION = '1.1.0';

use Google::RestApi::Setup;

sub new {
  my $class = shift;
  state $check = compile_named(
    drive_api => HasApi,
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  my %p = @_;
  my $uri = "changes";
  $uri .= "/$p{uri}" if $p{uri};
  delete $p{uri};
  return $self->drive_api()->api(%p, uri => $uri);
}

sub get_start_page_token {
  my $self = shift;
  state $check = compile_named(
    drive_id            => Str, { optional => 1 },
    supports_all_drives => Bool, { default => 1 },
  );
  my $p = $check->(@_);

  my %params;
  $params{driveId} = $p->{drive_id} if defined $p->{drive_id};
  $params{supportsAllDrives} = $p->{supports_all_drives} ? 'true' : 'false';

  my $result = $self->api(uri => 'startPageToken', params => \%params);
  return $result->{startPageToken};
}

sub list {
  my $self = shift;
  state $check = compile_named(
    page_token                    => Str,
    spaces                        => Str, { default => 'drive' },
    include_removed               => Bool, { default => 1 },
    include_items_from_all_drives => Bool, { default => 1 },
    supports_all_drives           => Bool, { default => 1 },
    fields                        => Str, { optional => 1 },
    page_size                     => PositiveInt, { default => 100 },
    drive_id                      => Str, { optional => 1 },
    max_pages                     => Int, { default => 0 },
    page_callback                 => CodeRef, { optional => 1 },
    _extra_                       => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  my $max_pages = delete $p->{max_pages};
  my $page_callback = delete $p->{page_callback};
  my %params = (
    pageToken   => delete $p->{page_token},
    spaces      => delete $p->{spaces},
    pageSize    => delete $p->{page_size},
    includeRemoved          => delete $p->{include_removed} ? 'true' : 'false',
    includeItemsFromAllDrives => delete $p->{include_items_from_all_drives} ? 'true' : 'false',
    supportsAllDrives       => delete $p->{supports_all_drives} ? 'true' : 'false',
  );
  $params{fields} = delete $p->{fields} if defined $p->{fields};
  $params{driveId} = delete $p->{drive_id} if defined $p->{drive_id};

  my @changes;
  my $next_page_token;
  my $new_start_page_token;
  my $page = 0;
  my $keep_going = 1;

  do {
    $params{pageToken} = $next_page_token if $next_page_token;
    my $result = $self->api(params => \%params);
    push(@changes, $result->{changes}->@*) if $result->{changes};
    $next_page_token = $result->{nextPageToken};
    $new_start_page_token = $result->{newStartPageToken};
    $page++;
    if ($page_callback && $result->{changes}) {
      $keep_going = $page_callback->($result);
    }
  } until !$keep_going || !$next_page_token || ($max_pages > 0 && $page >= $max_pages);

  return wantarray ? @changes : { changes => \@changes, newStartPageToken => $new_start_page_token };
}

sub watch {
  my $self = shift;
  state $check = compile_named(
    page_token => Str,
    id         => Str,
    type       => Str, { default => 'web_hook' },
    address    => Str,
    expiration => Int, { optional => 1 },
    _extra_    => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  my %params = (
    pageToken => delete $p->{page_token},
  );

  my $content = {
    id      => delete $p->{id},
    type    => delete $p->{type},
    address => delete $p->{address},
  };
  $content->{expiration} = delete $p->{expiration} if defined $p->{expiration};

  DEBUG("Setting watch on changes");
  return $self->api(
    uri     => 'watch',
    method  => 'post',
    params  => \%params,
    content => $content,
  );
}

sub drive_api { shift->{drive_api}; }

1;

__END__

=head1 NAME

Google::RestApi::DriveApi3::Changes - Track changes in Google Drive.

=head1 SYNOPSIS

 my $changes = $drive->changes();

 # Get starting token
 my $token = $changes->get_start_page_token();

 # List changes since token
 my @changes = $changes->list(page_token => $token);

 # Or get changes with new token
 my $result = $changes->list(page_token => $token);
 my @change_list = @{$result->{changes}};
 my $new_token = $result->{newStartPageToken};

 # Watch for changes
 $changes->watch(
   page_token => $token,
   id         => 'channel-id',
   address    => 'https://example.com/webhook',
 );

=head1 DESCRIPTION

Tracks changes to files in Google Drive. Useful for synchronization
and change notification.

=head1 METHODS

=head2 get_start_page_token(drive_id => $id)

Gets the starting page token for listing future changes.

=head2 list(page_token => $token, ...)

Lists changes since the given page token.

Options:
- page_token: Required starting token
- spaces: 'drive' or 'appDataFolder' (default: 'drive')
- include_removed: Include removed items (default: true)
- include_items_from_all_drives: Include shared drive items (default: true)
- supports_all_drives: Support shared drives (default: true)
- page_size: Number of changes per page (default: 100)
- drive_id: Specific shared drive ID
- max_pages: Maximum pages to fetch (default: 0 = unlimited)

In list context, returns array of changes.
In scalar context, returns hashref with changes and newStartPageToken.

=head2 watch(page_token => $token, id => $id, address => $url)

Sets up a notification channel for changes.

Parameters:
- page_token: Starting token
- id: Channel ID for the webhook
- type: Channel type (default: 'web_hook')
- address: Webhook URL
- expiration: Optional expiration time in milliseconds

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
