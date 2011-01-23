use strict;
use warnings;
package MojoX::Renderer::Alloy;
BEGIN {
  $MojoX::Renderer::Alloy::AUTHORITY = 'cpan:AJGB';
}
BEGIN {
  $MojoX::Renderer::Alloy::VERSION = '1.103450';
}
#ABSTRACT: Base class for Template::Alloy renderer

use base 'Mojo::Base';



sub build {
    my $self = shift->SUPER::new(@_);

    die "Abstract class cannot be built"
        if ref $self eq __PACKAGE__;

    $self->_init(@_);

    return sub { $self->_render(@_) };
};

sub _init {
    my $self = shift;

    $self->alloy(
        Template::Alloy->new( $self->_default_config(@_) )
    );
}

sub _default_config {
    my ($self, %args) = @_;

    my $app = delete $args{app} || delete $args{mojo};

    my $compile_dir = defined $app && $app->home->rel_dir('tmp/ctpl');
    my $inc_path  = defined $app && $app->home->rel_dir('templates');

    return (
        (
            $inc_path ?
            (
                INCLUDE_PATH => $inc_path
            ) : ()
        ),
        COMPILE_EXT => '.ct',
        COMPILE_DIR => ( $compile_dir || File::Spec->tmpdir ),
        UNICODE     => 1,
        ENCODING    => 'utf-8',
        CACHE_SIZE  => 128,
        RELATIVE    => 1,
        ABSOLUTE    => 1,
        %{ $args{template_options} || {} },
    );
}

sub _get_input {
    my ( $self, $r, $c, $options ) = @_;

    my $inline = $options->{inline};

    my $tname = $r->template_name($options);
    my $path = $r->template_path($options);

    $path = \$inline if defined $inline;

    return unless defined $path && defined $tname;

    return ref $path ? $path # inline
        : -r $path ?
            $path # regular file
            :
            do { # inlined templates are not supported
                if ( $r->get_inline_template($options, $tname) ) {
                    $c->render_exception(
                        "Inlined templates are not supported"
                    );
                } else {
                    $c->render_not_found( $tname );
                }
                return;
            };
};

1;

__END__
=pod

=encoding utf-8

=head1 NAME

MojoX::Renderer::Alloy - Base class for Template::Alloy renderer

=head1 VERSION

version 1.103450

=head1 SYNOPSIS

Base abstract class for following renderers:

=over

=item * L<MojoX::Renderer::Alloy::TT>

=item * L<MojoX::Renderer::Alloy::Velocity>

=item * L<MojoX::Renderer::Alloy::Tmpl>

=item * L<MojoX::Renderer::Alloy::HTE>

=back

=head1 METHODS

=head2 build

Build handler for selected renderer.

Please note that for all renderers a L<Mojolicious::Controller> is available as C<c> variable.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

