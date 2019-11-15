package Test::Google::RestApi::SheetsApi4::Range;

use YAML::Any qw(Dump);
use Test::Most;

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

my $index = {
  sheetId          => 'mock_worksheet_id',
  startColumnIndex => 0,
  startRowIndex    => 0,
  endColumnIndex   => 1,
  endRowIndex      => 1,
};

sub range_text_format : Tests(29) {
  my $self = shift;

  my $cell = {
    repeatCell => {
      range => '',
      cell => {
        userEnteredFormat => {
          textFormat => {}
        },
      },
      fields => '',
    },
  };

  my $range = $self->new_range("A1");
  $cell->{repeatCell}->{range} = $range->range_to_index();
  my $text_format = $cell->{repeatCell}->{cell}->{userEnteredFormat}->{textFormat};
  my $fields = $cell->{repeatCell}->{fields};
  my @requests;

  is $range->bold(), $range, "Bold should return the same range";
  @requests = $range->batch_requests();
  is scalar $range->batch_requests(), 1, "Batch requests should have one entry.";
  $text_format->{bold} = 'true'; _add_field($cell, "userEnteredFormat.textFormat.bold");
  is_deeply $requests[0], $cell, "Bold should be staged";

  is $range->italic(), $range, "Italic should return the same range";
  @requests = $range->batch_requests();
  is scalar @requests, 1, "Batch requests should still have one entry.";
  $text_format->{italic} = 'true'; _add_field($cell, 'userEnteredFormat.textFormat.italic');
  is_deeply $requests[0], $cell, "Italic should be staged";

  is $range->strikethrough(), $range, "Strikethrough should return the same range";
  $text_format->{strikethrough} = 'true'; _add_field($cell, 'userEnteredFormat.textFormat.strikethrough');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Strikethrough should be staged";

  is $range->underline(), $range, "Underline should return the same range";
  $text_format->{underline} = 'true'; _add_field($cell, 'userEnteredFormat.textFormat.underline');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Underline should be staged";

  $text_format->{foregroundColor} = {};
  my $foreground_color = $text_format->{foregroundColor};
  is $range->red(), $range, "Red should return the same range";
  $foreground_color->{red} = 1; _add_field($cell, 'userEnteredFormat.textFormat.foregroundColor');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Red should be staged";

  is $range->blue(0.2), $range, "Blue should return the same range";
  $foreground_color->{blue} = 0.2;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Blue should be staged";

  is $range->green(0), $range, "Green should return the same range";
  $foreground_color->{green} = 0;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Green should be staged";

  is $range->font_family('joe'), $range, "Font family should return the same range";
  $text_format->{fontFamily} = 'joe'; _add_field($cell, 'userEnteredFormat.textFormat.fontFamily');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Font family should be staged";

  is $range->font_size(1.1), $range, "Font size should return the same range";
  $text_format->{fontSize} = 1.1; _add_field($cell, 'userEnteredFormat.textFormat.fontSize');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Font size should be staged";

  lives_ok sub { _range_text_format_all($range); }, "Build all for text format should succeed";
  @requests = $range->batch_requests();
  is scalar @requests, 1, "Batch requests should have one entry.";
  is_deeply $requests[0], $cell, "Build all should be same as previous build";

  lives_ok sub { _range_text_format_all($range)->white(); }, "Build all text white should succeed";
  $foreground_color->{red} = $foreground_color->{blue} = $foreground_color->{green} = 1;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Text white should be built correctly";

  lives_ok sub { _range_text_format_all($range)->black(); }, "Build all text black should succeed";
  $foreground_color->{red} = $foreground_color->{blue} = $foreground_color->{green} = 0;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Text black should be built correctly";

  lives_ok sub { $range->submit_requests(); }, "Submit format request should succeed";
  is scalar $range->batch_requests(), 0, "Batch requests should have been emptied";

  return;
}

