package MojoX::Session;

use strict;
use warnings;

our $VERSION = '0.23';

use base 'Mojo::Base';

use Mojo::Loader;
use Mojo::ByteStream;
use Mojo::Transaction::HTTP;
use MojoX::Session::Transport::Cookie;
use Digest::SHA1;

my $PRIVATE_IP_FIELD = 'mojox.session.ip_address';

__PACKAGE__->attr(loader => sub { Mojo::Loader->new });
__PACKAGE__->attr(tx     => sub { Mojo::Transaction::HTTP->new });
__PACKAGE__->attr([qw/sid _store/]);
__PACKAGE__->attr(_transport => sub { MojoX::Session::Transport::Cookie->new }
);

__PACKAGE__->attr(ip_match      => 0);
__PACKAGE__->attr(expires_delta => 3600);

__PACKAGE__->attr(_is_new     => 0);
__PACKAGE__->attr(_is_stored  => 0);
__PACKAGE__->attr(_is_flushed => 1);

__PACKAGE__->attr(_expires => 0);
__PACKAGE__->attr(_data => sub { {} });

__PACKAGE__->attr('error');

sub new {
    my $class = shift;
    my %args  = @_;

    my $store     = delete $args{store};
    my $transport = delete $args{transport};

    my $self = $class->SUPER::new(%args);

    $self->_store($self->_instance(Store => $store));
    $self->_transport($self->_instance(Transport => $transport));

    return $self;
}

sub store {
    my $self = shift;

    return $self->_store if @_ == 0;

    $self->_store($self->_instance(Store => shift));
}

sub transport {
    my $self = shift;

    return $self->_transport if @_ == 0;

    $self->_transport($self->_instance(Transport => shift));
}

sub _load_and_build {
    my $self = shift;
    my ($namespace, $name, $args) = @_;

    my $class = join('::',
        __PACKAGE__, $namespace, Mojo::ByteStream->new($name)->camelize);

    my $rv = $self->loader->load($class);

    if (defined $rv) {
        die qq/Store "$class" can not be loaded : $rv/ if ref $rv;

        die qq/Store "$class" not found/;
    }

    return $class->new(%{$args || {}});
}

sub _instance {
    my $self = shift;
    my ($namespace, $instance) = @_;

    return unless $instance;

    if (ref $instance eq 'HASH') {
        die 'HASH';

        #$store
    }
    elsif (ref $instance eq 'ARRAY') {
        $instance =
          $self->_load_and_build($namespace, $instance->[0], $instance->[1]);
    }
    elsif (!ref $instance) {
        $instance = $self->_load_and_build($namespace, $instance);
    }

    return $instance;
}

sub create {
    my $self = shift;
    my ($cb) = @_;

    $self->_expires(time + $self->expires_delta);

    $self->_is_new(1);

    if ($self->ip_match) {
        $self->data($PRIVATE_IP_FIELD, $self->_remote_addr);
    }

    $self->_generate_sid;

    if ($self->transport) {
        $self->transport->tx($self->tx);
        $self->transport->set($self->sid, $self->expires);
    }

    $self->_is_flushed(0);

    return $cb->($self, $self->sid) if $cb;

    return $self->sid;
}

sub load {
    my $self = shift;
    my ($sid, $cb) = @_;

    ($cb, $sid) = ($sid, undef) if ref $sid eq 'CODE';

    $self->sid(undef);
    $self->_expires(0);
    $self->_data({});

    if ($self->transport) {
        $self->transport->tx($self->tx);
    }

    unless ($sid) {
        $sid = $self->transport->get;
        return $cb ? $cb->($self) : undef unless $sid;
    }

    if ($self->store->is_async) {
        $self->store->load(
            $sid => sub {
                my ($store, $expires, $data) = @_;

                if ($store->error) {
                    $self->error($store->error);
                    return $cb ? $cb->($self) : undef;
                }

                my $sid = $self->_on_load($sid, $expires, $data);

                return $cb->($self, $sid) if $cb;

                return $sid;
            }
        );
    }
    else {
        my ($expires, $data) = $self->store->load($sid);

        return $self->error($self->store->error) && undef
          if $self->store->error;

        my $sid = $self->_on_load($sid, $expires, $data);

        return unless $sid;

        return $sid;
    }
}

