package Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range;

use strict;
use warnings;

our $VERSION = '0.3';

use 5.010_000;

use autodie;
use Scalar::Util qw(looks_like_number);
use Type::Params qw(compile_named);
use Types::Standard qw(Str StrMatch Bool ArrayRef HashRef HasMethods);
use YAML::Any qw(Dump);

no autovivification;

use aliased "Google::RestApi::SheetsApi4::Range";

use Google::RestApi::Utils qw(bool dim dims dims_all);

use parent "Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet";

do 'Google/RestApi/logger_init.pl';

sub range { die "Pure virtual function 'range' must be overridden"; }

sub _user_entered_format { { cell => { userEnteredFormat => shift }, fields => 'userEnteredFormat.' . shift }; }

sub horizontal_alignment { _user_entered_format({ horizontalAlignment => shift }, 'horizontalAlignment'); }
sub left { shift->_repeat_cell(horizontal_alignment('LEFT')); }
sub center { shift->_repeat_cell(horizontal_alignment('CENTER')); }
sub right { shift->_repeat_cell(horizontal_alignment('RIGHT')); }

sub vertical_alignment { _user_entered_format({ verticalAlignment => shift }, 'verticalAlignment'); }
sub top { shift->_repeat_cell(vertical_alignment('TOP')); }
sub middle { shift->_repeat_cell(vertical_alignment('MIDDLE')); }
sub bottom { shift->_repeat_cell(vertical_alignment('BOTTOM')); }

sub _text_format { _user_entered_format({ textFormat => shift }, 'textFormat.' . shift); }
sub font_family { shift->_repeat_cell(_text_format({ fontFamily => shift }, 'fontFamily')); }
sub font_size { shift->_repeat_cell(_text_format({ fontSize => shift }, 'fontSize')); }
sub bold { shift->_repeat_cell(_text_format({ bold => bool(shift) }, 'bold')); }
sub italic { shift->_repeat_cell(_text_format({ italic => bool(shift) }, 'italic')); }
sub strikethrough { shift->_repeat_cell(_text_format({ strikethrough => bool(shift) }, 'strikethrough')); }
sub underline { shift->_repeat_cell(_text_format({ underline => bool(shift) }, 'underline')); }

