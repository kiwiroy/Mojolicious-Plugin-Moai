package Mojolicious::Plugin::Moai;
our $VERSION = '0.003';
# ABSTRACT: Mojolicious UI components using modern UI libraries

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin Moai => 'Bootstrap4';
    app->start;
    __DATA__
    @@ list.html.ep
    %= include 'moai/lib'
    %= include 'moai/table', items => \@items, columns => [qw( id name )]
    %= include 'moai/pager', current_page => 1, total_pages => 5

=head1 DESCRIPTION

This plugin provides some common UI components using a couple different
popular UI libraries.

These components are designed to integrate seamlessly with L<Yancy>,
L<Mojolicious::Plugin::DBIC>, and L<Mojolicious::Plugin::SQL>.

=head1 SUPPORTED LIBRARIES

These libraries are not included and the desired version should be added
to your layout templates. To add your library using a CDN, see
L</moai/lib>, below.

=head2 Bootstrap4

L<http://getbootstrap.com>

=head1 WIDGETS

Widgets are snippets that you can include in your templates using the
L<include helper|Mojolicious::Guides::Rendering/Partial templates>.

=head2 moai/pager

    <%= include 'moai/pager',
        current_page => param( 'page' ),
        total_pages => $total_pages,
    %>

A pagination control. Will display previous and next buttons along with
individual page buttons.

Also comes in a C<mini> variant in C<moai/pager/mini> that has just
previous/next buttons.

=head3 Stash

=over

=item current_page

The current page number. Defaults to the value of the C<page> parameter.

=item total_pages

The total number of pages. Required.

=item page_param

The name of the parameter to use for the current page. Defaults to C<page>.

=back

=head2 moai/table

    <%= include 'moai/table',
        items => [
            { id => 1, name => 'Doug' },
        ],
        columns => [
            { key => 'id', title => 'ID' },
            { key => 'name', title => 'Name' },
        ],
    %>

A table of items.

=head3 Stash

=over

=item items

The items to display in the table. An arrayref of hashrefs.

=item columns

The columns to display, in order. An arrayref of hashrefs with the following
keys:

=over

=item key

The hash key in the item to use.

=item title

The text to display in the column heading

=back

=item class

A hashref of additional classes to add to certain elements:

=over

=item * C<table>

=item * C<thead>

=item * C<wrapper> - Add a wrapper element with these classes

=back

=back

=head2 moai/lib

    %= include 'moai/lib', version => '4.1.0';

Add the required stylesheet and JavaScript links for the current library
using a CDN. The stylesheets and JavaScript can be added separately
using C<moai/lib/stylesheet> and C<moai/lib/javascript> respectively.

=head3 Stash

=over

=item version

The specific version of the library to use. Required.

=back

=head1 TODO

=over

=item Security

The CDN links should have full security hashes.

=item Accessibility Testing

Accessibility testing should be automated and applied to all supported
libraries.

=item Internationalization

This library should use Mojolicious's C<variant> feature to provide
translations for every widget in every library.

=item Add more widgets

There should be widgets for...

=over

=item * menus (vertical lists, horizontal navbars, dropdown buttons)

=item * switched panels (tabs, accordion, slider)

=item * alerts (error, warning, info)

=item * menus (dropdown button, menu bar)

=item * popups (modal dialogs, tooltips, notifications)

=item * grid (maybe...)

=back

=item Add more libraries

There should be support for...

=over

=item * Bootstrap 3

=item * Bulma

=item * Material

=back

Moai should support the same features for each library, allowing easy
switching between them.

=item Add progressive enhancement

Some examples of progressive enhancement:

=over

=item * The table widget could have sortable columns

=item * The table widget could use AJAX to to filter and paginate

=item * The pager widget could use AJAX to update a linked element

=item * The switched panel widgets could load their content lazily

=back

=item Themes

Built-in selection of CDN-based themes for each library

=item Layouts

A customizable layout with good defaults.

=item Extra Classes

A standard way of adding extra classes to individual tags inside components. In addition
to a string, we should also support a subref so that loops can apply classes to certain
elements based on input criteria.

=item Documentation Sheet

Each supported library should come with a single page that demonstrates the various
widgets and provides copy/paste code snippets to achieve that widget.

It would be amazing if there was a way to make one template apply to all
supported libraries.

=back

=head1 SEE ALSO

L<Mojolicious::Guides::Rendering>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::File qw( path );

sub register {
    my ( $self, $app, $conf ) = @_;
    my $library = $conf->[0];
    $conf = $conf->[1] || {};
    my $libdir = path( __FILE__ )->sibling( 'Moai' )->child( 'resources', lc $library );
    push @{$app->renderer->paths}, $libdir->child( 'templates' );
    return;
}

1;