sub _on_load {
    my $self = shift;
    my ($sid, $expires, $data) = @_;

    unless (defined $expires && defined $data) {
        $self->transport->set($sid, time - 30 * 24 * 3600)
          if $self->transport;
        return;
    }

    $self->_expires($expires);
    $self->_data($data);

    if ($self->ip_match) {
        return unless $self->_remote_addr;

        return unless $self->data($PRIVATE_IP_FIELD);

        return unless $self->_remote_addr eq $self->data($PRIVATE_IP_FIELD);
    }

    $self->sid($sid);

    $self->_is_stored(1);

    return $self->sid;
}

sub flush {
    my $self = shift;
    my ($cb) = @_;

    return $cb ? $cb->($self) : 1 unless $self->sid && !$self->_is_flushed;

    if ($self->is_expired && $self->_is_stored) {
        if ($self->store->is_async) {

            $self->store->delete(
                $self->sid => sub {
                    my ($store) = @_;

                    if (my $error = $store->error) {
                        $self->error($error);
                        return $cb ? $cb->($self) : undef;
                    }

                    $self->_is_stored(0);
                    $self->_is_flushed(1);

                    return $cb->($self) if $cb;

                    return 1;
                }
            );
        }
        else {
            my $ok = $self->store->delete($self->sid);
            $self->_is_stored(0);
            $self->_is_flushed(1);
            return $ok;
        }
    }
    else {
        my $ok = 1;

        my $action = $self->_is_new ? 'create' : 'update';

        $self->_is_new(0);

        if ($self->store->is_async) {
            $self->store->$action(
                $self->sid,
                $self->expires,
                $self->data => sub {
                    my ($store) = @_;

                    if ($store->error) {
                        $self->error($store->error);
                        return $cb ? $cb->($self) : undef;
                    }

                    $self->_is_stored(1);
                    $self->_is_flushed(1);

                    return $cb ? $cb->($self) : 1;
                }
            );
        }
        else {
            $ok =
              $self->store->$action($self->sid, $self->expires, $self->data);

            unless ($ok) {
                $self->error($self->store->error);
                return;
            }

            $self->_is_stored(1);
            $self->_is_flushed(1);

            return $ok;
        }
    }
}

sub data {
    my $self = shift;

    if (@_ == 0) {
        return $self->_data;
    }

    if (@_ == 1) {
        return $self->_data->{$_[0]};
    }

    my %params = @_;

    $self->_data({%{$self->_data}, %params});
    $self->_is_flushed(0);
}

sub flash {
    my $self = shift;
    my ($key) = @_;

    return unless $key;

    $self->_is_flushed(0);

    return delete $self->data->{$key};
}

sub clear {
    my $self = shift;
    my ($key) = @_;

    if ($key) {
        delete $self->_data->{$key};
    }
    else {
        $self->_data({});
    }

    $self->_is_flushed(0);
}

sub expire {
    my $self = shift;

    $self->expires(0);

    if ($self->transport) {
        $self->transport->tx($self->tx);
        $self->transport->set($self->sid, $self->expires);
    }

    return $self;
}

sub expires {
    my $self = shift;
    my ($val) = @_;

    if (defined $val) {
        $self->_expires($val);
        $self->_is_flushed(0);
    }

    return $self->_expires;
}

sub extend_expires {
    my $self = shift;

    $self->_expires(time + $self->expires_delta);

    if ($self->transport) {
        $self->transport->tx($self->tx);
        $self->transport->set($self->sid, $self->expires);
    }

    $self->_is_flushed(0);
}

sub is_expired {
    my ($self) = shift;

    return time > $self->expires ? 1 : 0;
}

sub _remote_addr {
    my $self = shift;

    return $self->tx->remote_address;
}

sub _generate_sid {
    my $self = shift;

    # based on CGI::Session::ID
    my $sha1 = Digest::SHA1->new;
    $sha1->add($$, time, rand(time));
    $self->sid($sha1->hexdigest);
}

1;
__END__

=head1 NAME

MojoX::Session - Session management for Mojo

