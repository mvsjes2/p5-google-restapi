package Google::RestApi::SheetsApi4;

our $VERSION = '1.0.3';

use Google::RestApi::Setup;

use Module::Load qw( load );
use Try::Tiny ();
use YAML::Any ();

use aliased 'Google::RestApi::DriveApi3';
use aliased 'Google::RestApi::SheetsApi4::Spreadsheet';

# TODO: switch to ReadOnly
use constant {
  Sheets_Endpoint    => "https://sheets.googleapis.com/v4/spreadsheets",
  Spreadsheet_Filter => "mimeType='application/vnd.google-apps.spreadsheet'",
  Spreadsheet_Id     => DriveApi3->Drive_File_Id,
  Spreadsheet_Uri    => "https://docs.google.com/spreadsheets/d",
  Worksheet_Id       => "[0-9]+",
  Worksheet_Uri      => "[#&]gid=([0-9]+)",
};

sub new {
  my $class = shift;

  state $check = compile_named(
    api           => HasApi,                                           # the G::RestApi object that will be used to send http calls.
    drive         => HasMethods[qw(filter_files)], { optional => 1 },  # a drive instnace, could be your own, defaults to G::R::DriveApi3.
    endpoint      => Str, { default => Sheets_Endpoint },              # this gets tacked on to the api uri to reach the sheets endpoint.
  );
  my $self = $check->(@_);

  return bless $self, $class;
}

# this gets called by lower-level classes like worksheet and range objects. they
# will have passed thier own uri with params and possible body, we tack on the
# sheets endpoint and pass it up the line to G::RestApi to make the actual call.
sub api {
  my $self = shift;
  state $check = compile_named(
    uri     => Str, { default => '' },
    _extra_ => slurpy Any,              # just pass through any extra params to G::RestApi::api call.
  );
  my $p = named_extra($check->(@_));
  my $uri = $self->{endpoint};          # tack on the uri endpoint and pass the buck.
  $uri .= "/$p->{uri}" if $p->{uri};
  return $self->rest_api()->api(%$p, uri => $uri);
}

