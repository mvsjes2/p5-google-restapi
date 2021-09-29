package Google::RestApi::SheetsApi4::Range;

# some private subroutines here are called by RangeGroup, so think of RangeGroup as
# a friend of Range. the routines RangeGroup calls are commented thusly:
# "private range routine called here!"

# there are different ways to specify ranges. this came about by merging different
# ideas from different spreadsheet implementations.

# column:
# A             ====> A:A
# A:A           ====> A:A
# [A]           ====> A:A
# [[A]]         ====> A:A
# [1]           ====> A:A
# [[1]]         ====> A:A
# {col => A}    ====> A:A
# [{col => A}]  ====> A:A
# {col => 1}    ====> A:A
# [{col => 1}]  ====> A:A
# a partial column is still considered a column
# A5:A10        ====> A5:A10

# row:
# 1             ====> 1:1
# 1:1           ====> 1:1
# [undef, 1]    ====> 1:1
# [[undef, 1]]  ====> 1:1
# 0's are 'valid' in that they are ignored.
# [0, 1]        ====> 1:1
# [[0, 1]]      ====> 1:1
# {row => 1}    ====> 1:1
# [{row => 1}]  ====> 1:1
# a partial row is still considered a row
# D1:1          ====> D1:1

# partial rows/columns:
# [[A, 5], [A]]                       ====> A5:A
# [{col => A, row => 5}, {col => A}]  ====> A5:A
# [[A], [A, 5]]                       ====> A:A5
# [{col => A}, {col => A, row => 5}]  ====> A:A5
# [[5, 1], [undef, 1]]                ====> E1:1
# [[5, 1], [0, 1]]                    ====> E1:1
# [{col => 5, row => 1}, {row => 1}]  ====> E1:1

# single cell:
# A1                      ====> A1
# [A, 1]                  ====> A1
# [[A, 1]]                ====> A1
# [1, 1]                  ====> A1
# [[1, 1]]                ====> A1
# {col => A, row => 1}    ====> A1
# [{col => A, row => 1}]  ====> A1
# {col => 1, row => 1}    ====> A1
# [{col => 1, row => 1}]  ====> A1

# same cell twice gets reduced to single cell:
# A1:A1                   ====> A1
# these only get reduced using the factory method.
# [[A, 1], [A, 1]]        ====> A1
# [[1, 1], [1, 1]]        ====> A1
# [{col => A, row => 1}, {col => A, row => 1}]  ====> A1
# [{col => 1, row => 1}, {col => 1, row => 1}]  ====> A1

# general ranges:
# A1:B2                                         ====> A1:B2
# [[1,1],[2,2]]                                 ====> A1:B2
# [[A,1],[B,2]]                                 ====> A1:B2
# [{col => 1, row => 1}, {col => 2, row => 2}]  ====> A1:B2
# [{col => A, row => 1}, {col => B, row => 2}]  ====> A1:B2

# mixing is ok:
# [A1, [2, 2]]                    ====> A1:B2
# [{col => 1, row => 1}, [2, 2]]  ====> A1:B2
# [{col => 1. row => 1}, B2]      ====> A1:B2

# bad ranges:
# should be able to support this but makes range routine
# too complex, and the simple workaround is to just A1:B2.
# [A1, B2]

our $VERSION = '0.8';

use Google::RestApi::Setup;

use Carp qw( confess );
use List::Util qw( max );
use Scalar::Util qw( looks_like_number );
use Try::Tiny qw( try catch );

use experimental qw( switch );

use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';
use aliased 'Google::RestApi::SheetsApi4::Range::Iterator';

use parent 'Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range';

