#!/usr/bin/env perl

# Post-process Drive.pm.exchanges after live regeneration.
# The Drive tests use a fake 'drive123' shared drive ID, so live runs
# produce 404/400 errors. This script replaces those with canned
# success responses so the unit tests pass.

use strict;
use warnings;

use FindBin;
use YAML::Any qw(LoadFile Dump);

my $file = "$FindBin::RealBin/../unit/Test/Google/RestApi/DriveApi3/Drive.pm.exchanges";
die "Exchange file not found: $file\n" unless -f $file;

my @exchanges = LoadFile($file);

my %canned = (
  'Test::Google::RestApi::DriveApi3::Drive::get_drive' => {
    code    => 200,
    message => 'OK',
    headers => ['content-type', 'application/json; charset=UTF-8'],
    content => qq|{\n  "kind": "drive#drive",\n  "id": "drive123",\n  "name": "Test Shared Drive",\n  "colorRgb": "#0F9D58",\n  "capabilities": {\n    "canAddChildren": true,\n    "canDeleteDrive": true,\n    "canRenameDrive": true\n  }\n}\n|,
  },
  'Test::Google::RestApi::DriveApi3::Drive::get_with_fields' => {
    code    => 200,
    message => 'OK',
    headers => ['content-type', 'application/json; charset=UTF-8'],
    content => qq|{\n  "id": "drive123",\n  "name": "Test Shared Drive"\n}\n|,
  },
  'Test::Google::RestApi::DriveApi3::Drive::get_with_domain_admin' => {
    code    => 200,
    message => 'OK',
    headers => ['content-type', 'application/json; charset=UTF-8'],
    content => qq|{\n  "kind": "drive#drive",\n  "id": "drive123",\n  "name": "Test Shared Drive"\n}\n|,
  },
  'Test::Google::RestApi::DriveApi3::Drive::update_drive' => {
    code    => 200,
    message => 'OK',
    headers => ['content-type', 'application/json; charset=UTF-8'],
    content => qq|{\n  "kind": "drive#drive",\n  "id": "drive123",\n  "name": "Renamed Drive"\n}\n|,
  },
  'Test::Google::RestApi::DriveApi3::Drive::update_with_options' => {
    code    => 200,
    message => 'OK',
    headers => ['content-type', 'application/json; charset=UTF-8'],
    content => qq|{\n  "kind": "drive#drive",\n  "id": "drive123",\n  "name": "Styled Drive",\n  "colorRgb": "#FF0000"\n}\n|,
  },
  'Test::Google::RestApi::DriveApi3::Drive::delete_drive' => {
    code    => 204,
    message => 'No Content',
    headers => ['content-type', 'text/html'],
    content => '',
  },
  'Test::Google::RestApi::DriveApi3::Drive::delete_with_options' => {
    code    => 204,
    message => 'No Content',
    headers => ['content-type', 'text/html'],
    content => '',
  },
  'Test::Google::RestApi::DriveApi3::Drive::hide_drive' => {
    code    => 200,
    message => 'OK',
    headers => ['content-type', 'application/json; charset=UTF-8'],
    content => qq|{\n  "kind": "drive#drive",\n  "id": "drive123",\n  "name": "Test Shared Drive",\n  "hidden": true\n}\n|,
  },
  'Test::Google::RestApi::DriveApi3::Drive::unhide_drive' => {
    code    => 200,
    message => 'OK',
    headers => ['content-type', 'application/json; charset=UTF-8'],
    content => qq|{\n  "kind": "drive#drive",\n  "id": "drive123",\n  "name": "Test Shared Drive",\n  "hidden": false\n}\n|,
  },
);

my $fixed = 0;
for my $exchange (@exchanges) {
  my $source = $exchange->{source} or next;
  my $code = $exchange->{response}{code} || 0;
  if (($code == 404 || $code == 400) && $canned{$source}) {
    $exchange->{response} = $canned{$source};
    $fixed++;
  }
}

if ($fixed) {
  open my $fh, '>', $file or die "Cannot write $file: $!\n";
  for my $exchange (@exchanges) {
    print $fh Dump($exchange), "\n";
  }
  close $fh;
  print "Fixed $fixed exchange(s) in $file\n";
} else {
  print "No exchanges needed fixing in $file\n";
}
