package MYDLjE::Site::C::Site;
use MYDLjE::Base 'MYDLjE::Site::C';
use List::Util qw(first);
use MYDLjE::ControlPanel::C::Site;
sub _domains { goto &MYDLjE::ControlPanel::C::Site::domains; }

sub page {
  my $c    = shift;
  my $user = $c->msession->user;
  $c->_domains();    #fill in "domains" and "domain_id" stash variables

  #Construct the current page
  $c->_prepare_page($user);
  return;

}

#Retreives page and page properties from database
#and puts them into stash.
sub _prepare_page {
  my ($c, $user) = @_;
  my $time        = time;
  my $ui_language = $c->languages();    #registered by I18N
  my ($c_language) = ($c->req->param('c_language') || $c->session('c_language'));
  $c_language ||= $ui_language;
  $c->session('c_language', $c_language) unless $c->session('c_language');
  if ($c_language ne $ui_language) {    #ui_language depends on c_language here
    $ui_language = $c->languages($c_language)->languages;
  }
  my $page_alias = $c->stash('page_alias');
  my $uid        = $user->id;
  my $and_sql    = [$c->sql('read_permissions_sql'), $uid, $uid, $uid];

  my $where = {
    domain_id => $c->msession('domain_id'),
    published => 2,
    start     => [{'=' => 0}, '<' => $time],
    stop      => [{'=' => 0}, '>' => $time],
    deleted   => 0,
    -and      => [\$and_sql]
  };

  if ($page_alias) {
    $where->{alias} = $page_alias;
  }
  else {
    $where->{page_type} = 'default';
  }
  my $page = MYDLjE::M::Page->select($where);
  $c->debug($c->dumper($where));

  #TODO implement a default page with 404 page_type and insert it during install
  if (not $page->id) {
    $where->{page_type} = '404';
    delete $where->{alias};
    $page = MYDLjE::M::Page->select($where);
    $c->debug('404', $c->dumper($page->data));
    $c->stash(status => $page->page_type);
  }

  #find page template
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
  my $page_properties_where = {
    data_type => 'page',
    page_id   => $page->id,
    language  => $ui_language,
  };
  my $page_properties = MYDLjE::M::Content->select($page_properties_where);
  $c->stash(
    TITLE            => $page_properties->title,
    DESCRIPTION      => $page_properties->description,
    KEYWORDS         => $page_properties->keywords,
    BODY             => $page_properties->body,
    PAGE             => $page,
    PAGE_PROPERTIES  => $page_properties,
    CONTENT_LANGUAGE => $c_language,

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

