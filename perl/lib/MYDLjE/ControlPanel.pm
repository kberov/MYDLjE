package MYDLjE::ControlPanel;
use MYDLjE::Base 'MYDLjE';


has controller_class => 'MYDLjE::ControlPanel::C';


sub startup {
  my $app = shift;
  $app->SUPER::startup;
  my $r = $app->routes;
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

