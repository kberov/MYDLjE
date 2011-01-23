package MojoX::Session::Store::Couchdb;

use strict;
use warnings;

use base 'MojoX::Session::Store';

use Mojo::Client;
use Mojo::JSON;

__PACKAGE__->attr(is_async => 1);

__PACKAGE__->attr(client => sub { Mojo::Client->singleton->async });
__PACKAGE__->attr(address  => 'localhost');
__PACKAGE__->attr(port     => '5984');
__PACKAGE__->attr(database => 'session');

# For internal use
__PACKAGE__->attr('_rev');

sub _build_url {
    my $self  = shift;
    my $path  = shift;
    my $query = shift;

    my $url = Mojo::URL->new;
    $url->scheme('http');
    $url->host($self->address);
    $url->port($self->port);
    $url->path('/' . $self->database . '/' . $path);
    $url->query(%$query) if $query;

    return $url;
}

sub _encode_json {
    my $self = shift;
    my $data = shift;

    my $json = Mojo::JSON->new;

    $data = $json->encode($data);
    unless ($data && !$json->error) {
        $self->error("Can't parse incoming data");
        return;
    }

    return $data;
}

sub _decode_json {
    my $self = shift;
    my $body = shift;

    my $json = Mojo::JSON->new;

    $body = $json->decode($body);

    unless ($body && !$json->error) {
        $self->error("Can't parse response");
        return;
    }

    return $body;
}

sub create {
    my ($self, $sid, $expires, $data, $cb) = @_;

    $self->error('');

    $data = $self->_encode_json({data => $data, expires => $expires});
    return $cb->($self) unless $data;

    my $url = $self->_build_url($sid);

    $self->client->put(
        $url => $data => sub {
            my ($client, $tx) = @_;

            if ($tx->has_error) {
                $self->error($tx->error);
                return $cb->($self);
            }

            unless ($tx->res->code == 201) {
                $self->error('Wrong response');
                return $cb->($self);
            }

            my $body = $self->_decode_json($tx->res->body);
            if ($body->{error}) {
                $self->error($body->{error});
                return $cb->($self);
            }

            $self->_rev($body->{_rev});

            return $cb->($self);
        }
    )->process;
}

sub update {
    my ($self, $sid, $expires, $data, $cb) = @_;

    $self->error('');

    $data =
      $self->_encode_json({data => $data, expires => $expires, _rev => $self->_rev});
    return $cb->($self) unless $data;

    my $url = $self->_build_url($sid);

    $self->client->put(
        $url => $data => sub {
            my ($client, $tx) = @_;

            if ($tx->error) {
                $self->error($tx->error);
                return $cb->($self);
            }

            unless ($tx->res->code == 201) {
                $self->error('Wrong response');
                return $cb->($self);
            }

            my $body = $self->_decode_json($tx->res->body);
            if ($body->{error}) {
                $self->error($body->{error});
                return $cb->($self);
            }

            $self->_rev($body->{_rev});

            return $cb->($self);
        }
    )->process;
}

sub load {
    my ($self, $sid, $cb) = @_;

    $self->error('');

    my $url = $self->_build_url($sid);

    $self->client->get(
        $url => sub {
            my ($client, $tx) = @_;

            if ($tx->error) {
                $self->error($tx->error);
                return $cb->($self);
            }

            # Session not found
            if ($tx->res->code == 404) {
                return $cb->($self);
            }

            # Wrong response status
            unless ($tx->res->code == 200) {
                $self->error('Wrong response');
                return $cb->($self);
            }

            my $body = $self->_decode_json($tx->res->body);

            # CouchDB internal id
            delete $body->{_id};

            # Needed for update and delete
            $self->_rev(delete $body->{_rev});

            my $expires = delete $body->{expires};

            return $cb->($self, $expires, $body->{data});
        }
    )->process;
}

sub delete {
    my ($self, $sid, $cb) = @_;

    $self->error('');

    my $url = $self->_build_url($sid, {rev => $self->_rev});

    $self->client->delete(
        $url => sub {
            my ($client, $tx) = @_;

            if ($tx->error) {
                $self->error($tx->error);
                return $cb->($self);
            }

            unless ($tx->res->code == 200) {
                $self->error('Wrong response');
                return $cb->($self);
            }

            my $body = $self->_decode_json($tx->res->body);
            return $cb->($self) unless $body;

            if ($body->{error}) {
                $self->error($body->{error});
                return $cb->($self);
            }

            return $cb->($self);
        }
    )->process;
}

1;
