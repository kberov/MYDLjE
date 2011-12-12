package MYDLjE::Site::C::Site;
use Mojo::Base 'MYDLjE::Site::C';
use List::Util qw(first);
use MYDLjE::ControlPanel::C::Site;
use MYDLjE::M::Content::Page;
use Mojo::ByteStream qw(b);
sub _domains { goto &MYDLjE::ControlPanel::C::Site::domains; }

sub page {
  my $c    = shift;
  my $user = $c->msession->user;
  $c->_domains();    #fill in "domains" and "domain_id" stash variables

  #Construct the page
  $c->_prepare_page($user);
  $c->_prepare_content($user);

  my %render_options = ();
  if (not $c->stash('format')) {
    $render_options{format} = 'html';
  }
  $c->render(%render_options);
  return;

}

sub _prepare_content {
  my ($c, $user) = @_;
  my $form                 = {@{$c->req->params->params}};
  my $ct                   = MYDLjE::M::Content->new;
  my $sql_abstract         = $c->dbix->abstract;
  my $time                 = time;
  my $uid                  = $user->id;
  my $read_permissions_sql = [$c->sql('read_permissions_sql'), $uid, $uid, $uid];
  my $ct_where             = {
    page_id   => $c->stash('PAGE')->id,
    start     => [{'=' => 0}, {'<' => $time}],
    stop      => [{'=' => 0}, {'>' => $time}],
    deleted   => 0,
    data_type => [-and => {'!=' => 'page'}, {'!=' => 'brick'}],
    language  => $c->stash('C_LANGUAGE'),
    '-and'    => [\$read_permissions_sql],
  };
  my $data_type = $c->stash('data_type');
  my $modules   = Mojo::Loader->search('MYDLjE::M::Content');

  #get content with the given data_type,alias and  page_id=$page->id
  if ($c->stash('alias')) {
    my $module = first { $_ =~ /$data_type$/ix } @$modules;
    if ($module) {
      my $e = Mojo::Loader->load($module);
      Mojo::Exception->throw($e) if $e;
      $ct_where->{alias} = $c->stash('alias');
      $c->debug('$ct_where:' . $c->dumper($ct_where));
      my $content = $module->select($ct_where);
      if (not $content->id) {
        $content = $module->new->data(
          title       => 'Not found',
          body        => 'Not found',
          data_format => 'text',
        );
      }
      $c->stash(CONTENT => [$content]);
      return;
    }
    else {
      $c->app->log->warn('Could not map $data_type "'
          . $data_type
          . '" to Module: "MYDLjE::M::Content::'
          . Mojo::Util::camelize($data_type)
          . '"!');
      delete $c->stash->{'alias'};
    }
  }

  #No alias, so get a list!
  #Load only specified data_type
  my $order = {'-asc' => 'sorting'};
  if ($data_type) {
    $ct_where->{data_type} = $data_type;
    my $order_by = $form->{order_by} || 'tstamp';
    $order = $form->{order} ? {'-asc' => $order_by} : {'-desc' => $order_by};
  }
  my ($sql, @bind) = $sql_abstract->select($ct->TABLE, '*', $ct_where, [$order]);
  $sql .= $c->sql_limit($form->{offset}, $form->{rows});
  my @rows = $c->dbix->query($sql, @bind)->hashes;

  my @CONTENT;
  foreach my $row (@rows) {
    my $module = first { $_ =~ /$row->{data_type}$/xi } @$modules;
    my $e = Mojo::Loader->load($module);
    Mojo::Exception->throw($e) if $e;
    push @CONTENT, $module->new($row);
  }
  $c->stash(MAIN_AREA_CONTENT => \@CONTENT);
  return;
}


