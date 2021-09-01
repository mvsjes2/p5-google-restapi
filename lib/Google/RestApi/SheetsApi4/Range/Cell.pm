package Google::RestApi::SheetsApi4::Range::Cell;

our $VERSION = '0.8';

use Google::RestApi::Setup;

use Try::Tiny qw( try catch );

use aliased 'Google::RestApi::SheetsApi4::Range';

use parent Range;

# make sure the translated range refers to a single cell (no ':').
sub new {
  my $self = shift->SUPER::new(@_);

  state $check = compile(RangeCell);
  try {
    $check->($self->{range});  # not range() since we don't want the sheet name.
  } catch {
    LOGDIE "Unable to translate '$self->{range}' into a worksheet cell";
  };

  return $self;
}

sub values {
  my $self = shift;
  state $check = compile_named(
    values => Str, { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  $p->{values} = [[ $p->{values} ]] if defined $p->{values};
  my $values = $self->SUPER::values(%$p);
  return defined $values ? $values->[0]->[0] : undef;
}

sub batch_values {
  my $self = shift;

  state $check = compile_named(
    values => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  $p->{values} = [[ $p->{values} ]] if $p->{values};
  return $self->SUPER::batch_values(%$p);
}

# is this 0 or infinity? return self if offset is 0, undef otherwise.
sub cell_at_offset {
  my $self = shift;
  state $check = compile(Int, DimAny);
  my ($offset) = $check->(@_);   # we're a cell, no dim required.
  return $self if !$offset;
  return;
}

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Range::Cell - Represents a cell within a Worksheet.

=head1 DESCRIPTION

A Range::Cell object modifies the behaviour of the parent Range object
to treat the values used within the range as a plain string instead of
arrays of arrays. This object will encapsulate the passed string value
into a [[$value]] array of arrays when interacting with Goolge API.

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