sub range_background_color : Tests(14) {
  my $self = shift;

  my $cell = {
    repeatCell => {
      range => '',
      cell => {
        userEnteredFormat => {
          backgroundColor => {},
        },
      },
      fields => '',
    },
  };

  my $range = $self->new_range("A1");
  $cell->{repeatCell}->{range} = $range->range_to_index();
  my $bk_color = $cell->{repeatCell}->{cell}->{userEnteredFormat}->{backgroundColor};
  my $fields = $cell->{repeatCell}->{fields};
  my @requests;

  is $range->bk_red(), $range, "Background red should return the same range";
  $bk_color->{red} = 1; _add_field($cell, 'userEnteredFormat.backgroundColor');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background red should be staged";

  is $range->bk_blue(0.2), $range, "Background blue should return the same range";
  $bk_color->{blue} = 0.2;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background blue should be staged";

  is $range->bk_green(0), $range, "Background green should return the same range";
  $bk_color->{green} = 0;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background green should be staged";

  lives_ok sub { $range->bk_white(); }, "Background white should succeed";
  $bk_color->{red} = $bk_color->{blue} = $bk_color->{green} = 1;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background white request should be built correctly";

  lives_ok sub { $range->bk_black(); }, "Background black should succeed";
  $bk_color->{red} = $bk_color->{blue} = $bk_color->{green} = 0;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background black request should be built correctly";

  lives_ok sub { $range->bk_white()->bk_black(); }, "Background white/black should succeed";
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background white/black request should be built correctly";

  lives_ok sub { $range->submit_requests(); }, "Submit format request should succeed";
  is scalar $range->batch_requests(), 0, "Batch requests should have been emptied";

  return;
}

sub range_borders : Tests(18) {
  my $self = shift;

  my $cell = {
    updateBorders => {
      range => '',
    },
  };

  my $range = $self->new_range("A1");
  my $borders = $cell->{updateBorders};
  $borders->{range} = $range->range_to_index();
  my @requests;

  lives_ok sub { $range->bd_dotted('top'); }, "Setting top should live";
  $borders->{top}->{style} = 'DOTTED';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border dotted should be staged on top";

  lives_ok sub { $range->bd_dotted('bottom'); }, "Setting bottom should live";
  $borders->{bottom}->{style} = 'DOTTED';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border dotted should be staged on bottom";

  lives_ok sub { $range->bd_dotted('left'); }, "Setting left should live";
  $borders->{left}->{style} = 'DOTTED';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border dotted should be staged on left";

  lives_ok sub { $range->bd_dotted('right'); }, "Setting right should live";
  $borders->{right}->{style} = 'DOTTED';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border dotted should be staged on right";

  lives_ok sub { $range->bd_dotted('vertical'); }, "Setting vertical should live";
  $borders->{innerVertical}->{style} = 'DOTTED';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border dotted should be staged on inner vertical";

  lives_ok sub { $range->bd_dotted('horizontal'); }, "Setting horizontal should live";
  $borders->{innerHorizontal}->{style} = 'DOTTED';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border dotted should be staged on inner horizontal";

  my %save_outside = map { $_ => delete $borders->{$_}; } qw(top bottom left right);
  my %save_inside = map { $_ => delete $borders->{$_}; } qw(innerVertical innerHorizontal);

  $range->submit_requests();
  lives_ok sub { $range->bd_dotted(); }, "Setting outside borders should live";
  @$borders{ keys %save_outside } = values %save_outside;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border dotted should be staged on outside";

  $range->submit_requests();
  lives_ok sub { $range->bd_dotted('all'); }, "Setting all outside borders should live";
  @$borders{ keys %save_outside } = values %save_outside;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border dotted should be staged on outside";

  $range->submit_requests();
  lives_ok sub { $range->bd_dotted('inner'); }, "Setting outside borders should live";
  delete @$borders{qw(top bottom left right)};
  @$borders{ keys %save_inside } = values %save_inside;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border dotted should be staged on inside";

  return;
}

sub range_border_style : Tests(14) {
  my $self = shift;

  my $cell = {
    updateBorders => {
      range => '',
      top   => {
        style => '',
      },
    },
  };

  my $range = $self->new_range("A1");
  $cell->{updateBorders}->{range} = $range->range_to_index();
  my $bd_top = $cell->{updateBorders}->{top};
  my @requests;

  is $range->bd_dotted('top'), $range, "Border dotted should return the same range";
  $bd_top->{style} = 'DOTTED';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border dotted should be staged";

  is $range->bd_dashed('top'), $range, "Border dashed should return the same range";
  $bd_top->{style} = 'DASHED';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border dashed should be staged";

  is $range->bd_solid('top'), $range, "Border solid should return the same range";
  $bd_top->{style} = 'SOLID';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border solid should be staged";

  is $range->bd_medium('top'), $range, "Border medium should return the same range";
  $bd_top->{style} = 'SOLID_MEDIUM';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border medium should be staged";

  is $range->bd_thick('top'), $range, "Border thick should return the same range";
  $bd_top->{style} = 'SOLID_THICK';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border thick should be staged";

  is $range->bd_double('top'), $range, "Border double should return the same range";
  $bd_top->{style} = 'DOUBLE';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border double should be staged";

  is $range->bd_none('top'), $range, "Border none should return the same range";
  $bd_top->{style} = 'NONE';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border none should be staged";

  return;
}

