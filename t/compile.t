use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use File::Find;
use Test::More;

my @modules;
my $lib = "$FindBin::RealBin/../lib";
find(
  sub {
    return unless /\.pm$/;
    my $module = $File::Find::name;
    $module =~ s{^\Q$lib\E/}{};
    $module =~ s{/}{::}g;
    $module =~ s{\.pm$}{};
    push @modules, $module;
  },
  $lib,
);

plan tests => scalar @modules;

for my $module (sort @modules) {
  use_ok($module);
}
