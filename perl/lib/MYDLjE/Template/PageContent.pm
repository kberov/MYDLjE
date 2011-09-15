package MYDLjE::Template::PageContent;
use MYDLjE::Base 'MYDLjE::Template';
use utf8;
use Mojo::ByteStream qw(b);


sub render {
  my $self     = shift;
  my $PAGE     = $self->get('PAGE');
  my $template = $PAGE->template;

  Mojo::Util::html_unescape( $template);
  Mojo::Util::decode('UTF-8', $template);    # or die $self->context->error;

  $self->c->debug($template);
  my $out = '';
  my $ok = eval { $out .= $self->process(\$template) or die $self->context->error };
  unless ($ok) { $out .= "Page (" . $PAGE->alias . ") template ERROR$@"; }
  return
      $out
    . 'Hello World from '
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

Renders all content which is found in C<CONTENT> STASH variable.
 C<CONTENT> is an array of content elements which are retreived from database and 
 have box property with value C<MAIN_AREA>. C<CONTENT> is constructed in 
 L<MYDLjE::Site::C::Site/_prepare_content>.
 
 TO BE IMPLEMENTED...

 
=head1 SEE ALSO

L<MYDLjE::Template>, L<MYDLjE::PageTree>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

