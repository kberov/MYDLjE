use strict;
use warnings;
package MojoX::Renderer::Alloy::TT;
BEGIN {
  $MojoX::Renderer::Alloy::TT::AUTHORITY = 'cpan:AJGB';
}
BEGIN {
  $MojoX::Renderer::Alloy::TT::VERSION = '1.103450';
}
#ABSTRACT: Template::Alloy's Template-Toolkit renderer

use base 'MojoX::Renderer::Alloy';

use Template::Alloy qw( TT );
use File::Spec ();

__PACKAGE__->attr('alloy');



sub _render {
    my ($self, $r, $c, $output, $options) = @_;

    my $input = $self->_get_input( $r, $c, $options )
        || return;

    my $alloy = $self->alloy;

    $alloy->process( $input,
        {
            %{ $c->stash },
            c => $c,
        },
        $output,
        { binmode => ':utf8' },
    ) || do {
        my $e = $alloy->error;
        chomp $e;
        $c->render_exception( $e );
    };
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

MojoX::Renderer::Alloy::TT - Template::Alloy's Template-Toolkit renderer

=head1 VERSION

version 1.103450

=head1 SYNOPSIS

Mojolicious

    $self->plugin( 'alloy_renderer' );

Mojolicious::Lite

    plugin( 'alloy_renderer' );

=head1 DESCRIPTION

    <a href="[% c.url_for('about_us') %]">Hello!</a>

    [% INCLUDE "include.inc" %]

Use L<Template::Alloy::TT> for rendering.

Please see L<Mojolicious::Plugin::AlloyRenderer> for configuration options.

=head1 SEE ALSO

=over 4

=item *

L<MojoX::Renderer::Alloy>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

