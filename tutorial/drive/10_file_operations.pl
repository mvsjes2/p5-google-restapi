#!/usr/bin/env perl

# This tutorial demonstrates Drive API file operations:
# - Getting file metadata
# - Updating file properties
# - Managing permissions
# - Copying and deleting files
#
# Run with: GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml perl tutorial/drive/10_file_operations.pl
# Add DEBUG=1 for verbose API logging.

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../../t/lib";
use lib "$FindBin::RealBin/../../lib";

use Tutorial::Setup;

init_logger($TRACE) if $ENV{DEBUG};

my $name = spreadsheet_name();
my $rest_api = rest_api();
my $sheets_api = sheets_api(api => $rest_api);
my $drive = drive_api(api => $rest_api);

# clean up any failed previous runs.
$sheets_api->delete_all_spreadsheets_by_filters("name = '$name'");

# create a spreadsheet to work with.
start("Creating a spreadsheet named '$name' to demonstrate Drive file operations.");
my $ss = $sheets_api->create_spreadsheet(title => $name);
my $file_id = $ss->spreadsheet_id();
end("Spreadsheet created with ID: $file_id.");

# now set a callback to display the api request/response.
$rest_api->api_callback(\&show_api);

# get file metadata.
start("Now we'll get the file's metadata using the Drive API.");
my $file = $drive->file(id => $file_id);
my $metadata = $file->get(fields => 'name, mimeType, createdTime, modifiedTime');
end("File metadata:\n" . Dump($metadata));

# update file description.
start("Now we'll update the file's description.");
$file->update(description => 'Created by Google::RestApi Drive tutorial');
my $updated = $file->get(fields => 'name, description');
end("Updated file:\n" . Dump($updated));

# add a permission (reader, anyone with the link).
start("Now we'll add a 'reader' permission so anyone with the link can view.");
my $perm = $file->permission()->create(
  role => 'reader',
  type => 'anyone',
);
my $perm_id = $perm->permission_id();
end("Permission created with ID: $perm_id.");

# list permissions.
start("Now we'll list all permissions on the file.");
my @perms = $file->permissions();
end("File has " . scalar(@perms) . " permission(s):\n" . Dump(\@perms));

# remove the permission we added.
start("Now we'll remove the 'anyone' permission.");
$perm->delete();
end("Permission deleted.");

# copy the file.
start("Now we'll make a copy of the file.");
my $copy = $file->copy(name => "${name}_drive_copy");
my $copy_id = $copy->file_id();
end("File copied, new ID: $copy_id.");

# clean up the copy.
start("Now we'll delete the copy.");
$copy->delete();
end("Copy deleted.");

message('green', "\nThe original spreadsheet '$name' is still available.");
message('green', "Proceed to 20_comments.pl to see comments and replies.\n");

message('blue', "We are done, here are some api stats:\n", Dump($sheets_api->stats()));
