package Test::Unit::Utils;

use strict;
use warnings;

use FindBin;
use aliased "Google::RestApi";

use Exporter qw(import);
our @EXPORT_OK = qw(
  fake_rest_api fake_config_file
  fake_token_file
  fake_json_response
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub fake_config_file { "$FindBin::RealBin/etc/rest_config.yaml"; }
sub fake_token_file { "$FindBin::RealBin/etc/rest_config.token"; }
sub fake_json_response { "$FindBin::RealBin/etc/json_response/" . shift . ".json"; }
sub fake_rest_api { RestApi->new(@_, config_file => fake_config_file()); }

1;