sub range_border_colors : Tests(14) {
  my $self = shift;

  my $cell = {
    updateBorders => {
      range => '',
      top   => {
        color => {},
      },
    },
  };

  my $range = $self->new_range("A1");
  $cell->{updateBorders}->{range} = $range->range_to_index();
  my $bd_color = $cell->{updateBorders}->{top}->{color};
  my @requests;

  is $range->bd_red('top'), $range, "Border red should return the same range";
  $bd_color->{red} = 1;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border red should be staged";

  is $range->bd_blue(0.2, 'top'), $range, "Border blue should return the same range";
  $bd_color->{blue} = 0.2;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border blue should be staged";

  is $range->bd_green(0, 'top'), $range, "Border green should return the same range";
  $bd_color->{green} = 0;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border green should be staged";

  lives_ok sub { $range->bd_white('top'); }, "Border white should succeed";
  $bd_color->{red} = $bd_color->{blue} = $bd_color->{green} = 1;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border white request should be built correctly";

  lives_ok sub { $range->bd_black('top'); }, "Border black should succeed";
  $bd_color->{red} = $bd_color->{blue} = $bd_color->{green} = 0;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border black request should be built correctly";

  lives_ok sub { $range->bd_white('top')->bd_black('top'); }, "Border white/black should succeed";
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border white/black request should be built correctly";

  lives_ok sub { $range->submit_requests(); }, "Submit format request should succeed";
  is scalar $range->batch_requests(), 0, "Batch requests should have been emptied";

  return;
}

sub range_border_cells : Tests(7) {
  my $self = shift;

  my $cell = {
    repeatCell => {
      range => '',
      cell => {
        userEnteredFormat => {
          borders => {}
        },
      },
      fields => '',
    },
  };

  my $range = $self->new_range("A1");
  $cell->{repeatCell}->{range} = $range->range_to_index();
  my $borders = $cell->{repeatCell}->{cell}->{userEnteredFormat}->{borders};
  my $fields = $cell->{repeatCell}->{fields};
  my @requests;

  my $err = qr/when bd_repeat_cell is turned on/;
  is $range->bd_repeat_cell(), $range, "Repeat cell should return the same range";
  throws_ok { $range->bd_red('inner'); } $err, "Turning on inner when repeat cell is on should die";
  throws_ok { $range->bd_red('vertical'); } $err, "Turning on vertical when repeat cell is on should die";
  throws_ok { $range->bd_red('horizontal'); } $err, "Turning on horizontal when repeat cell is on should die";

  lives_ok sub { $range->bd_red('top'); }, "Border red repeat cell should live";
  @requests = $range->batch_requests();
  is scalar $range->batch_requests(), 1, "Batch requests should have one entry.";
  $borders->{top}->{color}->{red} = 1; _add_field($cell, "userEnteredFormat.borders");
  is_deeply $requests[0], $cell, "Border red repeat cell should be staged";

  return;
}

sub range_merge : Tests(6) {
  my $self = shift;

  my $cell = {
    mergeCells => {
      range     => '',
      mergeType => '',
    },
  };

  my $range = $self->new_range("A1:B2");
  $cell->{mergeCells}->{range} = $range->range_to_index();
  my @requests;

  $range->red()->merge_cols();
  @requests = $range->batch_requests();
  is scalar @requests, 2, "Batch requests should have two entries";
  $cell->{mergeCells}->{mergeType} = 'MERGE_COLUMNS';
  is_deeply $requests[1], $cell, "Merge columns should be staged";

  $range->merge_rows();
  @requests = $range->batch_requests();
  is scalar @requests, 2, "Batch requests should still have two entries";
  $cell->{mergeCells}->{mergeType} = 'MERGE_ROWS';
  is_deeply $requests[1], $cell, "Merge rows should be staged";

  $range->merge_both();
  @requests = $range->batch_requests();
  is scalar @requests, 2, "Batch requests should continue have two entries";
  $cell->{mergeCells}->{mergeType} = 'MERGE_ALL';
  is_deeply $requests[1], $cell, "Merge both should be staged";

  return;
}

sub _range_text_format_all {
  shift->
    bold()->italic()->strikethrough()->underline()->
    red()->blue(0.2)->green(0)->font_family('joe')->font_size(1.1);
}

sub _add_field {
  my ($cell, $field) = (@_);
  my @fields = split(',', $cell->{repeatCell}->{fields});
  $cell->{repeatCell}->{fields} = join(',', sort @fields, $field);
  return;
}

1;