sub red { shift->_red_blue_green_alpha('red' => shift); }
sub blue { shift->_red_blue_green_alpha('blue' => shift); }
sub green { shift->_red_blue_green_alpha('green' => shift); }
sub alpha { shift->_red_blue_green_alpha('alpha' => shift); }
sub _red_blue_green_alpha { shift->color({ (shift) => (shift // 1) }); }
sub black { shift->color({ red => 0, blue => 0, green => 0 }); }
sub white { shift->color({ red => 1, blue => 1, green => 1 }); }
sub color { shift->_repeat_cell(_text_format({ foregroundColor => shift }, 'foregroundColor')); }

sub _bk_color { _user_entered_format({ backgroundColor => shift }, 'backgroundColor'); }
sub _bk_red_blue_green { shift->bk_color({ (shift) => (shift // 1) }); }
sub bk_red { shift->_bk_red_blue_green('red' => shift); }
sub bk_blue { shift->_bk_red_blue_green('blue' => shift); }
sub bk_green { shift->_bk_red_blue_green('green' => shift); }
sub bk_black { shift->bk_color({ red => 0, blue => 0, green => 0 }); }
sub bk_white { shift->bk_color({ red => 1, blue => 1, green => 1 }); }
sub bk_color { shift->_repeat_cell(_bk_color(shift)); }

# just dereferences the hash so it doesn't have to be done over and over above.
sub _repeat_cell { my $self = shift; my $h = shift; $self->repeat_cell(%$h); }

sub repeat_cell {
  my $self = shift;

  state $check = compile_named(
    cell   => HashRef,
    fields => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  my $cell = $p->{cell};
  my $fields = $p->{fields} || join(',', sort keys %{ $p->{cell} });

  $self->batch_requests(
    repeatCell => {
      range  => $self->range_to_index(),
      cell   => $cell,
      fields => $fields,
    },
  );

  return $self;
}

sub heading {
  my $self = shift;
  $self->center()->bold()->white()->bk_black()->font_size(12);
  return $self;
}

sub _bd { shift->borders(properties => shift, border => (shift||'all')); };
sub bd_red { shift->_bd_red_blue_green('red' => shift, @_); }
sub bd_blue { shift->_bd_red_blue_green('blue' => shift, @_); }
sub bd_green { shift->_bd_red_blue_green('green' => shift, @_); }
sub bd_black { shift->bd_color({ red => 0, blue => 0, green => 0 }, @_); }
sub bd_white { shift->bd_color({ red => 1, blue => 1, green => 1 }, @_); }
sub bd_color { shift->_bd({ color => shift }, @_); }
sub bd_dotted { shift->_bd_style('DOTTED', @_); }
sub bd_dashed { shift->_bd_style('DASHED', @_); }
sub bd_solid { shift->_bd_style('SOLID', @_); }
sub bd_medium { shift->_bd_style('SOLID_MEDIUM', @_); }
sub bd_thick { shift->_bd_style('SOLID_THICK', @_); }
sub bd_double { shift->_bd_style('DOUBLE', @_); }
sub bd_none { shift->_bd_style('NONE', @_); }
sub _bd_style { shift->_bd({ style => shift }, @_); }

# allows:
#   bd_red()  turns it all on
#   bd_red(0)  turns it all off
#   bd_red(0.3, 'top')
#   bd_red(0.3)
#   bd_red('top')
sub _bd_red_blue_green {
  my $self = shift;
  my $color = shift;
  my $value;
  $value = shift if looks_like_number($_[0]);
  $value //= 1;
  $self->bd_color({ $color => $value }, @_);
  return $self;
}

sub borders {
  my $self = shift;

  state $check = compile_named(
    border     =>
      StrMatch[qr/^(top|bottom|left|right|all|vertical|horizontal|inner|)$/],
      { default => 'all' },
    properties => HashRef,
  );
  my $p = $check->(@_);
  $p->{border} ||= 'all';

  if ($p->{border} eq 'all') {
    $self->borders(border => $_, properties => $p->{properties})
      foreach (qw(top bottom left right));
    return $self;
  }

  if ($p->{border} eq 'inner') {
    $self->borders(border => $_, properties => $p->{properties})
      foreach (qw(vertical horizontal));
    return $self;
  }

  # change vertical to innerVertical.
  $p->{border} =~ s/^(vertical|horizontal)$/"'inner' . '" . ucfirst($1) . "'"/ee;

  $self->batch_requests(
    updateBorders => {
      range        => $self->range_to_index(),
      $p->{border} => $p->{properties},
    }
  );

  return $self;
}

sub merge_cols { shift->merge_cells(merge_type => 'col'); }
sub merge_rows { shift->merge_cells(merge_type => 'row'); }
sub merge_all { shift->merge_cells(merge_type => 'all'); }
sub merge_both { merge_all(@_); }
sub merge_cells {
  my $self = shift;

  state $check = compile_named(
    merge_type => Range->DimsAll,
  );
  my $p = $check->(@_);
  $p->{merge_type} = dims_all($p->{merge_type});

  $self->batch_requests(
    mergeCells => {
      range     => $self->range_to_index(),
      mergeType => "MERGE_$p->{merge_type}",
    },
  );

  return $self;
}

sub unmerge { unmerge_cells(@_); }
sub unmerge_cells {
  my $self = shift;
  $self->batch_requests(
    unmergeCells => {
      range => $self->range_to_index(),
    },
  );
  return $self;
}

sub insert_d { shift->insert_dimension(dimension => shift, inherit => shift); }
sub insert_dimension {
  my $self = shift;

  state $check = compile_named(
    dimension => Str,
    inherit   => Bool, { default => 0 }
  );
  my $p = $check->(@_);

  $self->batch_requests(
    insertDimension => {
      range             => $self->range_to_dimension($p->{dimension}),
      inheritFromBefore => $p->{inherit},
    },
  );

  return $self;
}

sub insert_r { shift->insert_dimension(dimension => shift); }
sub insert_range {
  my $self = shift;

  state $check = compile_named(
    dimension => Str,
  );
  my $p = $check->(@_);

  $self->batch_requests(
    insertRange    => {
      range => $self->range_to_dimension($p->{dimension}),
    },
    shiftDimension => $p->{dimension},
  );

  return $self;
}

sub move { shift->move_dimension(dimension => shift, destination => shift); }
sub move_dimension {
  my $self = shift;

  state $check = compile_named(
    dimension   => Str,
    destination => HasMethods['range_to_index'],
  );
  my $p = $check->(@_);

  $self->batch_requests(
    insertDimension => {
      range            => $self->range_to_dimension($p->{dimension}),
      destinationIndex => $p->{destination},
    },
  );

  return $self;
}

sub copy_paste {
  my $self = shift;

  state $check = compile_named(
    destination => HasMethods['range_to_index'],
    type        => Str, { default => 'normal' },
    orientation => Str, { default => 'normal' },
  );
  my $p = $check->(@_);
  $p->{type} = "PASTE_" . uc($p->{type});
  $p->{orientation} = uc($p->{orientation});

  $self->batch_requests(
    copyPaste => {
      source      => $self->range_to_index(),
      destination => $p->{destination}->range_to_index(),
      type        => $p->{type},
      orientation => $p->{orientation},
    },
  );

  return $self;
}

sub cut_paste {
  my $self = shift;

  state $check = compile_named(
    destination => HasMethods['range_to_index'],
    type        => Str, { default => 'normal' },
  );
  my $p = $check->(@_);
  $p->{type} = "PASTE_" . uc($p->{type});

  $self->batch_requests(
    cutPaste => {
      source      => $self->range_to_index(),
      destination => $p->{destination}->range_to_index(),
      type        => $p->{type},
    },
  );

  return $self;
}

sub delete_d { shift->delete_dimension(dimension => shift); }
sub delete_dimension {
  my $self = shift;

  state $check = compile_named(dimension => Str);
  my $p = $check->(@_);

  $self->batch_requests(
    deleteDimension => {
      range => $self->range_to_dimension($p->{dimension}),
    },
  );

  return $self;
}

sub delete_r { shift->delete_range(dimension => shift); }
sub delete_range {
  my $self = shift;

  state $check = compile_named(dimension => Str);
  my $p = $check->(@_);

  $self->batch_requests(
    deleteRange => {
      range => $self->range_to_dimension($p->{dimension}),
    },
    shiftDimension => $p->{dimension},
  );

  return $self;
}

sub named_a { shift->add_named(name => shift); }
sub add_named {
  my $self = shift;

  state $check = compile_named(name => Str);
  my $p = $check->(@_);

  $self->batch_requests(
    addNamedRange => {
      namedRange => {
        name  => $p->{name},
        range => $self->range_to_index(),
      },
    }
  );

  return $self;
}

sub named_d { shift->delete_named(); }
sub delete_named {
  my $self = shift;

  my $named = $self->named() or die "Not a named range";
  $self->batch_requests(
    deleteNamedRange => {
      namedRangeId => $named->{namedRangeId},
    },
  );

  return $self;
}

sub _clear {
  my $self = shift;
  return $self->SUPER::_clear(@_, $self->range_to_index());
}

sub range_to_index { shift->range()->range_to_index(@_); }
sub range_to_dimension { shift->range()->range_to_dimension(@_); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range - Build Google API's batchRequests for a Range.

=head1 DESCRIPTION

Deriving from the Request::Spreadsheet::Worksheet object, this adds the ability to create
requests that have to do with ranges (formatting, borders etc).

See the description and synopsis at Google::RestApi::SheetsApi4::Request.
and Google::RestApi::SheetsApi4.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
