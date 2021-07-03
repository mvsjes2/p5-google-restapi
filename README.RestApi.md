# NAME

Google::RestApi - Connection to Google REST APIs (currently Drive and Sheets).

# SYNOPSIS

>     use Google::RestApi;
>     $rest_api = Google::RestApi->new(
>       config_file   => <path_to_config_file>,
>       auth          => <object|hashref>,
>       timeout       => <int>,
>       throttle      => <int>,
>       post_process  => <coderef>,
>     );
>
>     $response = $rest_api->api(
>       uri     => <google_api_url>,
>       method  => get|head|put|patch|post|delete,
>       headers => [],
>       params  => <query_params>,
>       content => <data_for_body>,
>     );
>
>     use Google::RestApi::SheetsApi4;
>     $sheets_api = Google::RestApi::SheetsApi4->new(api => $rest_api);
>     $sheet = $sheets_api->open_spreadsheet(title => "payroll");
>
>     use Google::RestApi::DriveApi3;
>     $drive = Google::RestApi::DriveApi3->new(api => $rest_api);
>     $file = $drive->file(id => 'xxxx');
>     $copy = $file->copy(title => 'my-copy-of-xxx');
>
>     print YAML::Any::Dump($rest_api->stats());

# DESCRIPTION

Google Rest API is the foundation class used by the included Drive
and Sheets APIs. It is used to send API requests to the Google API
endpoint on behalf of the underlying API classes (Sheets and Drive).

# SUBROUTINES

- new(config\_file => &lt;path\_to\_config\_file>, auth => &lt;object|hash>, post\_process => &lt;coderef>, throttle => &lt;int>);

        config_file: Optional YAML configuration file that can specify any
          or all of the following args:
        auth: A hashref to create the specified auth class, or (outside the config file) an instance of the blessed class itself.
        post_process: A coderef to call after each API call.
        throttle: Used in development to sleep the number of seconds
          specified between API calls to avoid threshhold errors from Google.

    You can specify any of the arguments in the optional YAML config file.
    Any passed in arguments will override what is in the config file.

    The 'auth' arg can specify a pre-blessed class of one of the Google::RestApi::Auth::\*
    classes, or, for convenience sake, you can specify a hash of the required
    arguments to create an instance of that class:
      auth:
        class: OAuth2Client
        client\_id: xxxxxx
        client\_secret: xxxxxx
        token\_file: &lt;path\_to\_token\_file>

    Note that the auth hash itself can also contain a config\_file:
      auth:
        class: OAuth2Client
        config\_file: &lt;path\_to\_oauth\_config\_file>

    This allows you the option to keep the auth file in a separate, more secure place.

- api(uri => &lt;uri\_string>, method => &lt;http\_method\_string>,
  headers => &lt;headers\_string\_array>, params => &lt;query\_parameters\_hash>,
  content => &lt;body\_hash>);

    The ultimate Google API call for the underlying classes. Handles timeouts
    and retries etc.

        uri: The Google API endpoint such as https://www.googleapis.com/drive/v3
          along with any path segments added.
        method: The http method being used get|head|put|patch|post|delete.
        headers: Array ref of http headers.
        params: Http query params to be added to the uri.
        content: The body being sent for post/put etc. Will be encoded to JSON.

    You would not normally call this directly unless you were
    making a Google API call not currently supported by this API
    framework.

- stats();

    Shows some statistics on how many get/put/post etc calls were made.
    Useful for performance tuning during development.

# SEE ALSO

For specific use of this class, see:

    Google::RestApi::SheetsApi4
    Google::RestApi::DriveApi3

# AUTHORS

- Test User mvsjes@cpan.org

# COPYRIGHT

Copyright (c) 2019, Test User. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
