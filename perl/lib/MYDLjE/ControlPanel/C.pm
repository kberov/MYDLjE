package MYDLjE::ControlPanel::C;

#Base class for MYDLjE::ControlPanel controllers
use Mojo::Base 'MYDLjE::C';

sub home {
  my $c = shift;
  $c->render(text => 'home');
  return;
}

1;

__END__


=head1 NAME

MYDLjE::ControlPanel::C - The L<cpanel> Controller class


=head1 DESCRIPTION


=head1 ATTRIBUTES

L<MYDLjE::ControlPanel::C> inherits most attributes from L<MYDLjE::C> and implements/overrides the following ones.



=head1 SEE ALSO

L<MYDLjE::Guides>, L<MYDLjE::C>, L<MYDLjE::Site::C>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

