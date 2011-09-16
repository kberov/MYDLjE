package MYDLjE::Template::PageContent;
use MYDLjE::Base 'MYDLjE::Template';
use utf8;
use Mojo::ByteStream qw(b);


sub render {
  my $self = shift;
  my $PAGE = $self->get('PAGE');
  my $out  = $self->render_page_template($PAGE, $PAGE->template);
  if (!$out) {
    $out = $self->render_page_content();
  }

  $out .= $self->render_content($out, $self->get('CONTENT'));
  $self->render_bricks_to_boxes($PAGE);
  return $out;
}

sub render_page_template {
  my ($self, $RECORD, $template) = @_;
  $template || return '';
  Mojo::Util::html_unescape $template;
  my $out = '';
  my $ok =

    #SELF: Reference to the record from within its template
    eval {
    $out .= $self->process(\$template, {SELF => $RECORD})
      or Carp::croak $self->context->error;
    };
  unless ($ok) {
    $out
      .= $RECORD->TABLE . ' id:'
      . $RECORD->id . ', ('
      . $RECORD->alias
      . ") template ERROR:"
      . "<span class=\"error\">$@</span>";
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

  #$c->debug($self->get('BODY'));
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
  return '' unless $CONTENT;
  foreach my $C ($CONTENT) {
    my $render_data_format = 'render_' . $C->data_format;
    $out .= $self->$render_data_format($C);
  }

  #TODO: Render each data_type depending on its own data_format
  return $out;
}

#rendering soubroutines for each data format
sub render_text { goto &html_paragraphs }

sub render_textile {
  my ($self, $RECORD) = @_;
  my $body = $RECORD->body;
  Mojo::Util::html_unescape $body;
  return $self->c->textile($body);
}

sub render_markdown {
  my ($self, $RECORD) = @_;
  my $body = $RECORD->body;
  Mojo::Util::html_unescape $body;
  return $self->c->markdown($body);
}

sub render_html {
  my ($self, $RECORD) = @_;
  return Mojo::Util::html_unescape $RECORD->body;
}

sub render_template {
  my ($self, $RECORD, $template) = @_;
  return $self->render_page_template($RECORD, $RECORD->body);
}

sub render_bricks_to_boxes {
  my ($self, $PAGE) = @_;
  my $BOXES       = $self->get('BOXES');
  my $BOXES_NAMES = [keys %$BOXES];
  my $c           = $self->c;
  my $uid         = $self->USER->id;
  my $time        = time;
  my $sql =
      $c->sql('bricks_for_page')
    . " AND ( start = 0 OR start < $time )"
    . " AND ( stop = 0 OR stop > $time )"
    . ' AND box IN(\''
    . join(q|','|, @$BOXES_NAMES)
    . '\') AND '
    . $c->sql('read_permissions_sql')
    . ' ORDER BY _id, c.sorting '
    . $c->sql_limit(0, 100);
  my $BRICKS =
    $self->dbix->query($sql, $PAGE->id, $self->get('C_LANGUAGE'), $uid, $uid, $uid);

  #$c->debug($sql)

  return;
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

