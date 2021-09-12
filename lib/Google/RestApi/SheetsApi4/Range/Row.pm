package Google::RestApi::SheetsApi4::Range::Row;

our $VERSION = '0.8';

use Google::RestApi::Setup;

use Try::Tiny qw( try catch );

use aliased 'Google::RestApi::SheetsApi4::Range';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

use parent Range;

sub new {
  my $class = shift;
  my %self = @_;

  $self{dim} = 'row';

  # this is fucked up, but want to support creating this object directly and also
  # via the range::factory method, so have to handle both cases here. so call
  # rangeany first to invoke any coersions, then coerce the result into a row.
  try {
    state $check = compile(RangeAny);
    ($self{range}) = $check->($self{range});
  } catch {};

  try {
    state $check = compile(RangeRow);
    ($self{range}) = $check->($self{range});
  } catch {
    my $err = $_;
    LOGDIE sprintf("Unable to translate '%s' into a worksheet row: %s", flatten_range($self{range}), $err);
  };

  return $class->SUPER::new(%self);
}

sub values {
  my $self = shift;
  state $check = compile_named(
    values => ArrayRef[Str], { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  $p->{values} = [ $p->{values} ] if defined $p->{values};
  my $values = $self->SUPER::values(%$p);
  return defined $values ? $values->[0] : undef;
}

sub batch_values {
  my $self = shift;
  state $check = compile_named(
    values => ArrayRef[Str], { optional => 1 },
  );
  my $p = $check->(@_);
  $p->{values} = [ $p->{values} ] if $p->{values};
  return $self->SUPER::batch_values(%$p);
}

sub cell_at_offset {
  my $self = shift;
  state $check = compile(Int, DimColRow);
  my ($offset) = $check->(@_);     # we're a row, no dim required.
  my $range = $self->range_to_array();
  $range->[0] = ($range->[0] || 1) + $offset;
  return Cell->new(worksheet => $self->worksheet(), range => $range);
}

sub range_to_index {
  my $self = shift;
  my $range = $self->SUPER::range_to_index(@_);
  delete @$range{qw(startColumnIndex endColumnIndex)};
  return $range;
}

sub freeze {
  my $self = shift;
  my $range = $self->range_to_dimension('row');
  return $self->freeze_rows($range->{endIndex});
}

sub thaw {
  my $self = shift;
  my $range = $self->range_to_dimension('row');
  return $self->freeze_rows($range->{startIndex});
}

sub heading { shift->SUPER::heading(@_)->freeze(); }
sub insert_d { shift->insert_dimension(inherit => shift); }
sub insert_dimension { shift->SUPER::insert_dimension(dimension => 'row', @_); }
sub move_dimension { shift->SUPER::move_dimension(dimension => 'row', @_); }
sub delete_dimension { shift->SUPER::delete_dimension(dimension => 'row', @_); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Range::Row - Represents a row within a Worksheet.

=head1 DESCRIPTION

A Range::Row object modifies the behaviour of the parent Range object
to treat the values used within the range as a row in the spreadsheet,
in other words, a single flat array instead of arrays of arrays. This
object will encapsulate the passed flat array value into a [$value]
array of arrays when interacting with Google API.

It also adjusts calls defined in Request::Spreadsheet::Worksheet::Range
to reflect using a row instead of a general range.

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 AUTHORS

=over

=item

Test User mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Test User. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
