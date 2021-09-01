package Test::Google::RestApi::Types;

use strict;
use warnings;

use File::Basename qw( dirname );
use Test::More;
use Test::Utils qw( :all );

use Google::RestApi::Types qw(:all);

no autovivification;

use parent 'Test::Class';

# cheat and steal the flatten routine from Range object.
use Google::RestApi::SheetsApi4::Range;
my $flatten = \&Google::RestApi::SheetsApi4::Range::_flatten_range;

sub class { 'Google::RestApi::Types'; }

sub readable_fs : Tests(6) {
  my $self = shift;
  is_valid $0, ReadableFile, "File is readable";
  is_not_valid "xxxx", ReadableFile, "File does not exist";
  is_not_valid dirname($0), ReadableFile, "File is a dir";
  is_valid dirname($0), ReadableDir, "Dir is readable";
  is_not_valid $0, ReadableDir, "Dir is a file and";
  is_not_valid "xxxx", ReadableDir, "Dir does not exist";
  return;
}

sub range_col : Tests(43) {
  my $self = shift;

  $self->_test_range_col('A', 'A:A');
  $self->_test_range_col('A:A', 'A:A');

  $self->_test_range_col(['A'], 'A:A');
  $self->_test_range_col([['A']], 'A:A');
  $self->_test_range_col([1], 'A:A');
  $self->_test_range_col([[1]], 'A:A');
  
  $self->_test_range_col({col => 'A'}, 'A:A');
  $self->_test_range_col([{col => 'A'}], 'A:A');
  $self->_test_range_col({col => 1}, 'A:A');
  $self->_test_range_col([{col => 1}], 'A:A');

  $self->_test_range_col(['A', undef], 'A:A');
  $self->_test_range_col([['A', undef]], 'A:A');
  $self->_test_range_col(['A', 0], 'A:A');
  $self->_test_range_col([['A', 0]], 'A:A');
  $self->_test_range_col(['A', ''], 'A:A');
  $self->_test_range_col([['A', '']], 'A:A');
  
  $self->_test_range_col('A5:A10', 'A5:A10');

  $self->_test_range_col('AA', 'AA:AA');
  $self->_test_range_col([27], 'AA:AA');  
  $self->_test_range_col({col => 27}, 'AA:AA');  

  is_not_valid {col => 'A', row => 1}, RangeCol, "Column '{col => 'A', row => 1}'";
  is_not_valid {row => 1}, RangeCol, "Column '{row => 1}'";
  is_not_valid ['A', 1], RangeCol, "Column '['A', 1]'";

  return;
}

sub _test_range_col {
  my $self = shift;
  my ($col, $is) = @_;
  my $flat = $flatten->($col);
  my ($valid) = is_valid $col, RangeCol, "Column '$flat'";
  is $valid, $is, "Column is '$is'";
  return;
}

sub range_row : Tests(27) {
  my $self = shift;

  $self->_test_range_row(1, '1:1');
  $self->_test_range_row('1:1', '1:1');

  $self->_test_range_row({row => 1}, '1:1');
  $self->_test_range_row([{row => 1}], '1:1');

  $self->_test_range_row([undef, 1], '1:1');
  $self->_test_range_row([[undef, 1]], '1:1');
  $self->_test_range_row([0, 1], '1:1');
  $self->_test_range_row([[0, 1]], '1:1');
  $self->_test_range_row(['', 1], '1:1');
  $self->_test_range_row([['', 1]], '1:1');
  
  $self->_test_range_row('A1:E1', 'A1:E1');

  $self->_test_range_row(11, '11:11');

  is_not_valid {col => 1, row => 1}, RangeRow, "Row '{col => 1, row => 1}'";
  is_not_valid [1, 1], RangeRow, "Row '[1, 1]'";
  is_not_valid ['A', 1], RangeRow, "Row '['A', 1]'";

  return;
}

sub _test_range_row {
  my $self = shift;
  my ($row, $is) = @_;
  my $flat = $flatten->($row);
  my ($valid) = is_valid $row, RangeRow, "Row '$flat'";
  is $valid, $is, "Row is '$is'";
  return;
}

