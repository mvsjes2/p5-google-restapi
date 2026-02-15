# NAME

Google::RestApi - API to Google Drive API V3, Sheets API V4, Calendar API V3,
Gmail API V1, Tasks API V1, and Docs API V1.

# SYNOPSIS

>
>
>     # create a new RestApi object to be used by the apis.
>     use Google::RestApi;
>     $rest_api = Google::RestApi->new(
>     config_file   => <path_to_config_file>,
>     auth          => <object|hashref>,
>     timeout       => <int>,
>     throttle      => <int>,
>     api_callback  => <coderef>,
>     );
>
>     # you can call the raw api directly, but usually the apis will take care of
>     # forming the correct API calls for you.
>     $response = $rest_api->api(
>     uri     => <google_api_url>,
>     method  => get|head|put|patch|post|delete,
>     headers => [],
>     params  => <query_params>,
>     content => <data_for_body>,
>     );
>
>     use Google::RestApi::DriveApi3;
>     $drive = Google::RestApi::DriveApi3->new(api => $rest_api);
>
>     # file operations
>     $file = $drive->file(id => 'xxxx');
>     $copy = $file->copy(name => 'my-copy-of-xxx');
>     $file->update(name => 'new-name', description => 'new desc');
>     $file->export(mime_type => 'application/pdf');
>
See the individual PODs for the different apis for details on how to use each
one.
>
>

# DESCRIPTION

Google::RestApi is a framework for interfacing with Google products, currently
Drive (Google::RestApi::DriveApi3), Sheets (Google::RestApi::SheetsApi4),
Calendar (Google::RestApi::CalendarApi3), Gmail (Google::RestApi::GmailApi1),
Tasks (Google::RestApi::TasksApi1), and Docs (Google::RestApi::DocsApi1).

The biggest hurdle to using this library is actually setting up the authorization
to access your Google account via a script. The Google development web space is
huge and complex. All that's required here is an OAuth2 token to authorize your
script that uses this library. See bin/google_restapi_oauth_token_creator for
instructions on how to do so. Once you've done it a couple of times it's
straight forward.

The synopsis above is a quick reference. For more detailed information, see the
pods listed in the NAVIGATION section below.

Once you have successfully created your OAuth2 token, you can run the tutorials
to ensure everything is working correctly. Set the environment variable
GOOGLE_RESTAPI_CONFIG to the path to your auth config file. See the
tutorial/ directory for step-by-step tutorials covering Sheets, Drive,
Calendar, Documents, Gmail, and Tasks. These will help you understand how the
API interacts with Google.

# PAGE CALLBACKS

Many list methods across the API support a page_callback parameter for
processing paginated results. The callback is called with the raw API result
hashref after each page is fetched. Return a true value to continue fetching,
or false to stop early.

 # print progress while listing files:
 my @files = $drive->list(
   filter        => "name contains 'report'",
   page_callback => sub {
     my ($result) = @_;
     print "Fetched a page of results...\n";
     return 1;  # continue fetching
   },
 );

 # stop after finding what you need:
 my $target;
 my @messages = $gmail_api->messages(
   max_pages     => 0,       # allow unlimited pages
   page_callback => sub {
     my ($result) = @_;
     foreach my $msg (@{ $result->{messages} || [] }) {
       if ($msg->{id} eq $some_id) {
         $target = $msg;
         return 0;  # stop pagination
       }
     }
     return 1;  # keep going
   },
 );

# NAVIGATION

    Google::RestApi::DriveApi3
    Google::RestApi::DriveApi3::File
    Google::RestApi::DriveApi3::About
    Google::RestApi::DriveApi3::Changes
    Google::RestApi::DriveApi3::Drive
    Google::RestApi::DriveApi3::Permission
    Google::RestApi::DriveApi3::Comment
    Google::RestApi::DriveApi3::Reply
    Google::RestApi::DriveApi3::Revision
    Google::RestApi::SheetsApi4
    Google::RestApi::SheetsApi4::Spreadsheet
    Google::RestApi::SheetsApi4::Worksheet
    Google::RestApi::SheetsApi4::Range
    Google::RestApi::SheetsApi4::Range::All
    Google::RestApi::SheetsApi4::Range::Col
    Google::RestApi::SheetsApi4::Range::Row
    Google::RestApi::SheetsApi4::Range::Cell
    Google::RestApi::SheetsApi4::Range::Iterator
    Google::RestApi::SheetsApi4::RangeGroup
    Google::RestApi::SheetsApi4::RangeGroup::Iterator
    Google::RestApi::SheetsApi4::RangeGroup::Tie
    Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator
    Google::RestApi::SheetsApi4::Request::Spreadsheet
    Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet
    Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range
    Google::RestApi::CalendarApi3
    Google::RestApi::CalendarApi3::Calendar
    Google::RestApi::CalendarApi3::Event
    Google::RestApi::CalendarApi3::Acl
    Google::RestApi::CalendarApi3::CalendarList
    Google::RestApi::CalendarApi3::Colors
    Google::RestApi::CalendarApi3::Settings
    Google::RestApi::GmailApi1
    Google::RestApi::GmailApi1::Message
    Google::RestApi::GmailApi1::Attachment
    Google::RestApi::GmailApi1::Thread
    Google::RestApi::GmailApi1::Draft
    Google::RestApi::GmailApi1::Label
    Google::RestApi::TasksApi1
    Google::RestApi::TasksApi1::TaskList
    Google::RestApi::TasksApi1::Task
    Google::RestApi::DocsApi1
    Google::RestApi::DocsApi1::Document

# STATUS

Partial sheets and drive apis were hand-written by the author. Anthropic
Claude was used to generate the missing api calls for these, and the rest of
the google apis were added using Claude, based on the original hand-wrieetn
patterns. If all works for you, it will be due to the author's stunning
intellect. If it doesn't, or you see strange and wild code, it's all Claude's
fault, nothing to do with the author.

All mock exchanges were generated by running the unit tests and opening the
live api to save the requests/responses for later playback. This process is
used as an integration test. Because all the tests pass using this process,
it's a pretty good indicator that the calls work.

# BUGS

Please report a bug or missing api call by creating an issue at the git repo.

# AUTHORS

- Robin Murray mvsjes@cpan.org

# COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

