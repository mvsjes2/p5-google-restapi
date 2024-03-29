package Test::Tutorial::Setup;

use strict;
use warnings;

use parent 'ToolSet';

ToolSet->use_pragma('strict');
ToolSet->use_pragma('warnings');

ToolSet->no_pragma('autovivification');

ToolSet->export(
  'autodie'                =>  [],
  'Log::Log4perl'          => ':easy',
  'YAML::Any'              => 'Dump',
  'Test::Utils'            => ':all',
  'Test::Tutorial::Utils'  => ':all',
  'Try::Tiny'              =>  [],
);

1;
