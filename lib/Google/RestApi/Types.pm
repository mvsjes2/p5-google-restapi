package Google::RestApi::Types;

# custom type constrants. see Type::Library.
# NOTE: can't use Google::RestApi::Setup here because that module imports this one.

use strict;
use warnings;

our $VERSION = '0.8';

use Types::Standard qw( Undef Str StrMatch Int ArrayRef HashRef Tuple Dict HasMethods );
use Types::Common::Numeric qw( PositiveInt PositiveOrZeroInt );

my @types = qw(
  ReadableDir ReadableFile
  EmptyArrayRef EmptyHashRef
  Zero EmptyString False
  DimCol DimRow DimAny
  RangeCol RangeRow RangeCell RangeAny RangeAll
  RangeNamed RangeIndex
  HasApi HasRange
);

use Type::Library -base, -declare => @types;

use Exporter;
our %EXPORT_TAGS = (all => \@types);

my $meta = __PACKAGE__->meta;

$meta->add_type(
  name    => 'ReadableDir',
  parent  => Str->where( sub { -d -r; } ),
  message => sub { "Must point to a file system directory that's readable" },
);

$meta->add_type(
  name    => 'ReadableFile',
  parent  => Str->where( sub { -f -r; } ),
  message => sub { "Must point to a file that's readable" },
);



$meta->add_type(
  name    => 'EmptyArrayRef',
  parent  => ArrayRef->where( sub { scalar @$_ == 0; } ),
  message => sub { "Must be an empty array" },
);

$meta->add_type(
  name    => 'EmptyHashRef',
  parent  => HashRef->where( sub { scalar keys %$_ == 0; } ),
  message => sub { "Must be an empty hash" },
);



my $zero = $meta->add_type(
  name    => 'Zero',
  parent  => Int->where( sub { $_ == 0; } ),
  message => sub { "Must be an int equal to 0" },
);

my $empty_string = $meta->add_type(
  name    => 'EmptyString',
  parent  => StrMatch[qr/^$/],
  message => sub { "Must be an empty string" },
);

my $false = $meta->add_type(
  name    => 'False',
  parent  => Undef | $zero | $empty_string,
  message => sub { "Must evaluate to false" },
);




my $dim_col = $meta->add_type(
  name    => 'DimCol',
  parent  => StrMatch[qr/^(col)/i],
  message => sub { "Must be spreadsheet dimention 'col'" },
);

my $dim_row = $meta->add_type(
  name    => 'DimRow',
  parent  => StrMatch[qr/^(row)/i],
  message => sub { "Must be spreadsheet dimention 'row'" },
);

my $dim_any = $meta->add_type(
  name    => 'DimAny',
  parent  => $dim_col | $dim_row,
  message => sub { "Must be a spreadsheet dimention (col or row)" },
);

$_->coercion->add_type_coercions(
  Str, sub { lc(substr($_, 0, 3)); },
) for ($dim_col, $dim_row);




my $col_str_int = StrMatch[qr/^([A-Z]+|\d+)$/];

my $col = $meta->add_type(
  name    => 'RangeCol',
  parent  => StrMatch[qr/^([A-Z]+)\d*:\1\d*$/],
  message => sub { "Must be a spreadsheet range column Ax:Ay" },
);
$col->coercion->add_type_coercions(
  StrMatch[qr/^([A-Z]+)$/], sub { "$_:$_"; },  # 'A' => 'A:A', 1 should be a row.
  Dict[col => $col_str_int], sub { $_ = _col_i2a($_->{col}); "$_:$_"; },
  Tuple[Dict[col => $col_str_int]], sub { $_ = _col_i2a($_->[0]->{col}); "$_:$_"; },
  Tuple[$col_str_int], sub { $_ = _col_i2a($_->[0]); "$_:$_"; },
  Tuple[$col_str_int, $false], sub { $_ = _col_i2a($_->[0]); "$_:$_"; },
  Tuple[Tuple[$col_str_int]], sub { $_ = _col_i2a($_->[0]->[0]); "$_:$_"; },
  Tuple[Tuple[$col_str_int, $false]], sub { $_ = _col_i2a($_->[0]->[0]); "$_:$_"; },
);
sub _col_i2a {
  my $col = shift;
  return $col if $col =~ qr/^\D+$/;
  my $l = int($col / 27);
  my $r = $col - $l * 26;
  return $l > 0 ? (pack 'CC', $l+64, $r+64) : (pack 'C', $r+64);
}


