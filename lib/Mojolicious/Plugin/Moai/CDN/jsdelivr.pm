package Mojolicious::Plugin::Moai::CDN::jsdelivr;

use Mojo::Base -base;
use Mojo::JSON::Pointer;
use Mojo::Path;
use Role::Tiny::With qw(with);

# https://data.jsdelivr.com/v1/package/npm/jquery@3.2.1
has api => sub { Mojo::URL->new('https://data.jsdelivr.com') };

# https://cdn.jsdelivr.net/npm/jquery@3.2.1/dist/jquery.min.js
has cdn  => sub { Mojo::URL->new('https://cdn.jsdelivr.net') };
has name => 'jsdelivr';

sub new {
  my $self = shift->SUPER::new(@_);
  $self->routes->get('/npm/<:library>@<#version>/*filepath',  {version => 'latest'})->name('cdn');
  $self->routes->get('/v1/package/npm/<:library>@<#version>', {version => 'latest'})->name('api');
  return $self;
}

sub parse_sri {
  my ($json) = @_;
  die $json->{message} if !!$json->{status};
  _walk($json->{'files'}, Mojo::Path->new(), my $hashset = {});
  return $hashset;
}

sub _walk {
  my ($files, $depth, $hashes) = @_;
  foreach my $file (@$files) {
    if (exists $file->{files} and $file->{type} eq 'directory') {
      _walk($file->{files}, $depth->clone->trailing_slash(1)->merge($file->{name}), $hashes);
    }
    else {
      $hashes->{$depth->clone->trailing_slash(1)->merge($file->{name})} = join '-', 'sha256', $file->{hash};
    }
  }
}

with 'Mojolicious::Plugin::Moai::CDN';

1;
