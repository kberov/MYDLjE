package MYDLjE::Site::C::Site;
use MYDLjE::Base 'MYDLjE::Site::C';
use List::Util qw(first);
use MYDLjE::ControlPanel::C::Site;
use MYDLjE::M::Content::Page;
sub _domains { goto &MYDLjE::ControlPanel::C::Site::domains; }

sub page {
  my $c    = shift;
  my $user = $c->msession->user;
  $c->_domains();    #fill in "domains" and "domain_id" stash variables

  #Construct the current page
  $c->_prepare_page($user);
  return;

}


#detects ui_language and c_language and returns them
sub detect_and_set_languages {
  my ($c) = @_;
  my ($ui_language) =
    ($c->stash('ui_language') || $c->req->param('ui_language') || $c->languages());
  $c->stash(ui_language => $c->languages()) unless $c->stash('ui_language');
  $c->session('ui_language', $ui_language) if $ui_language ne $c->languages();
  my ($c_language) = ($c->req->param('c_language') || $c->session('c_language'));
  $c_language ||= $ui_language;
  $c->session('c_language', $c_language)
    if $c_language ne ($c->session('c_language') || '');

  #if ($c_language ne $ui_language) {    #ui_language depends on c_language here
  #  $ui_language = $c->languages($c_language)->languages;
  #}
  return ($ui_language, $c_language);
}

sub _get_page {
  my ($c, $where) = @_;
  my $page_alias = $c->stash('page_alias');

  if ($page_alias) {
    $where->{alias} = $c->stash('page_alias');
  }
  else {
    $where->{page_type} = 'default';
  }
  return MYDLjE::M::Page->select($where);
}

sub _get_page_404 {
  my ($c, $where) = @_;
  $where->{page_type} = '404';
  delete $where->{alias};
  return MYDLjE::M::Page->select($where);
}

#Retreives page and page properties (MYDLjE::M::Content::Page) from database
#and puts them into stash.
sub _prepare_page {
  my ($c, $user) = @_;
  my $app = $c->app;

  #$c->debug('stash:', $c->dumper($c->stash));
  my $time = time;
  my ($ui_language, $c_language) = $c->detect_and_set_languages();
  my $uid                  = $user->id;
  my $read_permissions_sql = [$c->sql('read_permissions_sql'), $uid, $uid, $uid];
  my $where                = {
    domain_id => $c->msession('domain_id'),
    published => 2,
    start     => [{'=' => 0}, '<' => $time],
    stop      => [{'=' => 0}, '>' => $time],
    -and      => [\$read_permissions_sql]
  };

  #$c->debug($c->dumper($where));
  my $page = $c->_get_page($where);

  #TODO implement a default page with 404 page_type and insert it during install
  if (not $page->id) {
    $page = $c->_get_page_404($where);
    $c->stash(status => $page->page_type);
  }

  #Find page template up in the inheritance path and fallback to the default page
  #for this domain.
  if (not $page->template) {
    my $id = $page->pid;

    #shallow copy $where to change and reuse most of it
    my $parent_where = \%{$where};
    delete $parent_where->{alias};
    for (1 .. 10) {    #try up to 10 levels up
      $parent_where->{id} = $id;
      my $row =
        $c->dbix->select($page->TABLE, [qw(id pid template)], $parent_where)->hash;
      if ($row->{template}) {
        $page->template($row->{template});
        last;
      }
      $id = $row->{pid};
    }

  }
  my $default_language = $app->config('plugins')->{I18N}{default};
  my $page_c_where     = {
    page_id => $page->id,
    start   => [{'=' => 0}, '<' => $time],
    stop    => [{'=' => 0}, '>' => $time],
    '-and' =>
      [\$read_permissions_sql, \"language IN( '$ui_language','$default_language')"],
  };
  my $page_c = MYDLjE::M::Content::Page->new;
  my @rows = $c->dbix->select($page_c->TABLE, $page_c->COLUMNS, $page_c_where)->hashes;

  #$c->debug($c->dumper(@rows));
  #fallback to default language
  $page_c->data($rows[0])
    unless ($page_c->data($rows[1])->{id} and ($page_c->language eq $ui_language));

  $c->stash(
    TITLE       => $page_c->title,
    DESCRIPTION => $page_c->description,
    KEYWORDS    => $page_c->keywords,
    BODY        => $page_c->body,
    PAGE        => $page,
    PAGE_C      => $page_c,
    C_LANGUAGE  => $c_language,

  );
  my %render_options = ();
  if (not $c->stash('format')) {
    $render_options{format} = 'html';
  }
  $c->render(%render_options);
  return;
}

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Site::C::Site - Controller class for displaying site stuff

=head1 DESCRIPTION

This is the controller implementing actions to display domains, pages, 
articles, news...

=head1 ACTIONS

=head2 page

Fetches a page and its content from database (pages) and renders it.



=head1 SEE ALSO

L<MYDLjE::Guides>, L<MYDLjE::Site::C>, L<MYDLjE::Site>, L<MYDLjE>

=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