# this routine returns the best fitting object for the range specified.
# A5:A10 will return a Col object. A5:J5 will return a Row object. Etc.
sub factory {
  my %original_range_args = @_;
  my $original_range = $original_range_args{range};

  state $check = multisig(
    compile_named(
      worksheet => HasApi,
      range     => RangeCol,
      dim       => DimColRow, { optional => 1 },  # is switched to 'col'.
    ),
    compile_named(
      worksheet => HasApi,
      range     => RangeRow,
      dim       => DimColRow, { optional => 1 },  # is switched to 'row'
    ),
    compile_named(
      worksheet => HasApi,
      range     => RangeCell,
      dim       => DimColRow, { optional => 1 },  # doesn't matter for cells.
    ),
    compile_named(
      worksheet => HasApi,
      range     => RangeAny,
      dim       => DimColRow, { default => 'row' },
    ),
    compile_named(
      worksheet => HasApi,
      range     => RangeNamed,
      dim       => DimColRow, { default => 'row' },
    ),
  );
  my @range_args = $check->(@_);
  my $range_args = $range_args[0];  # no idea why it returns an arrayref pointer to a hashref.
  my $range = $range_args->{range};
  
  # be careful here, recursive.
  given (${^TYPE_PARAMS_MULTISIG}) {
    when (0) { return Col->new(%$range_args); }
    when (1) { return Row->new(%$range_args); }
    when (2) { return Cell->new(%$range_args); }

    # if we've translated a range, it now may be a better fit for one of the above.
    when (3) {
      # convert the range to A1:A1 format and redrive the factory routine to see
      # if it ends up being a col, row, or cell range.
      if ($range ne $original_range) {
        DEBUG(sprintf("Range '%s' converted to '$range'", flatten_range($original_range)));
        # resolve cells by collapsing A1:A1 to just A1. also A:A and 1:1 will be
        # properly resolved to cols/rows.
        my ($start, $end) = split(':', $range);
        $range = $start if $end && $start eq $end;
        return factory(%$range_args);                       ##### recursion
      }
      # we're already in A1:A1 format so just create a new range object.
      return __PACKAGE__->new(%$range_args);
    }

    # range could be a named range or a column/row header. we have to resolve the
    # range first, then see what the best fit will be above.
    when (4) {
      my $worksheet = $range_args->{worksheet};

      my $named = $range;
      $range = $worksheet->resolve_header_range($named);
      if ($range) {
        $range = factory(%$range_args, range => $range);    ##### recursion
        $range->{header_name} = $named;
        return $range;
      }
      
      $range = $worksheet->normalize_named($named)
        or LOGDIE("Unable to resolve named range '$named'");
      # we've resolved the name to A1 format, so redrive factory routine to
      # generate a range object with the resolved range.
      $range = factory(%$range_args, range => $range);      ##### recursion
      $range->{named} = $named;
      return $range;
    }
  }

  LOGDIE("Unable to resolve '$range_args->{range}' to a range object");
}

sub new {
  my $class = shift;

  # TODO: sort start range and end range before storing.

  state $check = compile_named(
    worksheet => HasMethods[qw(api worksheet_name)],
    range     => RangeAny,
    dim       => DimColRow, { default => 'row' },
  );
  my $self = $check->(@_);
  $self->{dim} = dims_any($self->{dim});   # convert internally to COLUMN | ROW

  return bless $self, $class;
}

sub clear {
  my $self = shift;
  my $range = $self->range();
  DEBUG("Clearing range '$range'");
  my %p = (
    uri    => "/values/$range:clear",
    method => 'post',
  );
  my $response = $self->api(%p);
  $self->clear_cached_values();
  return $response;
}

sub clear_cached_values { delete shift->{cache_range_values}; }

sub refresh_values {
  my $self = shift;
  $self->clear_cached_values();
  return $self->values();
}

# this gets or sets the values of a range immediately, no batch.
# if no values passed, gets them. if values passed, sets them.
sub values {
  my $self = shift;
  my %p = @_;
  $self->_send_values(%p) if defined $p{values};
  return $self->_cache_range_values(%p)->{values};
}

