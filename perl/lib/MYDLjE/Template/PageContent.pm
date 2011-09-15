package MYDLjE::Template::PageContent;
use MYDLjE::Base 'MYDLjE::Template';
use utf8;
use Mojo::ByteStream qw(b);


sub render {
  my $self = shift;
  my $PAGE = $self->get('PAGE');
  my $out  = $self->render_page_template($PAGE);
  if (!$out) {
    $out = $self->render_page_content();
  }
  $out = $self->render_content($out, $self->get('CONTENT'));
  $self->render_bricks_to_blocks();
  return $out;
}

sub render_page_template {
  my ($self, $PAGE) = @_;
  my $template = $PAGE->template || return '';
  Mojo::Util::html_unescape $template;
  my $out = '';
  my $ok =
    eval { $out .= $self->process(\$template) or Carp::croak $self->context->error };
  unless ($ok) {
    $out
      .= "Page ("
      . $PAGE->alias
      . ") template ERROR:"
      . "<span style=\"color:red\">$@</span>";
  }
  return $out;
}

sub render_page_content {
  my ($self) = @_;
  my $c      = $self->c;
  my $out    = $c->tag(
    'h1',
    class => "title",
    lang  => $self->get('PAGE_C')->language,
    $self->get('TITLE')
  );
  $c->debug($self->get('BODY'));
  $out .= $c->tag(
    'div',
    class => "unit body",
    lang  => $self->get('PAGE_C')->language,
    sub { $self->html_paragraphs($self->get('BODY')) }
  );
  return $out;
}

sub html_paragraphs {
  my $self = shift;
  return
      qq|<p class="c body">$/|
    . join(qq|$/</p>$/$/<p class="c body">$/|, split(/(?:\r?\n){2,}/x, shift))
    . "</p>$/";
}

sub render_content {
  my ($self, $out, $CONTENT) = @_;

  #TODO: Render each data_type depending on its own data_format
  return $out;
}

sub render_bricks_to_blocks { }
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

