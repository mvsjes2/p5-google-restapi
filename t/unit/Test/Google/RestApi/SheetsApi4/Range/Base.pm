package Test::Google::RestApi::SheetsApi4::Range::Base;

use Test::Unit::Setup;

use parent 'Test::Unit::TestBase';

use Scalar::Util qw(looks_like_number);

sub startup {
  my $self = shift;
  $self->SUPER::startup(@_);
  return;
}

sub setup {
  my $self = shift;
  $self->SUPER::setup(@_);
  $self->{err} = qr/Unable to translate/;
  $self->{name} = "'Sheet1'!";
  $self->_fake_http_auth();
  $self->_fake_http_no_retries();
  $self->_uri_responses(qw(
    get_worksheet_properties_title_sheetid
    get_worksheet_values_row
  ));
  $self->_fake_http_response_by_uri();
  return;
}

sub _to_str {
  my $self = shift;
  my $x = shift;
  return 'undef' if !defined $x;
  return $x if looks_like_number($x);
  return "'$x'";
}

sub new_range {
  my $self = shift;
  return $self->class()->new(worksheet => fake_worksheet(), range => shift);
}

1;
