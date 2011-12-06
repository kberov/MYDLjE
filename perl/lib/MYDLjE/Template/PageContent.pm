package MYDLjE::Template::PageContent;
use Mojo::Base 'MYDLjE::Template';
use utf8;
use Mojo::ByteStream qw(b);


sub render {
  my $self = shift;
  my $PAGE = $self->get('PAGE');
  my $out  = $self->render_template($PAGE, $PAGE->template);
  my $c    = $self->c;

  #$c->debug('Settings:' . $c->dumper($self->get('SETTINGS')));
  if (!$out) {
    $out = $self->render_page_content();
  }

  $out .= $self->render_content($self->get('MAIN_AREA_CONTENT'));
  $self->render_bricks_to_boxes($PAGE);
  return $out;
}

sub render_template {
  my ($self, $RECORD, $template) = @_;
  if (not $template) {

    #content or page
    if ($RECORD->can('body')) {
      $template = $RECORD->body;
      $RECORD->body('-');
    }
    else {
      $template = $RECORD->template;
      $RECORD->template('-');
    }
  }
  $template || return '';
  Mojo::Util::html_unescape $template;
  my $out = '';

  #SELF: Reference to the record from within its template
  my $ok = eval {
    $out .= $self->process(\$template, {SELF => $RECORD});
    1;
  };
  unless ($ok) {
    $out
      .= $RECORD->TABLE . ' id:'
      . $RECORD->id . ', ('
      . $RECORD->alias
      . ") template ERROR:<br />"
      . "<span style=\"color:red\">$@</span>";
  }

  return $out;
}

sub render_page_content {
  my ($self)    = @_;
  my $c         = $self->c;
  my $PAGE_C    = $self->get('PAGE_C');
  my $language  = $PAGE_C->language;
  my $css_class = $PAGE_C->data_type . ' ' . $PAGE_C->data_format;
  my $id        = $PAGE_C->TABLE . '_' . $PAGE_C->id;
  my $out       = $c->tag(
    'h1',
    id    => 'title_' . $id,
    class => "container title " . $css_class,
    lang  => $language,
    $self->get('TITLE')
  );

  #$c->debug($self->get('BODY'));
  $out .= $c->tag(
    'div',
    id    => 'body_' . $id,
    class => "container body " . $css_class,
    lang  => $language,
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
  my ($self, $CONTENT) = @_;
  my $out = '';
  return '' unless ($CONTENT and ref($CONTENT) eq 'ARRAY');
  my $wrap  = $self->get('SETTINGS')->{WRAP_MAIN_AREA_CONTENT};
  my $table = MYDLjE::M::Content->TABLE;

  foreach my $C (@$CONTENT) {
    my $render = 'render_' . $C->data_format;
    if ($wrap) {
      my $css_class = $C->data_type . ' ' . $C->data_format;
      $out .= $self->c->tag(
        'div',
        id    => $table . '_' . $C->id,
        class => "container body $css_class",
        lang  => $C->language,
        sub { $self->$render($C) }
      );
    }
    else {
      $out .= $self->$render($C);
    }
  }
  return $out;
}

#rendering soubroutines for each data format
sub render_text { return shift->html_paragraphs(shift->body) }

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
  my $body = $RECORD->body;
  Mojo::Util::html_unescape $body;
  return $body;
}

sub render_bricks_to_boxes {
  my ($self, $PAGE) = @_;
  $PAGE ||= $self->get('PAGE');
  my $BOXES       = $self->get('BOXES');
  my $BOXES_NAMES = [keys %$BOXES];
  my $c           = $self->c;
  my $uid         = $self->USER->id;
  my $time        = time;
  my $sql =
      $c->sql('bricks_for_page')
    . " AND ( start = 0 OR start < $time )"
    . " AND ( stop = 0 OR stop > $time )"
    . $/
    . ' AND box IN(\''
    . join(q|','|, @$BOXES_NAMES)
    . '\') AND '
    . $c->sql('read_permissions_sql')
    . ' ORDER BY _id, c.sorting '
    . $c->sql_limit(0, 100);

  require MYDLjE::M::Content::Brick;
  my $columns = join ',', @{MYDLjE::M::Content::Brick->COLUMNS};
  $sql = "SELECT $columns FROM ($sql) as bricks";

  #$c->debug($sql);
  my $BRICKS =
    $self->dbix->query($sql, $PAGE->id, $self->get('C_LANGUAGE'), $uid, $uid, $uid)
    ->hashes;

  return '' unless (scalar @$BRICKS);

  my $table = MYDLjE::M::Content::Brick->TABLE;
  my $wrap  = $self->get('SETTINGS')->{WRAP_BRICKS};
  foreach my $row (@$BRICKS) {
    my $brick          = MYDLjE::M::Content::Brick->new($row);
    my $box            = $brick->box;
    my $box_filled_key = $box . '_FILLED';

    #Is this box filled in? Yes. Then put there nothing more.
    next if $self->get($box_filled_key);
    my $render = 'render_' . $brick->data_format;
    if ($wrap) {
      my $language  = $brick->language;
      my $css_class = $brick->data_type . ' ' . $brick->data_format;
      $BOXES->{$box} .= $self->c->tag(
        'div',
        id    => $table . '_' . $brick->id,
        class => "container body " . $css_class,
        lang  => $language,
        sub { $self->$render($brick) }
      );
    }
    else {
      $BOXES->{$box} .= $self->$render($brick);
    }

    #Mark the box as filled from within its template to stop appending more bricks.
    #Example:
    #[% RIGHT_BOX_FILLED=1 %]
  }
  return;
}

