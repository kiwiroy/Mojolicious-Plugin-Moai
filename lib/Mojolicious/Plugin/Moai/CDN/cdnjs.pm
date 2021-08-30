package Mojolicious::Plugin::Moai::CDN::cdnjs;

use Mojo::Base -base;
use Mojo::JSON::Pointer;
use Role::Tiny::With qw(with);

# https://api.cdnjs.com/libraries/twitter-bootstrap/4.6.0?fields=sri
has api => sub { Mojo::URL->new('https://api.cdnjs.com') };

# https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.6.0/js/bootstrap.bundle.min.js
has cdn  => sub { Mojo::URL->new('https://cdnjs.cloudflare.com') };
has name => 'cdnjs';

sub new {
  my $self = shift->SUPER::new(@_);
  $self->routes->get('/ajax/libs/:library/#version/*filepath', {version => 'latest'})->name('cdn');
  $self->routes->get('/libraries/:library/#version',           {fields  => 'sri', version => 'latest'})->name('api');
  return $self;
}

sub parse_sri {
  my ($json) = @_;
  die $json->{message} if !!$json->{error};
  return $json->{'sri'};
}

with 'Mojolicious::Plugin::Moai::CDN';

1;
