
=head1 DESCRIPTION

This tests the CDN components

=cut

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojolicious;

subtest 'Bootstrap4' => \&test_lib, 'Bootstrap4',
    version => '4.6.0',
    css_min_name => 'bootstrap.min.css',
    js_min_name => 'bootstrap.bundle.min.js',
    js_prereqs => [qw( /jquery /popper.min.js )],
    ;

subtest 'Bulma' => \&test_lib, 'Bulma',
    version => '0.8.0',
    css_min_name => 'bulma.min.css',
    # Bulma does not have JavaScript
    ;

done_testing;

sub test_lib {
    my ( $lib, %attr ) = @_;
    my $app = Mojolicious->new;
    $app->plugin( Moai => [ $lib ] );
    $app->routes->get( '/*moai_x_template' )->to( cb => sub {
        my ( $c ) = @_;
        $c->stash( template => $c->param('moai_x_template') );
        $c->stash( map { $_ => $c->param( $_ ) } @{ $c->req->params->names } );
        $c->render;
    } );
    my $t = Test::Mojo->new( $app );

    $t->get_ok( '/moai/lib/stylesheet', form => { version => $attr{version} } )
      ->status_is( 200 )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->find( '#error,#routes,#log' )->join("\n") } )
      ;
    test_stylesheet( $t, %attr );

    if ( $attr{ js_min_name } ) {
        $t->get_ok( '/moai/lib/javascript', form => { version => $attr{version} } )
          ->status_is( 200 )
          ;
        test_javascript( $t, %attr );
    }

    $t->get_ok( '/moai/lib', form => { version => $attr{version} } )
      ->status_is( 200 )
      ;
    test_stylesheet( $t, %attr );
    if ( $attr{ js_min_name } ) {
        test_javascript( $t, %attr );
    }

    # Dies without known library version
    $t->get_ok( '/moai/lib' )
      ->status_is( 500 )
      ->content_like( qr/No Moai UI library version specified/ )
      ;

    # Test version config
    $app = Mojolicious->new;
    $app->plugin( Moai => [ $lib, { version => $attr{version} } ] );
    $app->routes->get( '/*moai_x_template' )->to( cb => sub {
        my ( $c ) = @_;
        $c->stash( template => $c->param('moai_x_template') );
        $c->stash( map { $_ => $c->param( $_ ) } @{ $c->req->params->names } );
        $c->render;
    } );
    $t = Test::Mojo->new( $app );
    $t->get_ok( '/moai/lib' )
      ->status_is( 200 )
      ;
    test_stylesheet( $t, %attr );
    if ( $attr{ js_min_name } ) {
        test_javascript( $t, %attr );
    }

}

sub test_javascript {
    my ( $t, %attr ) = @_;
    $t->element_exists( 'script', 'at least one script exists' )
      ->element_exists_not( 'script[src^=http]', 'no protocol in front of the src' )
      ->element_exists( "script[src\$=/$attr{js_min_name}]", 'javascript is loaded' )
      ->element_exists( "script[src*=$attr{version}]", 'version is in URL' )
      ;
    for my $prereq ( @{ $attr{ js_prereqs } } ) {
        $t->element_exists( "script[src*=$prereq]", "prereq $prereq is loaded" )
    }
}

sub test_stylesheet {
    my ( $t, %attr ) = @_;
    $t->element_exists( 'link[rel=stylesheet]', 'stylesheet exists' )
      ->element_exists( 'link[href^=//]', 'no protocol in front of the link' )
      ->or( sub { diag shift->tx->res->dom->find( 'link' )->map( 'to_string' )->each } )
      ->element_exists( "link[href\$=/$attr{css_min_name}]", 'use minified library' )
      ->element_exists( "link[href*=$attr{version}]", 'version is in URL' )
      ->or( sub { diag shift->tx->res->dom->find( 'link' )->map( 'to_string' )->each } )
      ;
}
