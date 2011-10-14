package MYDLjE::ControlPanel::C::Home;
use Mojo::Base 'MYDLjE::ControlPanel::C';


sub home {
  my $c = shift;
  $c->render(

    #template => 'Home/home'
  );
  return;
}


1;
__END__

=head1 NAME

MYDLjE::ControlPanel::C::Home - Default route for cpanel

=head1 DESCRIPTION
