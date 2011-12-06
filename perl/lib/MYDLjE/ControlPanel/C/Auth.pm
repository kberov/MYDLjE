package MYDLjE::ControlPanel::C::Auth;
use Mojo::Base 'MYDLjE::ControlPanel::C';
require MYDLjE::M::User;

sub logout {
  my $c = shift;
  $c->app->log->info('User ' . $c->msession->id . ' is leaving.');
  $c->msession->user(MYDLjE::M::User->select(login_name => 'guest'));

  $c->redirect_to('/loginscreen');
  return 0;

}

sub loginscreen {
  my $c = shift;
  if ($c->req->method eq 'GET') {
    $c->render();
  }
  elsif ($c->req->method eq 'POST') {
    if ($c->validate_and_login()) {

      #TODO: add hook on_login to do stuff each time a user logs in
      require MYDLjE::ControlPanel::C::Site;
      $c->MYDLjE::ControlPanel::C::Site::domains();

      $c->redirect_to('/home');
      return 1;
    }
    else {
      $c->render();
      return;
    }
  }
  return;
}


sub isauthenticated {
  my $c = shift;
  if (!$c->msession->guest) {
    return 1;
  }
  else {
    $c->redirect_to('/loginscreen');
  }
  return 0;
}


1;
__END__

=encoding utf8

=head1 NAME

MYDLjE::ControlPanel::C::Auth - Authentication and Authorisation for cpanel

=head1 DESCRIPTION

This is the L<cpanel> controller responsible fo authenticating and logging out a user. 
It exposes some methods as actions accesible by the users.

=head1 METHODS

=head2 isauthenticated

All other actions in all controllers are bridged to this action.
It checks if the current L<MYDLjE::ControlPanel::C/msession> user is "guest". 
If Yes - it redirects to loginscreen and returns 0. 
Otherwise it returns 1.

=head2 loginscreen

Displays the login screen if called via GET.

If called via, POST validates the form, checks for existing user 
and if the user meets all requirements puts the user in C<$c-E<gt>msession>. 
Then redirects to C</home> and returns 1. 
During the rest of the session currently logged in user is available via 
C<$c-E<gt>msession-E<gt>user> or C<$c-E<gt>msession('user')>.
More info about login requirements will be provided in L<MYDLjE::Guides|MYDLjE::Guides>. 

In case of login failure just renders the loginscreen like when called via GET. 

=head2 logout

Replaces currently logged in user with "guest" and redirects to C</loginscreen>. 
Returns 0.

=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.


