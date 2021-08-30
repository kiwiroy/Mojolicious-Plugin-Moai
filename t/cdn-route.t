use Test::More;
use Test::Mojo;
use Mojo::URL;
use Mojolicious::Controller;
use Mojolicious::Routes::Match;
use Mojolicious::Plugin::Moai::CDN::cdnjs;
use Mojolicious::Plugin::Moai::CDN::jsdelivr;
use Mojolicious::Plugin::Moai::CDN::unpkg;

subtest cdnjs => sub {
  my $cdn = Mojolicious::Plugin::Moai::CDN::cdnjs->new;
  is $cdn->resource_url('twitter-bootstrap' => '5.0.0' => 'js/bootstrap.bundle.min.js'),
    'https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/5.0.0/js/bootstrap.bundle.min.js', 'correct version';
  is $cdn->resource_url('twitter-bootstrap' => undef, 'js/bootstrap.bundle.min.js'),
    'https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/latest/js/bootstrap.bundle.min.js', 'latest';

  $cdn->resource_integrity_p('twitter-bootstrap' => '4.6.0', 'js/bootstrap.bundle.min.js', my $hashes = {})->wait;
  foreach my $url (keys %$hashes) {
    like $hashes->{$url}, qr/^sha(?:256|384|512)/;
    is +Mojo::URL->new($url)->host, 'cdnjs.cloudflare.com', 'correct host';
  }
};

subtest jsdelivr => sub {
  my $cdn = Mojolicious::Plugin::Moai::CDN::jsdelivr->new;
  is $cdn->resource_url(bootstrap => '5.0.0' => 'dist/js/bootstrap.bundle.min.js'),
    'https://cdn.jsdelivr.net/npm/bootstrap@5.0.0/dist/js/bootstrap.bundle.min.js', 'versioned';
  is $cdn->resource_url(bootstrap => undef, 'dist/js/bootstrap.bundle.min.js'),
    'https://cdn.jsdelivr.net/npm/bootstrap@latest/dist/js/bootstrap.bundle.min.js', 'latest';

  $cdn->resource_integrity_p(bootstrap => '4.6.0', 'dist/js/bootstrap.bundle.min.js', my $hashes = {})->wait;
  foreach my $url (keys %$hashes) {
    like $hashes->{$url}, qr/^sha(?:256|384|512)/;
    is +Mojo::URL->new($url)->host, 'cdn.jsdelivr.net', 'correct host';
  }
};

subtest unpkg => sub {
  my $cdn = Mojolicious::Plugin::Moai::CDN::unpkg->new;
  is $cdn->resource_url(bootstrap => '5.0.0' => 'dist/js/bootstrap.bundle.min.js'),
    'https://unpkg.com/bootstrap@5.0.0/dist/js/bootstrap.bundle.min.js', 'versioned';
  is $cdn->resource_url(bootstrap => undef, 'dist/js/bootstrap.bundle.min.js'),
    'https://unpkg.com/bootstrap@latest/dist/js/bootstrap.bundle.min.js', 'latest';

  $cdn->resource_integrity_p(bootstrap => '4.6.0', 'dist/js/bootstrap.bundle.min.js', my $hashes = {})->wait;
  ok scalar(keys %$hashes);
  foreach my $url (keys %$hashes) {
    like $hashes->{$url}, qr/^sha(?:256|384|512)/;
    is +Mojo::URL->new($url)->host, 'unpkg.com', 'correct host';
  }
};

subtest promises => sub {
  my $caught = 0;
  my $cdn    = Mojolicious::Plugin::Moai::CDN::jsdelivr->new;
  $cdn->resource_integrity_p->catch(sub { $caught++; })->wait;
  ok $caught;
};

subtest dispatch => sub {
  my $cdn = Mojolicious::Plugin::Moai::CDN::cdnjs->new;
  ok $cdn->pick('//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/5.0.0/js/bootstrap.bundle.min.js');
  is_deeply $cdn->match->stack, [{
    'filepath' => 'js/bootstrap.bundle.min.js',
    'library'  => 'twitter-bootstrap',
    'version'  => '5.0.0',
  }];

  $cdn = Mojolicious::Plugin::Moai::CDN::jsdelivr->new;
  ok $cdn->pick('//cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/js/bootstrap.bundle.min.js');
  is_deeply $cdn->match->stack, [{
    'filepath' => 'dist/js/bootstrap.bundle.min.js',
    'library'  => 'bootstrap',
    'version'  => '4.6.0',
  }];

  $cdn = Mojolicious::Plugin::Moai::CDN::unpkg->new;
  ok $cdn->pick('//unpkg.com/bootstrap@4.6.0/dist/js/bootstrap.bundle.min.js');
  is_deeply $cdn->match->stack, [{
    'filepath' => 'dist/js/bootstrap.bundle.min.js',
    'library'  => 'bootstrap',
    'version'  => '4.6.0',
  }];
};


done_testing;
