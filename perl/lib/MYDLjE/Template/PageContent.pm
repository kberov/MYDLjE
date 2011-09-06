package MYDLjE::Template::PageContent;
use MYDLjE::Base 'MYDLjE::Template';
use utf8;

require Mojo::Util;

sub render {
  my $self = shift;
  return
      'Hello World from '
    . __PACKAGE__
    . ' Called with page "'
    . $self->get('TITLE') . '"';
}

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Template::PageContent - A front-end Content renderer

=head1 METHODS

=head2 render

=head1 SEE ALSO

L<MYDLjE::Template>, L<MYDLjE::PageTree>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

