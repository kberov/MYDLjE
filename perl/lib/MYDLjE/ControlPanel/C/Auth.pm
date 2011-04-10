package MYDLjE::ControlPanel::C::Auth;
use MYDLjE::Base 'MYDLjE::ControlPanel::C';
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
    $c->render(
      #template => 'Auth/loginscreen'
    );
  }
  elsif ($c->req->method eq 'POST') {
    if ($c->_validate_and_login()) {
      $c->redirect_to('/home');
      return 1;
    }
    else {
      $c->render(
                 #template => 'loginscreen'
                 );
      return;
    }
  }
  return;
}


sub _validate_and_login {
  my $c      = shift;
  my $params = $c->req->params->to_hash;
  if (($params->{session_id} || '') ne $c->msession->id) {
    $c->stash(
      validator_errors => {session_id_error => $c->l('session_id_error')});
    return 0;
  }
  $params->{login_name} =~ s/[^\p{IsAlnum}]//gx;
  my $user = MYDLjE::M::User->select(login_name => $params->{login_name});

  unless ($user->id) {
    $c->app->log->error('No such user:' . $params->{login_name});
    $c->stash(validator_errors =>
        {login_name_error => $c->l('login_field_error', $c->l('login_name'))}
    );
    return 0;
  }

  my $login_password_md5 = Mojo::Util::md5_sum(
    ($params->{session_id} || '') . $user->login_password);
  if ($login_password_md5 ne $params->{login_password_md5}) {
    $c->stash(
      validator_errors => {
        login_password_error =>
          $c->l('login_field_error', $c->l('login_password'))
      }
    );
    return 0;

  #TODO:: add check for user namespace. Is he allowed to use this application?
  }
  else {
    $c->msession->sessiondata({});    #empty
    $c->msession->user($user);        #efficiently log in user
    return 1;
  }
  return 0;
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

=head1 NAME

MYDLjE::ControlPanel::C::Auth - Authentication and Authorisation for cpanel

=head1 DESCRIPTION