sub range_cell : Tests(30) {
  my $self = shift;

  $self->_test_range_cell('A1', 'A1');

  $self->_test_range_cell(['A', '1'], 'A1');
  $self->_test_range_cell([['A', '1']], 'A1');
  $self->_test_range_cell(['1', '1'], 'A1');
  $self->_test_range_cell([['1', '1']], 'A1');

  $self->_test_range_cell({col => 'A', row => 1}, 'A1');
  $self->_test_range_cell([{col => 'A', row => 1}], 'A1');
  $self->_test_range_cell({col => '1', row => 1}, 'A1');
  $self->_test_range_cell([{col => '1', row => 1}], 'A1');
  
  $self->_test_range_cell('A1:A1', 'A1');
  
  $self->_test_range_cell('AB12', 'AB12');
  $self->_test_range_cell('AB12:AB12', 'AB12');
  $self->_test_range_cell(['AB', '12'], 'AB12');
  $self->_test_range_cell({col => 'AB', row => 12}, 'AB12');

  is_not_valid {row => 1}, RangeCell, "Cell '{row => 1}'";
  is_not_valid [1], RangeCell, "Cell '[1]'";

  return;
}

sub _test_range_cell {
  my $self = shift;
  my ($cell, $is) = @_;
  my $flat = $flatten->($cell);
  my ($valid) = is_valid $cell, RangeCell, "Cell '$flat'";
  is $valid, $is, "Cell is '$is'";
  return;
}


sub range_any : Tests() {
  my $self = shift;

  $self->_test_range_any('A', 1, 'B', 2, 'A1:B2');
  $self->_test_range_any(1, 1, 2, 2, 'A1:B2');

  return;
}

sub _test_range_any {
  my $self = shift;
  my ($col1, $row1, $col2, $row2, $is) = @_;

  my $valid;
  if ($col1 =~ qr/^\D$/ && $col2 =~ qr/^\D$/) {   # can only handle this if col is not numeric.
    ($valid) = is_valid ["$col1$row1", "$col2$row2"], RangeAny, "Range '[$col1$row1, $col2$row2]'";
    is $valid, $is, "Range is '$is'";
  }

  ($valid) = is_valid [[$col1, $row1], [$col2, $row2]], RangeAny, "Range '[[$col1, $row1], [$col2, $row2]]'";
  is $valid, $is, "Range is '$is'";

  ($valid) = is_valid [{col => $col1, row => $row1}, {col => $col2, row => $row2}], RangeAny, "Range '[{col => $col1, row => $row1}, {col => $col2, row => $row2}]'";
  is $valid, $is, "Range is '$is'";

  
  if ($col1 =~ qr/^\D$/ && $col2 =~ qr/^\D$/) {   # can only handle this if col is not numeric.
    ($valid) = is_valid ["$col1$row1", {col => $col2, row => $row2}], RangeAny, "Range '[$col1$row1, {col => $col2, row => $row2}]'";
    is $valid, $is, "Range is '$is'";

    ($valid) = is_valid [{col => $col1, row => $row1}, "$col2$row2"], RangeAny, "Range '[{col => $col1, row => $row1}, $col2$row2]'";
    is $valid, $is, "Range is '$is'";
  }


  ($valid) = is_valid [{col => $col1, row => $row1}, [$col2, $row2]], RangeAny, "Range '[{col => $col1, row => $row1}, [$col2, $row2]]'";
  is $valid, $is, "Range is '$is'";
  
  
  if ($col1 =~ qr/^\D$/ && $col2 =~ qr/^\D$/) {   # can only handle this if col is not numeric.
    ($valid) = is_valid ["$col1$row1", [$col2, $row2]], RangeAny, "Range '[$col1$row1, [$col2, $row2]]'";
    is $valid, $is, "Range is '$is'";

    ($valid) = is_valid [[$col1, $row1], "$col2$row2"], RangeAny, "Range '[[$col1, $row1], $col2$row2]'";
    is $valid, $is, "Range is '$is'";
  }

  ($valid) = is_valid [[$col1, $row1], {col => $col2, row => $row2}], RangeAny, "Range '[[$col1, $row1], {col => $col2, row => $row2}]'";
  is $valid, $is, "Range is '$is'";
  
  return;
}

1;
