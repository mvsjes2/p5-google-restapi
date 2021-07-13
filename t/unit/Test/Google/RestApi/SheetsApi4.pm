package Test::Google::RestApi::SheetsApi4;

use Test::Most;
use Utils qw(:all);

use parent 'Test::Class';

sub class { 'Google::RestApi::SheetsApi4' }

sub startup : Tests(startup => 1) {
  my $self = shift;
  use_ok $self->class();
}

sub constructor : Tests(3) {
  my $self = shift;
  my $class = $self->class();
  can_ok $class, 'new';
  ok my $spreadsheets = $class->new(
    api => fake_rest_api(),
  ), '... and the constructor should succeed';
  isa_ok $spreadsheets, $class, '... and the object it returns';
}

1;