# immediately update the values for a range (no batch).
sub _send_values {
  my $self = shift;

  state $check = compile_named(
    values  => ArrayRef[ArrayRef[Str]], { optional => 1 }, # ArrayRef->plus_coercions(Str, sub { [ $_ ] } ),
    params  => HashRef, { default => {} },
    content => HashRef, { default => {} },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  
  my $range = $self->range();

  # since we're sending these values, fake a response from the
  # api to store them in our cache.
  # if includeValuesInResponse is sent in the params, then the
  # response will replace the cache again.
  $self->_cache_range_values(
    range          => $range,
    majorDimension => $self->dimension(),
    values         => $p->{values},
  );

  $p->{content}->{range} = $range;
  $p->{content}->{values} = delete $p->{values};
  $p->{content}->{majorDimension} = $self->dimension();
  $p->{params}->{valueInputOption} //= 'USER_ENTERED';
  # $p->{params}->{includeValuesInResponse} = 1;
  $p->{uri} = "/values/$range";
  $p->{method} = 'put';

  my $update = $self->api(%$p);

  # this fakes out the batch response with this immediate response.
  # batch response would be in an arrayref, so wrap it thusly.
  return $self->values_response_from_api([ $update ]);
}

# this stores the response to an update request, either batch or immediate:
# ---
# spreadsheetId: 1ky2czjhPArP71a6woeo_dxRr8gBOZZxGAPjOCXJvCwA
# updatedCells: 6
# updatedColumns: 3
# updatedRange: Sheet1!B3:D4
# updatedRows: 2
# if includeValuesInResponse was requested, the values are stashed
# from the updatedData response key.
# spreadsheet object will call this on a batch update response.
sub values_response_from_api {
  my $self = shift;

  state $check = compile(ArrayRef, { optional => 1 });
  my ($updates) = $check->(@_);
  return if !$updates;

  # shift off the next update from the batch api response. if this is
  # getting called from the spreadsheet object, it means we have an
  # update response to process.
  my $update = shift @$updates;

  # updatedData is included if includeValuesInResponse query param was sent.
  # updatedData:
  #   majorDimension: ROWS
  #   range: Sheet1!A1
  #   values:
  #   - - Fred
  # if the data is included, then replace any cached values with this latest
  # updated set of values.
  $self->_cache_range_values(%{ delete $update->{updatedData} })
    if $update->{updatedData};
  $self->{values_response_from_api} = $update;

  return $self->values();
}

# this returns the values and major dimension for a given range. it will store
# the values returned from an api fetch. it will store the values from a staged
# 'batch_values' call for later update from the api. it will store the values
# from an update if includeValuesInResponse was included.
# cache is in the format:
# majorDimension: ROWS
# values:
# - - Fred
# if a range is included it's a flag that the dim and values are present from
# the returned api call.
sub _cache_range_values {
  my $self = shift;

  my %p = @_;
  # if a range is included, assume this cache is coming from the api as a reply.
  # this is to store the values for this range when includeValuesInResponse is
  # added to the url or content on the original values call. you can replace the
  # original values using the valueRenderOption to replace, say, formulas with their
  # calculated value.
  if ($p{range}) {
    state $check = compile_named(
      majorDimension => DimColRow,
      range          => StrMatch[qr/.+!/],
      values         => ArrayRef, { optional => 1 }  # will not exist if values aren't set in the ss.
    );
    my $p = $check->(@_);

    # remove all quotes for comparison.
    my $self_range = $self->range();
    $self_range =~ s/'//g;
    my $range = $p->{range};
    $range =~ s/'//g;
    my ($worksheet_name) = $range =~ /^(.+)!/;

    LOGDIE "Setting range data to worksheet name '$worksheet_name' that doesn't belong to this range: " . $self->worksheet_name()
      if $worksheet_name ne $self->worksheet_name();
    #LOGDIE "Setting range data to '$range' which is not this range: " . $self_range
    #  if $range ne $self_range;
    LOGDIE "Setting major dimention to '$p->{majorDimension}' that doesn't belong to this range: " . $self->dimention()
      if $p->{majorDimension} ne $self->dimension();

    delete $p->{range};  # we only cache the values and dimensions.
    $self->{cache_range_values} = $p;
  }

  # if the value range was just stored (above) or was previously stored, return it.
  return $self->{cache_range_values} if $self->{cache_range_values};

  # used by iterators to use a 'parent' range to query the values for this 'child'
  # range. this is to reduce network calls when iterating through a range.
  my $shared = $self->{shared};
  if ($shared && $shared->has_values()) {
    my $dim = $shared->{cache_range_values}->{majorDimension};
    my $values = $shared->{cache_range_values}->{values};

    my ($top, $left, $bottom, $right) = $self->offsets($shared);
    my $data;
    if ($dim =~ /^col/i) {
      my @cols = @$values[$left..$right];
      $_ = [ @$_[$top..$bottom] ] foreach (@cols);
      $data = \@cols;
    } else {
      my @rows = @$values[$top..$bottom];
      $_ = [ @$_[$left..$right] ] foreach (@rows);
      $data = \@rows;
    }

    # return a subsection of the cached value for the iterator.
    return {
      majorDimension => $dim,
      values         => $data,
    };
  }

  # no values are found for this range, go get them from the api immediately.
  $p{uri} = sprintf("/values/%s", $self->range());
  $p{params}->{majorDimension} = $self->dimension();
  $self->{cache_range_values} = $self->api(%p);

  $self->{cache_range_values}->{values} //= [];  # in case there's nothing set in the ss.

  return $self->{cache_range_values};
}

# for a given range, calculate the offsets from this range. used to share values
# between ranges when iterating over a range, to reduce network calls (see above).
sub offsets {
  my $self = shift;

  state $check = compile(HasRange);
  my ($other_range) = $check->(@_);

  my $range = $self->range_to_hash();
  $range = [ $range, $range ] if ref($range) eq 'HASH'; # promote a cell.
  $other_range = $other_range->range_to_hash();
  $other_range = [ $other_range, $other_range ] if ref($other_range) eq 'HASH';

  my $top = $range->[0]->{row} - $other_range->[0]->{row};
  my $left = $range->[0]->{col} - $other_range->[0]->{col};
  my $bottom = $range->[1]->{row} - $other_range->[0]->{row};
  my $right = $range->[1]->{col} - $other_range->[0]->{col};

  return ( $top, $left, $bottom, $right );
}

sub share_values {
  my $self = shift;

  state $check = compile(HasRange);
  my ($shared_range) = $check->(@_);
  return if !$self->is_inside($shared_range);

  $self->{shared} = $shared_range;
  return $shared_range;
}

sub is_inside {
  my $self = shift;

  state $check = compile(HasRange);
  my ($other_range) = $check->(@_);

  my $range = $self->range_to_hash();
  $range = [ $range, $range ] if ref($range) eq 'HASH';
  $other_range = $other_range->range_to_hash();
  $other_range = [ $other_range, $other_range ] if ref($other_range) eq 'HASH';

  return 1 if 
    $range->[0]->{col} >= $other_range->[0]->{col} &&
    $range->[0]->{row} >= $other_range->[0]->{row} &&
    $range->[1]->{col} <= $other_range->[1]->{col} &&
    $range->[1]->{row} <= $other_range->[1]->{row}
  ;
  return;
}

# stage batch values get/set for later use by submit_values
sub batch_values {
  my $self = shift;

  state $check = compile_named(
    values => ArrayRef, { optional => 1 },
  );
  my $p = $check->(@_);

  if (defined $p->{values}) {
    # since we're sending these values, fake a response from the
    # api to store them in our cache.
    # if includeValuesInResponse is sent in the params, then the
    # response will replace the cache again.
    $self->_cache_range_values(
        range          => $self->range(),
        majorDimension => $self->dimension(),
        values         => $p->{values},
    );
  }

  return if !$self->{cache_range_values};

  return {
    range => $self->range(),
    %{ $self->{cache_range_values} },
  };
}

# tell the api to submit the batch values. the api will call back
# values_response_from_api with the results of the update.
sub submit_values {
  my $self = shift;
  $self->spreadsheet()->submit_values(ranges => [ $self ], @_);
  return $self->values();
}

sub submit_requests {
  my $self = shift;
  return $self->spreadsheet()->submit_requests(ranges => [ $self ], @_);
}

sub append {
  my $self = shift;

  state $check = compile_named(
    values  => ArrayRef->plus_coercions(Str, sub { [ $_ ] } ),
    params  => HashRef, { default => {} },
    content => HashRef, { default => {} },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  my $range = $self->range();
  $p->{content}->{range} = $range;
  $p->{content}->{values} = delete $p->{values};
  $p->{content}->{majorDimension} = $self->dimension();
  $p->{params}->{valueInputOption} //= 'USER_ENTERED';
  $p->{uri} = "/values/$range:append";
  $p->{method} = 'post';

  return $self->api(%$p);
}

sub range {
  my $self = shift;
  TRACE("Range external caller: " . $self->_caller_external()); 
  TRACE("Range internal caller: " . $self->_caller_internal()); 
  my $name = $self->worksheet_name();
  return "'$name'!$self->{range}";
}

# some staic calls...

sub _caller_internal {
  my ($package, $subroutine, $line, $i) = ('', '', 0);
  do {
    ($package, undef, $line, $subroutine) = caller(++$i);
  } while($subroutine =~ m|range$|);
  # not usually going to happen, but during testing we call
  # range directly, so have to backtrack.
  ($package, undef, $line, $subroutine) = caller(--$i)
    if !$package;
  return "$package:$line => $subroutine";
}

sub _caller_external {
  my ($package, $subroutine, $line, $i) = ('', '', 0);
  do {
    ($package, undef, $line, $subroutine) = caller(++$i);
  } while($package && $package =~ m[^(Google::RestApi)]);
  return "$package:$line => $subroutine";
}

# taken from https://metacpan.org/source/DOUGW/Spreadsheet-ParseExcel-0.65/lib/Spreadsheet/ParseExcel/Utility.pm
sub _col_a2i {
  state $check = compile(StrMatch[qr/^[A-Z]+$/]);
  my ($a) = $check->(@_);

  my $result = 0;
  my $incr = 0;
  for (my $i = length($a); $i > 0 ; $i--) {
    my $char = substr($a, $i - 1);
    my $curr += ord(lc($char)) - ord('a') + 1;
    $curr *= $incr if ($incr);
    $result += $curr;
    $incr += 26;
  }

  return $result;
}

sub cell_to_array {
  my $cell = shift;

  my ($col, $row) = $cell =~ /^([A-Z]*)(\d*)$/;
  $col = _col_a2i($col) if $col;

  $col ||= 0;
  $row ||= 0;

  return [$col, $row];
}

# back to object calls...

# returns [[col, row], [col, row]] for a full range.
# returns [col, row] for a col/row/cell.
sub range_to_array {
  my $self = shift;

  my $range = $self->range();
  ($range) = $range =~ /!(.+)/;
  $range or LOGDIE "Unable to convert range to array: ", $self->range();

  my ($start_cell, $end_cell) = split(':', $range);
  $end_cell = undef if defined $end_cell && $start_cell eq $end_cell;
  $start_cell = cell_to_array($start_cell);
  $end_cell = cell_to_array($end_cell) if $end_cell;

  return $end_cell ? [$start_cell, $end_cell] : $start_cell;
}

# returns [{col =>, row =>}, {col =>, row => }] for a full range.
# returns {col =>, row =>} for a cell.
# Cell class overrides this but is here in case a general Range class is used
# to represent a cell.
sub range_to_hash {
  my $self = shift;

  my $range = $self->range_to_array();
  $range = [ $range ] if !ref($range->[1]);
  my @ranges = map { { col => $_->[0], row => $_->[1] } } @$range;

  return $ranges[1] ? \@ranges : $ranges[0];
}

sub range_to_index {
  my $self = shift;

  my $array = $self->range_to_array();
  $array = [$array, $array] if !ref($array->[1]);

  my %range = (
    sheetId          => $self->worksheet()->worksheet_id(),
    startColumnIndex => max($array->[0]->[0] - 1, 0),
    startRowIndex    => max($array->[0]->[1] - 1, 0),
    endColumnIndex   => $array->[1]->[0],
    endRowIndex      => $array->[1]->[1],
  );
  
  return \%range;
}

sub range_to_dimension {
  my $self = shift;

  state $check = compile(DimColRow);
  my ($dims) = $check->(@_);
  $dims = dims_any($dims);

  my $array = $self->range_to_array();
  $array = [$array, $array] if !ref($array->[1]);
  my $start = $dims =~ /^col/i ? $array->[0]->[0] : $array->[0]->[1];
  my $end = $dims =~ /^col/i ? $array->[1]->[0] : $array->[1]->[1];

  my %range = (
    sheetId    => $self->worksheet()->worksheet_id(),
    startIndex => max($start - 1, 0),
    endIndex   => $end,
    dimension  => $dims,
  );

  return \%range;
}

sub cell_at_offset {
  my $self = shift;

  state $check = compile(Int, DimColRow);
  my ($offset, $dim) = $check->(@_);

  my $range = $self->range_to_hash();
  if (ref($range) eq 'HASH') {  # is just a col, row, or cell.
    # it's a row, so offset the col.
    return $self->worksheet()->range_cell({ col => $offset+1, row => $range->{row} }) if !$range->{col};
    # it's a col, so offset the row.
    return $self->worksheet()->range_cell({ col => $range->{col}, row => $offset+1 }) if !$range->{row};
    # it's a cell, so return it on offset 0, undef on anything else.
    return $offset ? undef : $self->worksheet()->range_cell($range);
  }

  # it's an a1:b2 range.
  my $other_dim = $dim =~ /col/i ? 'row' : 'col';
  # TODO: this is really brain dead, figure this out with a bit of arithmetic...
  my @ranges = map {
    my $outside = $_;
    map {
      my $inside = $_;
      my $r = { $dim => $inside, $other_dim => $outside }; $r; # for some reason have to stage the ref to a scalar.
    } ($range->[0]->{$other_dim} .. $range->[1]->{$other_dim});
  } ($range->[0]->{$dim} .. $range->[1]->{$dim});

  my $offset_range = $ranges[$offset] or return;
  my $new_cell = $self->worksheet()->range_cell($offset_range);
  $new_cell->share_values($self);
  return $new_cell;
}

# doesn't seem to be used anywhere internally.
sub range_at_offset {
  my $self = shift;

  state $check = compile_named(
    col    => Int, { default => 0 },
    row    => Int, { default => 0 },
    top    => Int, { default => 0 },
    left   => Int, { default => 0 },
    bottom => Int, { default => 0 },
    right  => Int, { default => 0 },
  );
  my $p = $check->(@_);

  my $range = $self->range_to_hash();
  if (ref($range) eq 'ARRAY') {
    foreach my $dim (@$range) {
      $dim->{$_} += $p->{$_} foreach (qw(col row));
    }
    $range->[0]->{row} += $p->{top};
    $range->[0]->{col} += $p->{left};
    $range->[1]->{row} += $p->{bottom};
    $range->[1]->{col} += $p->{right};
  } else {
    $range->{$_} += $p->{$_} foreach (qw(col row));
    $range->{row} += $p->{top};
    $range->{col} += $p->{left};
    $range->{row} += $p->{bottom};
    $range->{col} += $p->{right};
  }

  return (ref($self))->new(worksheet => $self->worksheet(), range => $range);
}

sub header_name { shift->{header_name}; }
sub named { shift->{named}; }
sub api { shift->worksheet()->api(@_); }
sub dimension { shift->{dim}; }
sub has_values { shift->{cache_range_values}; }
sub worksheet { shift->{worksheet}; }
sub worksheet_name { shift->worksheet()->worksheet_name(@_); }
sub worksheet_id { shift->worksheet()->worksheet_id(@_); }
sub spreadsheet { shift->worksheet()->spreadsheet(@_); }
sub spreadsheet_id { shift->spreadsheet()->spreadsheet_id(@_); }
sub transaction { shift->spreadsheet()->transaction(); }
sub iterator { Iterator->new(range => shift, @_); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Range - Represents a range in a Worksheet.

=head1 DESCRIPTION

A Range object that represents a range in a remote spreadsheet. These are
normally short-lived objects used to set up and execute a remote action.
Keep in mind that the remote spreadsheet can be concurrently updated by
many people, so a compromise must always be reached between holding a copy
of the local cell values and the number of network calls to the Google
API to keep the values current.

A range can be specified in whatever way is most convenient. For cells:

 * A1 notation: A1
 * Hash: { col => (A|1), row => 1 }
 * Array: [ (A|1), 1 ]

For ranges:

 * A1 notation: A1:B2
 * Hash: [ { col => (A|1), row => 1 }, { col => (B|2), row => 2 } ]
 * Array: [ [ (A|1), 1 ], [ (B|2), 2 ] ]

For columns:

 * A1 notation: A or A:A
 * Hash: { col => (A|1) }
 * Array: [ A|1 ]

For rows:

 * A1 notation: 1 or 1:1
 * Hash: { row => 1 }
 * Array: [ <false>, 1 ]

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 SUBROUTINES

=over

=item new(worksheet => <Worksheet>, range => <Range>, dim => (col|row));

Creates a new range object for the given worksheet.

 worksheet: The parent Worksheet object for this range.
 range: The range for this object, either A1 notation, hash {col => x, row => x} or array [col, row].
 dim: The major dimension for this range, either 'col' or 'row', defaults to 'row'.

You would not normally call this directly, you'd use Worksheet::range*
methods to create the range object for you.

=item api(%args);

Calls the parent worksheet's 'api' routine with the range added into
the URI or content appropriately.

You would not normally call this directly unless you were
making a Google API call not currently supported by this API
framework.

=item clear();

Clears the values using Google API's 'A1:clear' call.

=item refresh_values();

Immediately refreshes the values from the spreadsheet.

=item values(values => <arrayref>, %args);

Immediately gets or sets the values using Google API's 'get' or 'update'.

 values: The array ref of cells to update.

'args' are passed to the SheetsApi4's 'api' routine so you may add
extra arguments to the 'params' or 'content' as necessary.

=item batch_values(values => <arrayref>);

Gets or sets the queued batch values that will be sent to Google API
at a later time. Call 'submit_values' to send them later.

 values: The array ref of cells to update.

=item submit_values(%args);

Sends the previously queued batch values to Google API, if any.

'args' are passed to the SheetsApi4's 'api' routine so you may add
extra arguments to the 'params' or 'content' as necessary.

=item submit_requests(%args);

Sends the previously queued requests (formatting, sheet properties etc)
to Google API, if any.

'args' are passed to the SheetsApi4's 'api' routine so you may add
extra arguments to the 'params' or 'content' as necessary.

=item normalize_named();

If this is a 'named range', get the named range property from the
spreadsheet and set this object's real range that the named range
represents.

=item named();

Returns the 'named range' for this range, if any.

=item range();

Returns the A1 notation for this range.

=item range_to_hash();

Returns the hash representation for this range (e.g. {col => 1, row => 1}).

=item range_to_array();

Returns the array representation for this range (e.g. [1, 1]).

=item range_to_index();

Returns the index hash representation for this range, used for formatting
requests etc. You would not normally need to call this yourself.

=item range_to_dimension();

Returns the dimension hash representation for this range, used for
insert requests etc. You would not normally need to call this yourself.

=item offset(col => <int>, row => <int>, top => <int>, left => <int>, bottom => <int>, right => <int>);

Returns a new range object offset from this range.

 col: Optional offset of the new range by this many columns.
 row: Optional offset of the new range by this many rows.
 top: Optional offset of the new range with the new top.
 left: Optional offset of the new range with the new left.
 bottom: Optional offset of the new range with the new bottom.
 right: Optional offset of the new range with the new right.

=item offsets(range<Range>);

Returns the offsets of this range from the given range in an
array (top, left, bottom, right).

=item iterator(%args);

Returns an iterator for this range. Any 'args' are passed to the
'new' routine for the iterator.

=item is_inside(range<Range>);

Returns a true value if the given range fits entirely inside this
range.

=item share_values(range<Range>);

Share the cell values between this range and the passed range.

Normally ranges are short-lived, throw-away objects used to interact
with the Google API. Range objects work independently and don't
share any common storage of cells. No attempt is made to share a
common, local grid that mirrors what's in the remote spreadsheet.
The spreadsheet is a shared resource that can be updated concurrently
by multiple users, so attempting to mirror it locally is a waste of
time unless some kind of listener is provided that can be used to
syncronize the remote updates with the local copy (which Google doesn't).

However, for some cases, like iterators, we can set up ranges to
share values between them for a short time in order to reduce the
number of network calls to the Google API while you iterate over
the cells. When the iterated cell values are updated, the parent
range's value is also updated.

So far, this is the only use-case I can see for sharing the cell
grid between ranges.

=item dimension();

Returns this range's major dimension.

=item has_values();

Returns a true value if this range's values have been set either via
'values' or 'batch_values' routines.

=item worksheet();

Returns the parent Worksheet object.

=item worksheet_name();

Returns the parent Worksheet name.

=item worksheet_id();

Returns the parent Worksheet ID.

=item spreadsheet();

Returns the parent Spreadsheet object.

=item spreadsheet_id();

Returns the parent Spreadsheet ID.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
