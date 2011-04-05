package MYDLjE::ControlPanel::C::Auth;
use MYDLjE::Base 'MYDLjE::ControlPanel::C';

sub loginscreen {
  my $c = shift;
  $c->render(template => 'cpanel/Auth/loginscreen');
  return 0;
}

sub isauthenticated {

  my $c = shift;
  return 1 if $c->msession->user->login_name ne 'guest';
  $c->redirect_to('/loginscreen');
  return 0;
}

1;
__END__

=head1 NAME

MYDLjE::ControlPanel::C::Auth - Authentication and Authorisation for cpanel

=head1 DESCRIPTION
