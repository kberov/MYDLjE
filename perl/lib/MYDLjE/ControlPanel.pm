package MYDLjE::ControlPanel;

use strict;
use warnings FATAL => qw( all );
use  MYDLjE::Base 'MYDLjE';


has controller_class => 'MYDLjE::ControlPanel::C';


sub startup {
  my $app = shift;
  $app->SUPER::startup;
  my $r = $app->routes;

  #TODO: Define routes using description from config file

}


1;

__END__

=head1 NAME

MYDLjE::ControlPanel - The L<cpanel> Application class

=head1 DESCRIPTION


=head1 ATTRIBUTES

L<MYDLjE::ControlPanel> inherits most attributes from L<MYDLjE> and implements/overrides the following ones.

=head2 controller_class 

L<MYDLjE::ControlPanel::C>

