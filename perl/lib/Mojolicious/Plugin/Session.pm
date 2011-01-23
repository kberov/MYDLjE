package Mojolicious::Plugin::Session;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use MojoX::Session;

sub register {
    my ($self, $app, $args) = @_;

    $args ||= {};

    my $stash_key = delete $args->{stash_key} || 'mojox-session';
    my $init      = delete $args->{init};

    $app->plugins->add_hook(
        before_dispatch => sub {
            my ($self, $c) = @_;

            my $session = MojoX::Session->new(%$args);

            $session->tx($c->tx);

            $init->($c, $session) if $init;

            $c->stash($stash_key => $session);
        }
    );

    $app->plugins->add_hook(
        after_dispatch => sub {
            my ($self, $c) = @_;

            $c->stash($stash_key)->flush;
        }
    );
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Session - Session plugin for Mojolicious

=head1 SYNOPSIS

    # Mojolicious::Lite
    plugin session =>
      {stash_key => 'mojox-session', store => 'dbi', expires_delta => 5};

    # Mojolicious
    $self->plugin(
        session => {
            stash_key     => 'mojox-session',
            store         => 'dbi',
            expires_delta => 5
        }
    );

=head1 DESCRIPTION

Embedded L<Mojo> sessions are recommended for using instead of this module.

L<Mojolicious::Plugin::Session> is a session plugin for L<Mojolicious>. It
creates L<MojoX::Session> instance with provided parameters, passes $tx object
before dispatch method is called and calls flush just after dispatching.
L<MojoX::Session> instance is placed in the stash.

=head1 ATTRIBUTES

L<Mojolicious::Plugin::Session> accepts all the attributes accepted by
L<MojoX::Session> and implements the following.

=head2 C<stash_key>

    MojoX::Session instance will be saved in stash using this key.

=head1 SEE ALSO

L<MojoX::Session>

L<Mojolicious>

=cut
