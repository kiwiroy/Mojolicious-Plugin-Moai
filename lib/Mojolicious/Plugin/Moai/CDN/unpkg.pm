package Mojolicious::Plugin::Moai::CDN::unpkg;

use Mojo::Base -base;
use Mojo::JSON::Pointer;
use Role::Tiny::With qw(with);

# https://unpkg.com/bootstrap@4.6.0/?meta
has api => sub { Mojo::URL->new('https://unpkg.com') };

# https://unpkg.com/bootstrap@4.6.0/dist/js/bootstrap.bundle.min.js
has cdn  => sub { Mojo::URL->new('https://unpkg.com') };
has name => 'unpkg';

sub new {
  my $self = shift->SUPER::new(@_);
  $self->routes->get('/<:library>@<#version>/*filepath', {version => 'latest'})->name('cdn');
  $self->routes->get('/<:library>@<#version>/:force',    {version => 'latest', meta => 1})->name('api');
  return $self;
}

sub parse_sri {
  my ($json) = @_;
  die $json->{message} if !!$json->{status};
  _walk($json->{'files'}, my $hashset = {});
  return $hashset;
}

sub _walk {
  my ($files, $hashes) = @_;
  foreach my $file (@$files) {
    if (exists $file->{files} and $file->{type} eq 'directory') {
      _walk($file->{files}, $hashes);
    }
    else {
      $hashes->{$file->{path}} = $file->{integrity};
    }
  }
}


with 'Mojolicious::Plugin::Moai::CDN';

1;
