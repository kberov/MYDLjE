package MYDLjE::C;

#Base class for all controllers
use MYDLjE::Base 'Mojolicious::Controller';

# Say hello.
# This action is here only for test purposes.
# no other actions allowed here.
sub hi {
  my $c = shift;
  $c->render(text => 'Controller '
      . $c->stash('controller')
      . ' from '
      . ref($c)
      . ' with action '
      . $c->stash('action')
      . ' and id '
      . $c->stash('id')
      . ' says Hi!'
      . ($c->stash('format') || ''));
  return;
}

sub hisession {
  my $c = shift;
  my $i = ($c->msession('i') || 0) + 1;
  $c->render(text => 'Controller '
      . $c->stash('controller')
      . ' $c->msession("i"):'
      . $c->msession('i', $i));
  return;
}

#Controller helper for using MYDLjE session storage along the Mojolicious session
#TODO move this method to a plugin and register it
sub msession {
  my ($c, $key, $value) = @_;
  unless ($c->{msession}) {
    $c->dbix;    #init db connection for sure
    my $class = 'MYDLjE::M::Session';
    if (my $e = Mojo::Loader->load($class)) {
      my $error =
        ref $e
        ? qq{Can't load model class "$class": $e}
        : qq{Model class "$class" doesn't exist.};
      $c->app->log->error($error);
      Carp::confess($error);
    }
    $c->{msession} = MYDLjE::M::Session->select(id => $c->session('id'));
  }

  if (defined $value) {
    $c->{msession}->sessiondata->{$key} = $value;
    return $c->{msession}->sessiondata->{$key};
  }
  elsif ($key) {
    return $c->{msession}->sessiondata->{$key};
  }
  return $c->{msession};
}

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::C - Base class for our controllers


=head1 DESCRIPTION


=head1 ATTRIBUTES

L<MYDLjE::C> inherits all attributes from L<Mojolicious::Controller> and implements/overrides the following ones.

=head2 msession

Controller helper for using MYDLjE database-session storage along the L<Mojolicious::Controller/session>.

Regular usage:

  $c->msession('this',$that);
  my $other_thing = $c->msession('other_thing'); 

Using directly the underlying L<MYDLjE::M::Session>:
  
  my $dbsession = $c->msession;
  my $sid = $c->msession->id;
  #same as $c->msession above:
  my $sessiondata = $c->msession->sessiondata;
  $sessiondata->{this} = $that;
  #current user is "guest" by default and always available
  my $current_user = $session_storage->user;
  
  #when saving must happen now
  $c->msession->save();


=head1 SEE ALSO

L<MYDLjE::Guides>, L<MYDLjE::ControlPanel::C>, L<MYDLjE::Site::C>

=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.



