package Test::Unit::Setup;

use strict;
use warnings;

use parent 'ToolSet';

ToolSet->use_pragma('strict');
ToolSet->use_pragma('warnings');

ToolSet->no_pragma('autovivification');

ToolSet->export(
  'autodie'                =>  [],
  'Log::Log4perl'          => ':easy',
  'Type::Params'           => 'validate validate_named',
  'Types::Standard'        => 'Undef Defined Bool Str StrMatch Int ArrayRef HashRef Dict Object InstanceOf slurpy',
  'Types::Common::Numeric' => 'PositiveInt PositiveOrZeroInt',
  'YAML::Any'              => 'Dump',
  'Test::Most'             =>  '',
  'Test::Utils'            => ':all',
  'Test::Unit::Utils'      => ':all',
);

1;
