use strict;
use warnings;
package MojoX::Renderer::Alloy::Velocity;
BEGIN {
  $MojoX::Renderer::Alloy::Velocity::AUTHORITY = 'cpan:AJGB';
}
BEGIN {
  $MojoX::Renderer::Alloy::Velocity::VERSION = '1.112200';
}
#ABSTRACT: Template::Alloy's Velocity renderer

use base 'MojoX::Renderer::Alloy';

use Template::Alloy qw( Velocity );

__PACKAGE__->attr('alloy');


sub _render {
    my ($self, $r, $c, $output, $options) = @_;

    my $input = $self->_get_input( $r, $c, $options )
        || return;

    my $alloy = $self->alloy;

    # Template::Alloy won't handle undefined strings
    $$output = '' unless defined $$output;
    $alloy->merge( $input,
        $self->_template_vars( $c ),
        $output,
    ) || do {
        my $e = $alloy->error;
        chomp $e;
        $c->render_exception( $e );

        return;
    };

    return 1;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

MojoX::Renderer::Alloy::Velocity - Template::Alloy's Velocity renderer

=head1 VERSION

version 1.112200

=head1 SYNOPSIS

Mojolicious

    $self->plugin( 'alloy_renderer',
        {
            syntax => 'Velocity',
        }
    );

Mojolicious::Lite

    plugin( 'alloy_renderer',
        {
            syntax => 'Velocity',
        }
    );

=head1 DESCRIPTION

    <a href="$h.url_for('about_us')">Hello!</a>

    #include('include.inc')

Use L<Template::Alloy::Velocity> for rendering.

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

