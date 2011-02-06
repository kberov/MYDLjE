package MYDLjE::C;

#Base class for all controllers
use MYDLjE::Base 'Mojolicious::Controller';

# Say hello.
# This acction is here only for test purposes.
# no other actions allowed here.
sub hi {
  my $c = shift;
  $c->render(
    text => 'Controller '.$c->stash('controller') . ' from '
       .  ref($c)
      . ' with action '
      . $c->stash('action')
      . ' and id '
      . $c->stash('id')
      . ' says Hi!'
      . ($c->stash('format') || 'no format')
  );
}

1;

__END__

=head1 NAME

MYDLjE::C - Base class for our controllers


=head1 DESCRIPTION


=head1 ATTRIBUTES

L<MYDLjE::C> inherits all attributes from L<Mojolicious::Controller> and implements/overrides the following ones.



=head1 SEE ALSO

L<MYDLjE::Guides>, L<MYDLjE::ControlPanel::C>, L<MYDLjE::Site::C>


