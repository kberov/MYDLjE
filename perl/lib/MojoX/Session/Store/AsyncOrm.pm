package MojoX::Session::Store::AsyncOrm;

use strict;
use warnings;

use base 'MojoX::Session::Store';

use MIME::Base64;
use Storable qw/nfreeze thaw/;

__PACKAGE__->attr(is_async => 1);

__PACKAGE__->attr('dbh');
__PACKAGE__->attr('class');
__PACKAGE__->attr(sid_column => 'sid');
__PACKAGE__->attr(expires_column => 'expires');
__PACKAGE__->attr(data_column => 'data');

sub create {
    my ($self, $sid, $expires, $data, $cb) = @_;

    $data = encode_base64(nfreeze($data)) if $data;

    my $instance = $self->class->new;

    $instance->column($self->sid_column     => $sid);
    $instance->column($self->expires_column => $expires);
    $instance->column($self->data_column    => $data);

    $instance->create(
        $self->dbh => sub {
            my ($dbh, $instance, $error) = @_;

            if ($error) {
                $self->error($error);
                return $cb->($self);
            }

            return $cb->($self) unless $instance;

            return $cb->($self);
        }
    );
}

sub update {
    my ($self, $sid, $expires, $data, $cb) = @_;

    $data = encode_base64(nfreeze($data)) if $data;

    $self->class->update(
        $self->dbh => {
            where => [$self->sid_column => $sid],
            set   => {
                $self->expires_column => $expires,
                $self->data_column    => $data
            }
          } => sub {
            my ($dbh, $instance, $error) = @_;

            if ($error) {
                $self->error($error);
                return $cb->($self);
            }

            return $cb->($self) unless $instance;

            return $cb->($self);
        }
    );
}

sub load {
    my ($self, $sid, $cb) = @_;

    $self->class->new($self->sid_column => $sid)->load(
        $self->dbh => sub {
            my ($dbh, $instance, $error) = @_;

            if ($error) {
                $self->error($error);
                return $cb->($self);
            }

            return $cb->($self) unless $instance;

            my $data = $instance->column($self->data_column);

            $data = thaw(decode_base64($data)) if $data;

            return $cb->($self, $instance->column($self->expires_column),
                $data);
        }
    );
}

sub delete {
    my ($self, $sid, $cb) = @_;

    $self->class->delete(
        $self->dbh => {where => [$self->sid_column => $sid]} => sub {
            my ($dbh, $count, $error) = @_;

            if ($error) {
                $self->error($error);
                return $cb->($self);
            }

            return $cb->($self) unless $count;

            return $cb->($self, $count);
        }
    );
}

1;
