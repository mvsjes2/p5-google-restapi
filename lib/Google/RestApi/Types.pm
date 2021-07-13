package Google::RestApi::Types;

# custom type constrants. see Type::Library.

use strict;
use warnings;

my @types = qw(ReadableDir ReadableFile);

use Exporter;
use Types::Standard qw(Str);
use Type::Library -base, -declare => @types;

our %EXPORT_TAGS = (all => \@types);

my $meta = __PACKAGE__->meta;

$meta->add_type(
    name    => 'ReadableDir',
    parent  => Str->where( '-d -r $_' ),
    message => sub { "Must point to a file system directory that's readable" },
);

$meta->add_type(
    name    => 'ReadableFile',
    parent  => Str->where( '-f -r $_' ),
    message => sub { "Must point to a file that's readable" },
);

1;