#detects ui_language and c_language and returns them
sub detect_and_set_languages {
  my ($c)           = @_;
  my ($ui_language) = $c->set_ui_language($c->stash('ui_language'));
  my ($c_language)  = ($c->req->param('c_language') || $ui_language);
  $c->session('c_language', $c_language)
    if $c_language ne ($c->session('c_language') || '');

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

#Find page template up in the inheritance path and fallback to the default page
#for this domain.
sub _find_and_set_page_template {
  my ($c, $page, $where) = @_;
  return if b($page->template)->trim->to_string;
  my $pid = $page->pid;

  #shallow copy $where to change and reuse most of it
  my $parent_where = \%{$where};
  delete $parent_where->{alias};
  $parent_where->{id} = $pid;
  my $row = {};
  for (1 .. 10) {    #try up to 10 levels up
    $row =
      $c->dbix->select($page->TABLE, [qw(id pid alias template)], $parent_where)->hash;
    if ($row->{template}) {
      last;
    }
    last if !$row->{pid};
    $parent_where->{id} = $row->{pid};

    $pid = $row->{pid};
  }
  if (not $row->{template}) {
    delete $parent_where->{id};
    $parent_where->{page_type} = 'default';
    $row =
      $c->dbix->select($page->TABLE, [qw(id pid alias template)], $parent_where)->hash;
  }

  $page->template($row->{template});
  return;
}

#Retreives page and page properties (MYDLjE::M::Content::Page) from database
#and puts them into stash.
sub _prepare_page {
  my ($c, $user) = @_;
  my $app  = $c->app;
  my $time = time;
  my ($ui_language, $c_language) = $c->detect_and_set_languages();
  my $uid                  = $user->id;
  my $read_permissions_sql = [$c->sql('read_permissions_sql'), $uid, $uid, $uid];
  my $where                = {
    domain_id => $c->msession('domain_id'),
    published => 2,
    start     => [{'=' => 0}, {'<' => $time}],
    stop      => [{'=' => 0}, {'>' => $time}],
    -and      => [\$read_permissions_sql]
  };

  #$c->debug($c->dumper($where));
  my $page = $c->_get_page($where);

  #TODO implement a default page with 404 page_type and insert it during install
  if (not $page->id) {
    $page = $c->_get_page_404($where);
    $c->stash(status => $page->page_type);
  }

  $c->_find_and_set_page_template($page, $where);

  my $default_language = $app->config('plugins')->{I18N}{default};
  my $page_c_where     = {
    page_id => $page->id,
    start   => [{'=' => 0}, {'<' => $time}],
    stop    => [{'=' => 0}, {'>' => $time}],
    '-and' =>
      [\$read_permissions_sql, \"language IN( '$ui_language','$default_language')"],
  };
  my $page_c = MYDLjE::M::Content::Page->new;
  my @rows =
    $c->dbix->select($page_c->TABLE, $page_c->COLUMNS,
    {%$page_c_where, %{$page_c->WHERE}})->hashes;

  #$c->debug($c->dumper(@rows));
  #fallback to default language
  if ($page_c->data($rows[1])->{id} and ($page_c->language eq $ui_language)) {
    $page_c->data($rows[1]);
  }
  else {
    $page_c->data($rows[0]);
  }

  $c->stash(
    TITLE       => $page_c->title,
    DESCRIPTION => $page_c->description,
    KEYWORDS    => $page_c->keywords,
    BODY        => $page_c->body,
    PAGE        => $page,
    PAGE_C      => $page_c,
    C_LANGUAGE  => $c_language,
  );
  return;
}

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Site::C::Site - Controller class for displaying site pages 
and other defined octions.

=head1 DESCRIPTION

This is the controller implementing actions to 
display pages from any domain the system is configured to serve content for.
In pages we embed different I<semantic types> of content
(L<MYDLjE::M::Content/data_type>).

=head1 ACTIONS

=head2 page

Fetches a page and its content from database (pages) and renders it.

=head1 METHODS

This controller defines some methods which are called internally in L</page>
 and are not available as separate actions. However some description is provided
 so you can get an idea on how they work together.

=head2 _domains

This is a direct call (with C<goto>) to L<MYDLjE::ControlPanel::C::Site/domains> 
to detect the domain in which the L</page> method is called. 
This way we know from which domain to retreive the requested page.

=head2 _find_and_set_page_template

Finds a page template up in the inheritance path and
 fallbacks to the default page template
 for the current domain if a template is not found.
 Called in L</_prepare_page> after a page is retreived from the database.

=head2 _get_page

Retreives a L<page|MYDLjE::M::Page> from the database depending on the value in 
C<$c-E<gt>stash('page_alias')> and returns it. 
Fallbacks to the page with C<page_type "default"> 
if C<$c-E<gt>stash('page_alias')> is empty. Called in L</_prepare_page>

=head2 _get_page_404

Retreives a page with C<page_type "404"> and returns it. 
Such page B<I<must>> be created for each domain by the site administrator
using the "cpanel" application. 
Called in L</_prepare_page> if no page is found by L</_get_page>.

=head2 _prepare_content

Retreives content from the database and puts it in the stash to be displayed by
L<MYDLjE::Template::PageContent>.

The content is an array of instances of various L<MYDLjE::M::Content> subclasses.
All of them have their L<page_id|MYDLjE::M::Content/page_id> attribute equal 
to the current C<$page-E<gt>id>. The content elements are 
filtered depending on their read L<permissions|MYDLjE::M::Content/permissions>,
L<start|MYDLjE::M::Content/start>, L<stop|MYDLjE::M::Content/stop>, 
L<deleted|MYDLjE::M::Content/deleted> and 
L<language|MYDLjE::M::Content/language> attributes.
The language is determined by C<$c-E<gt>stash('C_LANGUAGE')>. 
All L<data_type|MYDLjE::M::Content/data_type>s are retreived except C<page> 
which is used as page properties for the current page in the current language 
and is retreived separately in L</_prepare_page>.

=head2 _prepare_page

Retreives a page (C<$page>) and its properties (C<$page_c>) from the databse 
depending on various stash variables, defined by the current route 
and fills in the stash with the retreived data.

The following stash variables are defined for display in the current domain 
or theme layout:

  $c->stash(
    TITLE       => $page_c->title,
    DESCRIPTION => $page_c->description,
    KEYWORDS    => $page_c->keywords,
    BODY        => $page_c->body,
    PAGE        => $page,
    PAGE_C      => $page_c,
    C_LANGUAGE  => $c_language, #content language
  );

=head2 detect_and_set_languages

Detects user interface language and content language and sets them.

Called in L</_prepare_page> before anything else. 
The checks are made in the following order:

  1. ui_language:
    1. Current route with /:ui_language in it;
    2. User browser preferences;
    3. System supported languages 
    (default language for Mojolicious::Plugin::I18N);
  2. c_language:
    1. GET/POST parameter "c_language";
    2. Current ui_langauge (default);

C<c_language> is stored in the current L<Mojolicious::Controller/session>  so you can use it:

  my $content_language = $c->session('c_language');

It is later passed to the stash as C<C_LANGUAGE> too so you can use it in templates.

Note that in case you pass in your form or GET request c_language=bg but your 
route looks like "/en/some_page/foo/bar/etc", L<_prepare_content> 
will get content with C<language='bg'> and L<_prepare_page> 
will get page properties with C<language='en'>. This may be a 
required behaviour in some cases.



=head1 SEE ALSO

L<MYDLjE::Template::PageContent>, 
L<MYDLjE::Guides>, L<MYDLjE::Site::C>, L<MYDLjE::Site>, L<MYDLjE>

=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