#TODO: gets content according to the where clause and renders it.
sub render_where {
  my ($self, $WHERE) = @_;
  my $c    = $self->c;
  my $uid  = $self->USER->id;
  my $time = time;
  my $sql  = '';
  my $out  = '';

  return '';
}
1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Template::PageContent - A front-end page-content renderer

=head1 SYNOPSIS

    [% 
    #In $ENV{MOJO_HOME}/templates/site/site/page.html.tt
    #but can be used in other templates made by the site developer

    USE PAGE_CONTENT = PageContent();
    PAGE_CONTENT.render();
    %]

=head1 DESCRIPTION

This core L<MYDLjE::Template> plugin renders all content attached to 
the currently displayed page. These are records in table C<content> with 
C<page_id> attribute equal to the currently rendered page. 
This is actually the I<defacto view> for L<MYDLjE::Site::C::Site> controller.

=head1 METHODS

=head2 render

Renders all page content. 

  [% 
    USE PAGE_CONTENT = PageContent();
    PAGE_CONTENT.render();
  %]

=head2 render_bricks_to_boxes

Renders all content elements with C<data_type> attribute C<brick> 
(L<MYDLjE::M::Content::Brick>) and disposes them in C<BOXES>,
defined in the current layout. 
The language attribute of the bricks is C<C_LANGUAGE>. 
Retreives the bricks for the current page and all parrent pages recursively.

You can stop displaying/inheriting bricks from parrent pages in the current page.
Depending on the box in which a brick is, 
you set: C<[% RIGHT_BOX_FILLED=1 %]> and no more briks placed in C<RIGHT_BOX> 
will be shown; C<[% LEFT_TOP_BOX_FILLED=1 %]> and no 
more briks placed in C<LEFT_TOP_BOX> will be shown; etc. 

Wraps the bricks with a div tag if C<SETTINGS.WRAP_BRICKS> is set to true.
Called in L<MYDLjE::Template::PageContent/render> after L</render_content>.
Can be callled separately in a site template.

Params: $page - a L<MYDLjE::M:Page> instance - Default: current page

  $self->render_bricks_to_boxes($PAGE);

=head2 render_content

Renders all content elements with C<data_type> attribute other  than C<brick>
and  C<page>. They are put in the special C<content> variable, 
placed in the current layout. 
Content elements are retreived from stash variable C<MAIN_AREA_CONTENT> and 
 have C<box> attribute with value C<MAIN_AREA||''>. 
 C<MAIN_AREA_CONTENT> is constructed in 
 L<MYDLjE::Site::C::Site/_prepare_content>. 
 Called in L</render> after rendering page template (L</render_template>) 
 and L</render_page_content>. 

Params: C<\@CONTENT> - an array reference of MYDLjE::M::Content::* instances

  $out .= $self->render_content($self->get('MAIN_AREA_CONTENT'));

=head2 render_page_content

Renders  content with C<data_type=page> for the current page.
Called in L</render> only if no content from the page template is produced.

  #in $self->render()
  my $out  = $self->render_template($PAGE, $PAGE->template);
  if (!$out) {
    $out = $self->render_page_content();
  }

=head1 DATA_FORMAT METHODS (renderers)

Below are described the methods which are used to render each content 
instance depending on its L<data_format|MYDLjE::M::Content/data_format> attribute. 

=head2 render_html

Just returns the C<$RECORD-E<gt>body> after unescaping the HTML.
All content is html-escaped before being stored. 

Params: C<$RECODRD> - a C<MYDLjE::M::Content::*> instance 

=head2 render_markdown 

Processes the C<$RECORD-E<gt>body> via the helper L<markdown|MYDLjE::Plugin::Helpers/markdown> 
and returns it after unescaping the HTML.

Params: C<$RECODRD> - a C<MYDLjE::M::Content::*> instance 

=head2 render_textile 

Processes the C<$RECORD-E<gt>body> via the helper L<textile|MYDLjE::Plugin::Helpers/textile> 
and returns it after unescaping the HTML.

Params: C<$RECODRD> - a C<MYDLjE::M::Content::*> instance 

=head2 render_text

Splits the text in new lines, wraps them with C<p> html tags and returns 
the result after unescaping the HTML.

Params: C<$RECODRD> - a C<MYDLjE::M::Content::*> instance 

=head2 render_template

Depending on the passed record uses C<$self-E<gt>process> to process 
the C<template> or C<body> attribute and returns the result.
Adds to the stash a C<SELF> variable which is reference to the object it self.
It can be used in the processed template. 
This is the most powerful renderer. 

Params: C<$RECORD> - a C<MYDLjE::M::Content::*> or C<MYDLjE::M::Page> instance, 
$template - optional template code to be used instead of its own template.

  #render a page object using some template
  my $out  = $self->render_template($PAGE, $template_code);
  #render a brick using its own "template" attribute
  my $out  = $self->render_template($brick);

=head1 SEE ALSO

L<MYDLjE::Site::C::Site>, 
L<MYDLjE::M::Content>, 
L<MYDLjE::Template>, L<MYDLjE::Template::PageTree>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

