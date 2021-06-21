package Google::RestApi::SheetsApi4::Range::Cell;

our $VERSION = '0.4';

use Google::RestApi::Setup;

use Carp qw(cluck);
use parent 'Google::RestApi::SheetsApi4::Range';

sub range {
  my $self = shift;
  return $self->{normalized_range} if $self->{normalized_range};
  my $range = $self->SUPER::range(@_);
  die "Unable to translate '$range' into a worksheet cell"
    if $range =~ /:/;
  return $range;
}

sub values {
  my $self = shift;
  my $p = _update_values(@_);
  my $values = $self->SUPER::values(%$p);
  return $values->[0]->[0];
}

sub batch_values {
  my $self = shift;
  my $p = _update_values(@_);
  return $self->SUPER::batch_values(%$p);
}

sub _update_values {
  state $check = compile_named(
    values  => Str, { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  $p->{values} = [[$p->{values}]] if defined $p->{values};
  return $p;
}

sub cell { shift; }

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