sub create_spreadsheet {
  my $self = shift;

  state $check = compile_named(
    title   => Str, { optional => 1 },
    name    => Str, { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  # we allow name and title to be synonymous for convenience. it's actuall title in the google api.
  $p->{title} || $p->{name} or LOGDIE "Either 'title' or 'name' should be supplied";
  $p->{title} ||= $p->{name};
  delete $p->{name};

  my $result = $self->api(
    method  => 'post',
    content => { properties => $p },
  );
  for (qw(spreadsheetId spreadsheetUrl properties)) {
    $result->{$_} or LOGDIE "No '$_' returned from creating spreadsheet";
  }

  return $self->open_spreadsheet(
    id  => $result->{spreadsheetId},
    uri => $result->{spreadsheetUrl},
  );
}

sub copy_spreadsheet {
  my $self = shift;
  my $id = Spreadsheet_Id;
  state $check = compile_named(
    spreadsheet_id => StrMatch[qr/$id/],
    _extra_        => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  my $file_id = delete $p->{spreadsheet_id};
  my $file = $self->drive()->file(id => $file_id);
  my $copy = $file->copy(%$p);
  return $self->open_spreadsheet(id => $copy->file_id());
}

sub delete_spreadsheet {
  my $self = shift;
  my $id = Spreadsheet_Id;
  state $check = compile(StrMatch[qr/$id/]);
  my ($spreadsheet_id) = $check->(@_);
  return $self->drive()->file(id => $spreadsheet_id)->delete();
}

# delete all the spreadsheets by the names passed.
sub delete_all_spreadsheets {
  my $self = shift;

  state $check = compile(ArrayRef->plus_coercions(Str, sub { [$_]; }));
  my ($names) = $check->(@_);

  my $count = 0;
  foreach my $name (@$names) {
    my @spreadsheets = grep { $_->{name} eq $name; } $self->spreadsheets();
    $count += scalar @spreadsheets;
    DEBUG(sprintf("Deleting %d spreadsheets for name '$name'", scalar @spreadsheets));
    $self->delete_spreadsheet($_->{id}) foreach (@spreadsheets);
  }
  return $count;
}

# list all spreadsheets.
sub spreadsheets {
  my $self = shift;
  my $drive = $self->drive();
  my $spreadsheets = $drive->filter_files(Spreadsheet_Filter);
  my @spreadsheets = map { { id => $_->{id}, name => $_->{name} }; } @{ $spreadsheets->{files} };
  return @spreadsheets;
}

sub drive {
  my $self = shift;
  if (!$self->{drive}) {
    load DriveApi3;
    $self->{drive} = DriveApi3->new(api => $self->rest_api());
  }
  return $self->{drive};
}

sub open_spreadsheet { Spreadsheet->new(sheets_api => shift, @_); }
sub transaction { shift->rest_api()->transaction(); }
sub stats { shift->rest_api()->stats(); }
sub rest_api { shift->{api}; }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4 - API to Google Sheets API V4.

=head1 SYNOPSIS

=over

 use aliased Google::RestApi;
 use aliased Google::RestApi::SheetsApi4;

 $rest_api = RestApi->new(%config);
 $sheets_api = SheetsApi4->new(api => $rest_api);
 $sheet = $sheets_api->create_spreadsheet(title => 'my_name');
 $ws0 = $sheet->open_worksheet(id => 0);
 $sw1 = $sheet->add_worksheet(name => 'Fred');

 # sub Worksheet::cell/col/cols/row/rows immediately get/set
 # values. this is less efficient but the simplest way to
 # interface with the api. you don't deal with any intermediate
 # api objects.
 
 # add some data to the worksheet:
 @values = (
   [ 1001, "Herb Ellis", "100", "10000" ],
   [ 1002, "Bela Fleck", "200", "20000" ],
   [ 1003, "Freddie Mercury", "999", "99999" ],
 );
 $ws0->rows([1, 2, 3], \@values);
 $values = $ws0->rows([1, 2, 3]);

 # use and manipulate 'range' objects to do more complex work.
 # ranges can be specified in many ways, use whatever way is most convenient.
 $range = $ws0->range("A1:B2");
 $range = $ws0->range([[1,1],[2,2]]);
 $range = $ws0->range([{col => 1, row => 1}, {col => 2, row => 2}]);

 $cell = $ws0->range_cell("A1");
 $cell = $ws0->range_cell([1,1]);
 $cell = $ws0->range_cell({col => 1, row => 1});

 $col = $ws0->range_col(1);
 $col = $ws0->range_col("A3:A");
 $col = $ws0->range_col([1]);
 $col = $ws0->range_col([[1, 3], [1]]);
 $col = $ws0->range_col({col => 1});

 $row = $ws0->range_row(1);
 $row = $ws0->range_row("C1:1");
 $row = $ws0->range_row([<false>, 1]);
 $row = $ws0->range_row({row => 1});
 $row = $ws0->range_row([{col => 3, row => 1 }, {row => 1}]);

 # add a header:
 $row = $ws0->range_row(1);
 $row->insert_d()->freeze()->bold()->italic()->center()->middle()->submit_requests();
 # sends the values to the api directly, not using batch (less efficient):
 $row->values(values => [qw(Id Name Tax Salary)]);

 # bold the names:
 $col = $ws0->range_col("B2:B");
 $col->bold()->submit_requests();

 # add some tax info:
 $tax = $ws0->range_cell([ 3, 5 ]);   # or 'C5' or [ 'C', 5 ] or { col => 3, row => 5 }...
 $salary = $ws0->range_cell({ col => "D", row => 5 }); # same as "D5"
 # set up batch update with staged values:
 $tax->batch_values(values => "=SUM(C2:C4)");
 $salary->batch_values(values => "=SUM(D2:D4)");
 # now collect the ranges into a group and send the values via batch:
 $rg = $sheet->range_group($tax, $salary);
 $rg->submit_values();
 # bold and italicize both cells, and put a solid border around each one:
 $rg->bold()->italic()->bd_solid()->submit_requests();

 # tie ranges to a hash:
 $row = $ws0->tie_cells({id => 'A2'}, {name => 'B2'});
 $row->{id} = '1001';
 $row->{name} = 'Herb Ellis';
 tied(%$row)->submit_values();

 # or use a hash slice:
 $ranges = $ws0->tie_ranges();
 @$ranges{ 'A2', 'B2', 'C2', 'D4:E5' } =
   (1001, "Herb Ellis", "123 Some Street", [["Halifax"]]);
 tied(%$ranges)->submit_values();

 # use simple header column/row values as a source for tied keys:
 $cols = $ws0->tie_cols('Id', 'Name');
 $cols->{Id} = [1001, 1002, 1003];
 $cols->{Name} = ['Herb Ellis', 'Bela Fleck', 'Freddie Mercury'];
 tied(%$cols)->submit_values();

 # format tied values by requesting that the tied hash returns the
 # underlying range objects on fetch:
 tied(%$rows)->fetch_range(1);
 $rows->{Id}->bold()->center();
 $rows->{Name}->red();
 # turn off fetch range and submit the formatting:
 tied(%$rows)->fetch_range(0)->submit_requests();

 # iterators can be used to step through ranges:
 # a basic iterator on a column:
 $col = $ws0->range_col(1);
 $i = $col->iterator();
 while(1) {
   $cell = $i->next();
   last if !defined $cell->values();
 }

 # a basic iterator on an arbitrary range, iterating by col or row:
 $range = $ws0->range("A1:C3");
 $i = $range->iterator(dim => 'col');
 $cell = $i->next();  # A1
 $cell = $i->next();  # A2
 $i = $range->iterator(dim => 'row');
 $cell = $i->next();  # A1
 $cell = $i->next();  # B1

 # an iterator on a range group:
 $col = $ws0->range_col(1);
 $row = $ws0->range_row(1);
 $rg = $sheet->range_group($col, $row);
 $i = $rg->iterator();
 $rg2 = $i->next();  # another range group of cells A1, A1
 $rg2 = $i->next();  # another range group of cells A2, B1

 # an iterator on a tied range group:
 $cols = $ws0->tie_cols(qw(Id Name));
 $i = tied(%$cols)->iterator();
 $row = $i->next();
 $row->{Id} = '1001';
 $row->{Name} = 'Herb Ellis';
 tied(%$row)->submit_values();

=back

=head1 DESCRIPTION

SheetsApi4 is an API to Google Sheets. It is very perl-ish in that there is usually "more than one way to do it". It provides default behaviours
that should be fine for most normal needs, but those behaviours can be overridden when necessary.

It is assumed that you are familiar with the Google Sheets API: https://developers.google.com/sheets/api

C<t/tutorial/sheets/*> also has a step-by-step tutorial of creating and updating a spreadsheet, showing you the API calls and return values for each step.

=head1 NAVIGATION

=over

=item * L<Google::RestApi::SheetsApi4>

=item * L<Google::RestApi::SheetsApi4::Spreadsheet>

=item * L<Google::RestApi::SheetsApi4::Worksheet>

=item * L<Google::RestApi::SheetsApi4::Range>

=item * L<Google::RestApi::SheetsApi4::Range::All>

=item * L<Google::RestApi::SheetsApi4::Range::Col>

=item * L<Google::RestApi::SheetsApi4::Range::Row>

=item * L<Google::RestApi::SheetsApi4::Range::Cell>

=item * L<Google::RestApi::SheetsApi4::RangeGroup>

=item * L<Google::RestApi::SheetsApi4::RangeGroup::Iterator>

=item * L<Google::RestApi::SheetsApi4::RangeGroup::Tie>

=item * L<Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator>

=item * L<Google::RestApi::SheetsApi4::Request::Spreadsheet>

=item * L<Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet>

=item * L<Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range>

=back

=head1 SUBROUTINES

=over

=item new(%args);

Creates a new instance of a SheetsApi object.

%args consists of:

=over

=item C<api> L<<Google::RestApi>>: A reference to a configured L<Google::RestApi> instance.

=back

=item api(%args);

%args consists of:

=over

=item * C<uri> <path_segments_string>: Adds this path segment to the Sheets endpoint and calls the L<Google::RestApi>'s C<api> subroutine.

=item * C<%args>: Passes any extra arguments to the L<Google::RestApi>'s C<api> subroutine (content, params, method etc).

=back

This is essentially a pass-through method between lower-level Worksheet/Range objects and L<Google::RestApi>, where this method adds in the Sheets endpoint.
See <Google::RestApi::SheetsApi4::Worksheet>'s C<api> routine for how this is called. You would not normally call this directly unless you were making a Google API call not currently
supported by this API framework.

Returns the response hash from Google API.

=item create_spreadsheet(%args);

Creates a new spreadsheet.

%args consists of:

=over

=item * C<title|name> <string>: The title (or name) of the new spreadsheet.

=item * C<%args>: Passes through any extra arguments to Google Drive's create file routine.

=back

Args C<title> and C<name> are synonymous, you can use either. Note that Sheets allows multiple spreadsheets with the same name. 

Normally this would be called via the Spreadsheet object, which would fill in the Drive file ID for you.

Returns the object instance of the new spreadsheet object.

=item copy_spreadsheet(%args);

Creates a copy of a spreadsheet.

%args consists of:

=over

=item * C<spreadsheet_id> <string>: The file ID in Google Drive of the spreadsheet you want to make a copy of.

=item * C<%args>: Additional arguments passed through to Google Drive file copy subroutine.

=back

Returns the object instance of the new spreadsheet object.

=item delete_spreadsheet(spreadsheet_id<string>);

Deletes the spreadsheet from Google Drive.

%args consists of:

spreadsheet_id is the file ID in Google Drive of the spreadsheet you want to delete.

Returns the Google API response.

=item delete_all_spreadsheets(spreadsheet_name<string>);

Deletes all spreadsheets with the given name from Google Drive. 

Returns the number of spreadsheets deleted.

=item spreadsheets();

Returns a list of spreadsheets in Google Drive.

=item drive();

Returns an instance of Google Drive that shares the same RestApi as this SheetsApi object. You would not normally need to use this directly.

=item open_spreadsheet(%args);

Opens a new spreadsheet from the given id, uri, or name.

%args consists of any args passed to Spreadsheet->new routine (which see).

=back

=head1 STATUS

This api is currently in beta status. It is incomplete. There may be design flaws that need to be addressed in later releases. Later
releases may break this release. Not all api calls have been implemented.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2021, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
