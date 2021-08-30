package Mojolicious::Plugin::Moai::CDN;

# ABSTRACT: Mojolicious::Plugin::Moai::CDN - A role for Content Delivery Network (CDN)

=head1 SYNOPSIS

Compose

  package Mojolicious::Plugin::Moai::CDN::service;
  use Mojo::Base -base;
  use Role::Tiny::With qw(with);
  has [qw(api cdn name)]; # implement
  with 'Mojolicious::Plugin::Moai::CDN';

Use

  $srihashes = {};
  $cdn = Mojolicious::Plugin::Moai::CDN::service->new;
  if ($cdn->pick($url)) {
    my $data = $cdn->match->stack->[$cdn->match->position];
    $cdn->resource_integrity(@$data{qw(library version filepath)}, $srihashes);
  }

=head1 DESCRIPTION

L<Mojolicious::Plugin::Moai::CDN> is a role to help provide a constant interface between L<Mojolicious::Plugin::Moai>
and individual content delivery network implementations.

=head1 ATTRIBUTES

L<Mojolicious::Plugin::Moai::CDN> composes the following attriutes.

=head2 match

  # Mojolicious::Routes::Match
  $cdn->match;

A L<Mojolicious::Routes::Match> object to use with L</"pick">.

=head2 routes

  # Mojolicious::Routes
  $cdn->routes;

A L<Mojolicious::Routes> object to store the routes for the CDN. As routes are paths only, with placeholders, the
absolute url must be used to obtain the URI of the CDN resource.

This L<routes|Mojolicious::Routes> object should be populated on instantiation of the CDN object with the following two
B<named> routes. The first is the API route that is for the L</"api"> base url and needs to be named C<'api'>. The
second is the route for content delivery of library files, a path under the L</"cdn"> base url, and needs to be named
C<'cdn'>.

=head2 ua

  # Mojo::UserAgent
  $cdn->ua;

A L<Mojo::UserAgent> to make requests to the L</"api"> url during L</"resource_integrity"> discovery.

=head1 METHODS

L<Mojolicious::Plugin::Moai::CDN> composes the following methods.

=head2 pick

  # 1
  $cdn->pick($url);
  $cdn->pick('https://cdn.service.com/libs/bootstrap/5.0/js/bootstrap.min.js');

Return a Boolean indicating whether the C<$url> is a resource under control of the composed CDN.

=head2 resource_integrity

  # $hashes is populated
  $cdn->resource_integrity($library_name, $version, $filepath, $hashes);

Obtain the subresource integrity hashes for the C<$filepath> from the C<$version> of library C<$library_name>. Some CDN
L<API|/"api"> provide the hashes for all files from a single request. In this case all of the files in the library will
be added to the C<$hashes> storage (this should be a hash reference).

=head2 resource_integrity_p

  # $hashes is populated
  $cdn->resource_integrity_p($library_name, $version, $filepath, $hashes)->wait;

A version of L</"resource_integrity"> that returns a L<Mojo::Promise>.

=head2 resource_url

  # Mojo::URL
  $url = $cdn->resource_url($library_name, $version, $filepath);
  # https://cdn.service.com/libs/bootstrap/5.0/js/bootstrap.min.js
  $cdn->resource_url('bootstrap', '5.0', 'js/bootstrap.min.js');

Translate the C<$library_name>, C<$version> and  C<$filepath> of a resource into an absolute C<$url> for the composed
CDN.

=head1 REQUIRED METHODS

The following methods are required for successful composition of this role using L<Role::Tiny>.

=head2 api

This attribute or method should return the base URL for the API of the CDN.

=head2 cdn

This attribute or method should return the base URL for the CDN.

=head2 name

This attribute or method should return the name for the CDN.

=cut

use Mojo::Base -role;
use Mojo::UserAgent;
use Mojolicious::Routes;
use Mojolicious::Routes::Match;

requires qw(api cdn name);

has match  => sub { Mojolicious::Routes::Match->new(root => shift->routes) };
has routes => sub { Mojolicious::Routes->new };
has ua     => sub { Mojo::UserAgent->new };

sub pick {
  my ($self, $url) = @_;
  $url = Mojo::URL->new($url);
  return undef unless $url->host eq $self->cdn->host;
  my $match = $self->match;
  my $c     = Mojolicious::Controller->new;
  return $match->find($c, {method => 'GET', path => $url->path});
}

sub resource_integrity_p {
  my ($self, $library, $version, $path, $all) = @_;
  return Mojo::Promise->reject("No version specified") unless $version;
  my $parse_sri = $self->can('parse_sri');
  return Mojo::Promise->reject("No method to parse API response") unless $parse_sri;
  my $url = $self->_url_for(api => {library => $library, version => $version, filepath => $path})->to_abs($self->api);
  $self->ua->get_p($url)->then(sub {

    # extract json
    return shift->res->json;
  })->then($parse_sri)->then(sub {
    my $data = shift;
    foreach my $filepath (keys %$data) {
      my $hash = $data->{$filepath};
      my $url  = $self->resource_url($library, $version, $filepath);
      $all->{$url} = $hash;
      $all->{$url->scheme(undef)} = $hash;
    }
    return $all;
  })->catch(sub { my $e = shift; warn $e; });
}

sub resource_integrity {
  shift->resource_integrity_p(@_)->catch(sub { warn shift })->wait;
}

sub resource_url {
  my ($self, $library, $version, $path) = @_;
  $self->_url_for(cdn => {library => $library, version => $version, filepath => $path})->to_abs($self->cdn);
}

sub _url_for {
  my ($self, $target, $pattern) = @_;
  my $match = $self->match;
  my $url   = Mojo::URL->new;
  my $path  = $url->path;
  my $route = $self->routes->lookup($target);
  my $gen   = $match->path_for($route->name, $pattern);
  $path->parse($gen->{path}) if $gen->{path};
  my %defaults = %{$route->pattern->defaults // {}};    # copy
  delete @defaults{qw{library version filepath}};
  $url->query(\%defaults);
  return $url;
}

1;

__END__
