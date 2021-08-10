package Test::Unit::UriResponse;

# this started out as a (simple) way to match a uri/content request and
# simulate the json response from google. simple in concept, complex in
# implementation.
# many contents and responses have arrays that vary in their order randomly,
# so they have to be sorted here to see if they match or to inject values
# into the proper places in the response. i'm constantly adding new features
# to make this work, a bad sign.
# there may be better ways to do this, it's escapted me thus far.

use Test::Unit::Setup;

use File::Slurp qw(read_file);
use Hash::Merge qw(merge);
use JSON::MaybeXS qw(encode_json decode_json);
use List::Util qw(pairs);
use Storable qw(freeze dclone);
use String::Interpolate qw(interpolate);
use Try::Tiny;
use URI;
use YAML::Any qw(LoadFile);

sub new {
  my $class = shift;
  my $self = validate_named(\@_,
    request     => InstanceOf['HTTP::Request'],
    responses   => HashRef,
    cell_values => HashRef,
  );
  return bless $self, $class;
}

# intercept furl's call to the network and see if the uri and content match something
# that's already been registered previously. see etc/uri_responses.
sub response {
  my $self = shift;

  my $req = $self->{request};
  my $req_method = $req->method();
  my $req_uri = $req->uri();
  my $req_content = $req->content() ?
    decode_json($req->content()) : undef;

  my ($matched_uri, @matches) = $self->find_response_by_uri($req_method, $req_uri);
  die "No response URI found for $req_method => $req_uri" if !defined $matched_uri; # can be '' for deletes.

  # can be a simple response string, or a hash of content/response to match contents.
  my $response_item = $req_content ? $self->find_response_by_content($matched_uri, $req_content) : $matched_uri;
  my $response_json = $response_item->{response};
  die "No response/content found for $req_method => $req_uri"
    if !defined $response_json; # a response of '' is valid (e.g. for DELETE).

  my $response_file = fake_response_json_file($response_json);
  $response_json = read_file($response_file) if -f $response_file;
  # do any substitutions necessary from any matches in the uri regex. didn't want to get into complex
  # templates here, just simple scalar subs.
  if ($response_json && @matches) {
    my $template = String::Interpolate->new($response_json);
    $template->(\@matches);
    $response_json = "$template";  # needs quotes to force interpolations.
  }

  my $tweaks = $response_item->{tweaks} || [];
  foreach my $tweak (@$tweaks) {
    my $method = "tweak_$tweak";
    $response_json = $self->$method($response_json, $req_uri, $req_content);
  }
  
  my $code = 200; my $message = 'ok';
  if ($response_json) {
    my $decoded = decode_json($response_json);
    $code = $decoded->{error}->{code} || $code;
    $message = $decoded->{error}->{message} || $message;
  }

  return ($response_json, $code, $message);
}

# see if the uri in the registered uris matches the one we're processing.
sub find_response_by_uri {
  my $self = shift;
  my ($method, $uri) = @_;

  # find the GET, POST etc hash of uri's.
  my $cmp_uris = $self->{responses}->{$method}
    or die "No matching method found for $method => $uri";

  # we need to either match with a generic regex, or an exact match of uri's.
  foreach my $cmp_uri (keys %$cmp_uris) {
    # if it begins with a caret ^ or a bracket ( it's a regex. other alternative is 'https'.
    if (substr($cmp_uri, 0, 1) =~ m|[\Q(^\E]|) {  # ref(\$cmp_uri) does not return Regexp!
      my $uri_string = $uri->canonical()->as_string();
      # need to eval this so we can add \Q\E to the regexes and avoid escaping all them
      # uri /.?= madness.
      my $cmp_uri_regex = eval "qr|$cmp_uri|";
      my @matches = $uri_string =~ /$cmp_uri_regex/;
      # matches are used later by string::interpolate to inject $1, $2 etc into the response.
      return ($cmp_uris->{$cmp_uri}, @matches) if @matches;
    } else {
      # 'normalizing' will sort the params so they can be proplerly compared.
      $uri = $self->normalize_uri($uri);
      my $norm_cmp_uri = $self->normalize_uri($cmp_uri);
      return ($cmp_uris->{$cmp_uri}) if $uri->eq($norm_cmp_uri);
    }
  }

  return ();
}

# now that we have the correct url, see if the content hash also has a match.
sub find_response_by_content {
  my $self = shift;
  my ($responses, $req_content) = @_;

  # there is no array of content to query in this case, we're responding with the same
  # thing no matter what is in the post content.
  return $responses if ref($responses) ne 'ARRAY';
  
  foreach my $response (@$responses) {
    my $cmp_content = $response->{content};
    return $response->{response} if !defined $req_content &&
      (!defined $cmp_content || $cmp_content eq '*');

    my $cmp_content_file = fake_response_json_file($cmp_content);
    $cmp_content = read_file($cmp_content_file) if -f $cmp_content_file;
    $cmp_content = decode_json($cmp_content);

    # this allows specific ordering of the content so we have a consistent
    # way of comparing them. this could balloon out to a lot of junk.
    my $content_match = $response->{content_match} || 'default';
    my $method = "content_match_$content_match";
    return $response if $self->$method($req_content, $cmp_content);
  }

  return;
}

# make the query params sorted so that when uri's are stringified they come out in the
# same order so we can compare them.
sub normalize_uri {
  my $self = shift;
  my $uri = URI->new(shift);
  $uri->query_form([
    map { $_->[0], $_->[1] }
    sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] }
    pairs($uri->query_form())
  ]);
  return $uri;
}

