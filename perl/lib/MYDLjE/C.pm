package MYDLjE::C;

#Base class for our controllers

use strict;
use warnings FATAL => qw( all );
use Mojo::Base 'Mojolicious::Controller';

# Say hello
sub hi {
    my $c = shift;
    $c->render(text => 'Hi!');
}

1;

__END__

=head1 NAME

MYDLjE::C - Base class for our controllers
