package MYDLjE::ControlPanel::C;

#Base class for MYDLjE::ControlPanel controllers

use strict;
use warnings FATAL => qw( all );
use Mojo::Base 'MYDLjE::C';

sub hi {
  my $c = shift;
  $c->render(text => ref($c) . ' says Hi!');
}
1;

