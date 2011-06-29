package MYDLjE::Site;
use MYDLjE::Base 'MYDLjE';
use MYDLjE::Site::C;

has controller_class => 'MYDLjE::Site::C';


sub startup {
  my $app = shift;
  $app->SUPER::startup;
  return;
}


1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Site - The L<site> Application class

=head1 DESCRIPTION


=head1 ATTRIBUTES

L<MYDLjE::Site> inherits all attributes from L<MYDLjE> and implements/overrides the following ones.

=head2 controller_class 

L<MYDLjE::Site::C>


=head1 SEE ALSO

L<MYDLjE::Guides>, L<MYDLjE::Site::C>, L<MYDLjE>



=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

