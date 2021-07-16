package Test::Mock::Drive;

use strict;
use warnings;

use Test::MockObject::Extends;
use Test::Unit::Setup;
 
use aliased 'Google::RestApi::DriveApi3';

sub new {
  my $self = DriveApi3->new(api => fake_rest_api());
  $self = Test::MockObject::Extends->new($self);
  $self->mock('filter_files', sub { 'aaa: bbb'; });
  return $self;
}

1;