=head1 SYNOPSIS

    my $session = MojoX::Session->new(
        tx        => $tx,
        store     => MojoX::Session::Store::Dbi->new(dbh  => $dbh),
        transport => MojoX::Session::Transport::Cookie->new,
        ip_match  => 1
    );

    # or
    my $session = MojoX::Session->new(
        tx        => $tx,
        store     => [dbi => {dbh => $dbh}],  # use MojoX::Session::Store::Dbi
        transport => 'cookie',                # this is by default
        ip_match  => 1
    );

    $session->create; # creates new session
    $session->load;   # tries to find session

    $session->sid; # session id

    $session->data('foo' => 'bar'); # set foo to bar
    $session->data('foo'); # get foo value

    $session->data('foo' => undef); # works
    $session->clear('foo'); # delete foo from data

    $session->flush; # writes session to the store

=head1 DESCRIPTION

L<MojoX::Session> is a session management for L<Mojo>. Based on L<CGI::Session>
and L<HTTP::Session> but without any dependencies except the core ones.

=head1 ATTRIBUTES

L<MojoX::Session> implements the following attributes.

=head2 C<tx>

    Mojo::Transaction object

    my $tx = $session->tx;
    $tx    = $session->tx(Mojo::Transaction->new);

=head2 C<store>

    Store object

    my $store = $session->store;
    $session  = $session->store(MojoX::Session::Store::Dbi->new(dbh => $dbh));
    $session  = $session->store(dbi => {dbh => $dbh});

=head2 C<transport>

    Transport to find and store session id

    my $transport = $session->transport;
    $session
        = $session->transport(MojoX::Session::Transport::Cookie->new);
    $session = $session->transport('cookie'); # by default

=head2 C<ip_match>

    Check if ip matches, default is 0

    my $ip_match = $session->ip_match;
    $ip_match    = $session->ip_match(0);

=head2 C<expires_delta>

    Seconds until session is considered expired

    my $expires_delta = $session->expires_delta;
    $expires_delta    = $session->expires_delta(3600);

=head1 METHODS

L<MojoX::Session> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 C<new>

    my $session = MojoX::Session->new(...);

    Returns new L<MojoX::Session> object.

=head2 C<create>

    my $sid = $session->create;
    $session->flush;

Creates new session. Puts sid into the transport. Call flush if you want to
store it.

=head2 C<load>

    $session->load;
    $session->load($sid);

Tries to load session from the store, gets sid from transport unless it is
provided. If sesssion is expired it will loaded also.

=head2 C<flush>

    $session->flush;

Flush actually writes to the store in these situations:
- new session was created (inserts it);
- any value was changed (updates it)
- session is expired (deletes it)

Returns the value from the corresponding store method call.

=head2 C<sid>

    my $sid = $session->sid;

Returns session id.

=head2 C<data>

    my $foo = $session->data('foo');
    $session->data('foo' => 'bar');
    $session->data('foo' => 'bar', 'bar' => 'foo');
    $session->data('foo' => undef);

    # or
    my $foo = $session->data->{foo};
    $session->data->{foo} = 'bar';

Get and set values to the session.

=head2 C<flash>

    my $foo = $session->data('foo');
    $session->data('foo' => 'bar');
    $session->flash('foo'); # get foo and delete it from data
    $session->data('foo');  # undef

Get value and delete it from data. Usefull when you want to store error messages
etc.

=head2 C<clear>

    $session->clear('bar');
    $session->clear;
    $session->flush;

Clear session values. Delete only one value if argument is provided.  Call flush
if you want to clear it in the store.

=head2 C<expires>

    $session->expires;
    $session->expires(123456789);

Get/set session expire time.

=head2 C<expire>

    $session->expire;
    $session->flush;

Force session to expire. Call flush if you want to remove it from the store.

=head2 C<is_expired>

Check if session is expired.

=head2 C<extend_expires>

Entend session expires time. Set it to current_time + expires_delta.

=head1 SEE ALSO

L<CGI::Session>, L<HTTP::Session>

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 CREDITS

Daniel Mascarenhas

David Davis

Maxim Vuets

Sergey Zasenko

William Ono

Yaroslav Korshak

=head1 COPYRIGHT

Copyright (C) 2008-2010, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
