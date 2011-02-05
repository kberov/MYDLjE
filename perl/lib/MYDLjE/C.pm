package MYDLjE::C;

#Base class for all controllers

use strict;
use warnings FATAL => qw( all );
use Mojo::Base 'Mojolicious::Controller';

# Say hello.
# This acction is here only for basic tests.
# no other actions allowed here.
sub hi {
  my $c = shift;
  $c->render(text => $c->stash('controller')
      . ' from ',ref($c)
      . ' with action '
      . $c->stash('action')
      . ' and id '
      . $c->stash('id')
      . ' says Hi!'
      . ($c->stash('format') || 'no format'));
}

1;

__END__

=head1 NAME

MYDLjE::C - Base class for our controllers
