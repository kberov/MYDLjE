package MYDLjE::Site;
use MYDLjE::Base 'MYDLjE';


has controller_class => 'MYDLjE::Site::C';


sub startup {
  my $app = shift;
  $app->SUPER::startup;
  return;
}


1;

__END__

=head1 NAME

MYDLjE::Site - The L<site> Application class

=head1 DESCRIPTION


=head1 ATTRIBUTES

L<MYDLjE::Site> inherits all attributes from L<MYDLjE> and implements/overrides the following ones.

=head2 controller_class 

L<MYDLjE::Site::C>


=head1 SEE ALSO

L<MYDLjE::Guides>, L<MYDLjE::Site::C>, L<MYDLjE>