sub content_match_default {
  my $self = shift;
  my ($req_content, $cmp_content) = @_;
  # so we can quickly compare data structures (post content) with freeze.
  local $Storable::canonical = 1;
  return freeze($req_content) eq freeze($cmp_content);
}

sub content_match_batch_update {
  my $self = shift;
  my ($req_content, $cmp_content) = @_;
  
  $req_content = dclone($req_content);
  $cmp_content = dclone($cmp_content);

  my $req_data = $req_content->{data}->[0];
  $req_content->{data} = [ sort { $a->{range} cmp $b->{range} } @$req_data ];
  
  my $cmp_data = $cmp_content->{data}->[0];
  $cmp_content->{data} = [ sort { $a->{range} cmp $b->{range} } @$cmp_data ];
  
  return $self->content_match_default($req_content, $cmp_content);
}

sub tweak_batch_get_sort {
  my $self = shift;
  my ($response_json, $uri) = @_;

  my $decoded = decode_json($response_json);
  
  my $value_ranges = $decoded->{valueRanges}
    or die "No 'batch get' values found in json response";
  # save a hash of range pairs.
  my %ranges = map { $_->{range} => $_; } @$value_ranges;

  # get the order of ranges present in the original uri.
  my @sheet_ranges = $uri =~ m|ranges\=\'(\D+\d+)\'\!(\D+\d+)|g;
  # combine the sheet name and range pair into one to match the range in the valueRanges.
  @sheet_ranges = map { "$_->[0]!$_->[1]"; } pairs @sheet_ranges;
  # reorder the valueRanges based on the original order in the uri.
  my @values = map { $ranges{$_}; } @sheet_ranges;
  # and overrite the new order in the original json.
  $decoded->{valueRanges} = \@values;
  
  return encode_json($decoded);
}

sub tweak_get_values {
  my $self = shift;
  my ($response_json, $uri) = @_;

  my $decoded = decode_json($response_json);
  my ($sheet, $range) = _sheet_range($decoded->{range});
  my $value = $self->{cell_values}->{$sheet}->{$range};
  $decoded->{values} = $value if defined $value;

  return encode_json($decoded);
}

sub tweak_batch_get_values {
  my $self = shift;
  my ($response_json, $uri) = @_;

  my $decoded = decode_json($response_json);
  
  my $value_ranges = $decoded->{valueRanges}
    or die "No 'batch get' values found in json response";
  foreach my $value_range (@$value_ranges) {
    my ($sheet, $range) = _sheet_range($value_range->{range});
    my $value = $self->{cell_values}->{$sheet}->{$range};
    $value_range->{values} = $value if defined $value;
  }

  return encode_json($decoded);
}

sub tweak_batch_update_sort {
  my $self = shift;
  my ($response_json, $uri, $content) = @_;
  return $response_json;
}

sub tweak_batch_update_values {
  my $self = shift;
  my ($response_json, $uri, $content) = @_;
  foreach my $value_range (@{ $content->{data} }) {
    my ($sheet, $range) = _sheet_range($value_range->{range});
    $self->{cell_values}->{$sheet}->{$range} = $value_range->{values};
  }
  return $response_json;
}

sub _sheet_range {
  my ($sheet_range) = @_;
  $sheet_range =~ s/\'//g;
  return split('!', $sheet_range);
}

1;
