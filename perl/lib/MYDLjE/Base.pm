package MYDLjE::Base;
use Mojo::Base -base;
use warnings FATAL => qw( all );

1;

__END__

=encoding utf8

=head1 MYDLjE::Base - base class - Mojo::Base

=head1 SYNOPSIS

  package MYDLjE::M;
  use MYDLjE::Base -base;
  #..
  has validator => sub { MojoX::Validator->new; };

  #...
  package MYDLjE::Template;
  use MYDLjE::Base -base;
  #...
  has context => sub { shift->{_CONTEXT} };
  has stash   => sub { shift->context->stash };
  sub get { return shift->stash->get(@_); }
  ## no critic qw(NamingConventions::ProhibitAmbiguousNames)
  sub set { return shift->stash->set(@_); }
  has c    => sub { shift->get('c'); };
  has app  => sub { shift->c->app; };
  has dbix => sub { shift->c->dbix; };
  sub msession { shift->get('c')->msession(@_); }
  has user => sub { shift->msession->user; };
  sub process { return shift->{_CONTEXT}->process(@_); }
  sub include { return shift->{_CONTEXT}->include(@_); }
  sub insert  { return shift->{_CONTEXT}->insert(@_); }

  #and so forth...


=head1 DESCRIPTION


L<MYDLjE::Base> is a simple base class for L<MYDLjE> projects and classes.
It extends ... you guessed - L<Mojo::Base>.

The idea is to add more things if and when needed. You get all of L<Mojo::Base>.
Currently there is nothing more added.


=head1 SEE ALSO

L<MYDLjE>, L<MYDLjE::Guides>, L<MYDLjE::ControlPanel>, 
L<MYDLjE::Site>, 

=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.


