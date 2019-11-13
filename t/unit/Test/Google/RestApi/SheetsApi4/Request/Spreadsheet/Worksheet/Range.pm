package Test::Google::RestApi::SheetsApi4::Range;

use YAML::Any qw(Dump);
use Test::Most;

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

sub class { 'Google::RestApi::SheetsApi4::Range' }

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
  my @requests;

  my $text_format = $cell->{repeatCell}->{cell}->{userEnteredFormat}->{textFormat};
  my $fields = $cell->{repeatCell}->{fields};

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

  is $range->green(0.4), $range, "Green should return the same range";
  $foreground_color->{green} = 0.4;
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
          backgroundColor => {}
        },
      },
      fields => '',
    },
  };

  my $range = $self->new_range("A1");
  $cell->{repeatCell}->{range} = $range->range_to_index();
  my $background_color = $cell->{repeatCell}->{cell}->{userEnteredFormat}->{backgroundColor};
  my $fields = $cell->{repeatCell}->{fields};
  my @requests;

  is $range->background_red(), $range, "Background red should return the same range";
  $background_color->{red} = 1; _add_field($cell, 'userEnteredFormat.backgroundColor');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background red should be staged";

  is $range->background_blue(0.2), $range, "Background blue should return the same range";
  $background_color->{blue} = 0.2;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background blue should be staged";

  is $range->background_green(0.4), $range, "Background green should return the same range";
  $background_color->{green} = 0.4;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background green should be staged";

  lives_ok sub { $range->background_white(); }, "Background white should succeed";
  $background_color->{red} = $background_color->{blue} = $background_color->{green} = 1;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background white request should be built correctly";

  lives_ok sub { $range->background_black(); }, "Background black should succeed";
  $background_color->{red} = $background_color->{blue} = $background_color->{green} = 0;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background black request should be built correctly";

  lives_ok sub { $range->background_white()->background_black(); }, "Background white/black should succeed";
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background white/black request should be built correctly";

  lives_ok sub { $range->submit_requests(); }, "Submit format request should succeed";
  is scalar $range->batch_requests(), 0, "Batch requests should have been emptied";

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
    red()->blue(0.2)->green(0.4)->font_family('joe')->font_size(1.1);
}

sub _add_field {
  my ($cell, $field) = (@_);
  my @fields = split(',', $cell->{repeatCell}->{fields});
  $cell->{repeatCell}->{fields} = join(',', sort @fields, $field);
  return;
}

1;
