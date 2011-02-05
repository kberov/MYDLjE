package MYDLjE::Site::C;

#Base class for MYDLjE::Site controllers

use strict;
use warnings FATAL => qw( all );
use Mojo::Base 'MYDLjE::C';

=pod

sub hi {
    my $c = shift;
    $c->render(text => ref($c) . ' says Hi!');
}

=cut

1;