my $row = $meta->add_type(
  name    => 'RangeRow',
  parent  => StrMatch[qr/^[A-Z]*(\d+):[A-Z]*\1$/],
  message => sub { "Must be a spreadsheet range row x1:y1" },
);
$row->coercion->add_type_coercions(
  PositiveInt, sub { "$_:$_"; },   # 1 => 1:1
  Dict[row => PositiveInt], sub { "$_->{row}:$_->{row}"; },
  Tuple[Dict[row => PositiveInt]], sub { "$_->[0]->{row}:$_->[0]->{row}"; },
  Tuple[$false, PositiveInt] => sub { "$_->[1]:$_->[1]"; },
  Tuple[Tuple[$false, PositiveInt]] => sub { "$_->[0]->[1]:$_->[0]->[1]"; },
);



my $cell_str_int = StrMatch[qr/^[A-Z]+\d+$/];

my $cell = $meta->add_type(
  name    => 'RangeCell',
  parent  => $cell_str_int,
  message => sub { "Must be a spreadsheet range cell A1" },
);
$cell->coercion->add_type_coercions(
  StrMatch[qr/^([A-Z]+\d+):\1$/], sub { (split(':'))[0]; },  # 'A1:A1' should be a cell.
  Dict[col => $col_str_int, row => PositiveInt], sub { _col_i2a($_->{col}) . $_->{row}; },
  Tuple[Dict[col => $col_str_int, row => PositiveInt]], sub { _col_i2a($_->[0]->{col}) . $_->[0]->{row}; },
  Tuple[$col_str_int, PositiveInt], sub { _col_i2a($_->[0]) . $_->[1]; },
  Tuple[Tuple[$col_str_int, PositiveInt]], sub { _col_i2a($_->[0]->[0]) . $_->[0]->[1]; },
);


my $range_any = $meta->add_type(
  name    => 'RangeAny',
  parent  => StrMatch[qr/^[A-Z]*\d*(:[A-Z]*\d*)?$/],
  message => sub { "Must be a spreadsheet range A1:B2" },
);
$range_any->coercion->add_type_coercions(
  Tuple[$cell_str_int, $cell_str_int],
    sub { "$_->[0]:$_->[1]"; },
  Tuple[Tuple[$col_str_int, PositiveInt], Tuple[$col_str_int, PositiveInt]],
    sub { _tuple_to_cell($_->[0]) . ":" . _tuple_to_cell($_->[1]); },
  Tuple[Dict[col => $col_str_int, row => PositiveInt], Dict[col => $col_str_int, row => PositiveInt]],
    sub { _dict_to_cell($_->[0]) . ":" . _dict_to_cell($_->[1]); },

  Tuple[$cell_str_int, Dict[col => $col_str_int, row => PositiveInt]],
    sub { $_->[0] . ":". _dict_to_cell($_->[1]); },
  Tuple[Dict[col => $col_str_int, row => PositiveInt], $cell_str_int],
    sub { _dict_to_cell($_->[0]) . ":" . $_->[1]; },
  Tuple[Dict[col => $col_str_int, row => PositiveInt], Tuple[$col_str_int, PositiveInt]],
    sub { _dict_to_cell($_->[0]) . ":" . _tuple_to_cell($_->[1]); },

  Tuple[$cell_str_int, Tuple[$col_str_int, PositiveInt]],
    sub { $_->[0] . ":" . _tuple_to_cell($_->[1]); },
  Tuple[Tuple[$col_str_int, PositiveInt], $cell_str_int],
    sub { _tuple_to_cell($_->[0]) . ":" . $_->[1]; },
  Tuple[Tuple[$col_str_int, PositiveInt], Dict[col => $col_str_int, row => PositiveInt]],
    sub { _tuple_to_cell($_->[0]) . ":" . _dict_to_cell($_->[1]); },
);

sub _tuple_to_cell {
  my $tuple = shift;
  return _col_i2a($tuple->[0]) . $tuple->[1];
}

sub _dict_to_cell {
  my $dict = shift;
  return _col_i2a($dict->{col}) . $dict->{row};
}

$meta->add_type(
  name    => 'RangeAll',
  parent  => $col | $row | $cell | $range_any,
  message => sub { "Must be a spreadsheet range, col, row, or cell" },
);



# https://support.google.com/docs/answer/63175?co=GENIE.Platform%3DDesktop&hl=en
$meta->add_type(
  name    => 'RangeNamed',
  parent  => StrMatch[qr/^[A-Za-z_][A-Za-z0-9_]+/],
  message => sub { "Must be a spreadsheet named range" },
);

$meta->add_type(
  name    => 'RangeIndex',
  parent  => PositiveOrZeroInt,
  message => sub { "Must be a spreadsheet range index (0-based)" },
);



$meta->add_type(
  name    => 'HasApi',
  parent  => HasMethods[qw(api)],
  message => sub { "Must be an api object"; }
);

$meta->add_type(
  name    => 'HasRange',
  parent  => HasMethods[qw(range)],
  message => sub { "Must be a range object"; }
);

__PACKAGE__->make_immutable;

1;
