package MYDLjE::ControlPanel::C::Site;
use MYDLjE::Base 'MYDLjE::ControlPanel::C';
use List::Util;

sub domains {
  my $c   = shift;
  my $uid = $c->msession->user->id;

  #save some selects
  if ($c->msession('domains')) {
    $c->stash(domains => $c->msession('domains'));
  }
  else {
    my $domains_SQL =
        'SELECT * FROM domains WHERE '
      . $c->sql('write_permissions_sql')
      . ' ORDER BY domain';
    $c->stash(domains => [$c->dbix->query($domains_SQL, $uid, $uid)->hashes]);
    $c->msession(domains => $c->stash('domains'));
  }
  return;
}

sub edit_domain {
  my $c = shift;
  require MYDLjE::M::Domain;
  my $id     = $c->stash('id');
  my $domain = MYDLjE::M::Domain->new;
  my $user   = $c->msession->user;

  if (defined $id) {
    $domain->select(
      id   => $id,
      -and => [\[$c->sql('write_permissions_sql'), $user->id, $user->id]]
    );
  }
  else{
    $domain->permissions;# default permissions
  }

  if ($c->req->method eq 'GET') {
    $c->stash(form => $domain->data);
    return;
  }
  delete $c->msession->sessiondata->{domains};
  #handle POST
  my $v = $c->create_validator;
  $v->field('domain')->required(1)->regexp($domain->FIELDS_VALIDATION->{domain}{regexp})
    ->message('Please enter valid domain name!');
  $v->field('name')->required(1)->inflate(\&MYDLjE::M::no_markup_inflate)
    ->message('Please enter valid value for human readable name!');
  $v->field('description')->required(1)->inflate(\&MYDLjE::M::no_markup_inflate)
    ->message('Please enter valid value for description!');
  $v->field('permissions')->required(1)
    ->regexp($domain->FIELDS_VALIDATION->{permissions}{regexp})
    ->message('Please enter valid value for permissions like "drwxrwxr--"!');

  my $all_ok = $c->validate($v);
  $c->stash(form => {%{$c->req->body_params->to_hash}, %{$v->values}});

  return unless $all_ok;
  
  my %ugids = ();

  #add user_id and group_id only if the domain is not the default or is new
  unless (defined $domain->id) {
    %ugids = (user_id => $user->id, group_id => $user->group_id);
  }

  #now we are ready to save
  $c->stash(id => $domain->save(%{$v->values}, %ugids));
  if (defined $c->stash('form')->{save_and_close}) {
    $c->redirect_to('/site/domains');
  }

  #$c->render();
  return;
}

sub pages {
  my $c = shift;
  $c->stash(form => $c->req->params->to_hash);
  my $form = $c->stash('form');
  $c->domains();
  if (exists $form->{'page.domain_id'}) {
    $form->{'pid'} = 0;
    $c->msession('domain_id', $form->{'page.domain_id'});
    $c->msession('language',  $form->{'content.language'});

  }
  return;
}

sub edit_page {
  my $c = shift;

  require MYDLjE::M::Page;
  require MYDLjE::M::Content::Page;
  my $id      = $c->stash('id');
  my $page    = MYDLjE::M::Page->new;
  my $content = MYDLjE::M::Content::Page->new;
  my $user    = $c->msession->user;
  my $method  = $c->req->method;
  $c->domains();    #fill in "domains" stash variable
  $c->stash(page_types => $page->FIELDS_VALIDATION->{page_type}{constraints}[0]{in});
  $c->stash(page_pid_options => $c->_set_page_pid_options($user));
  $c->stash(form             => $c->req->params->to_hash);
  my $form = $c->stash('form');
  $form->{'content.language'} ||=  $c->app->config('plugins')->{i18n}{default};
  my $language =
    (List::Util::first { $form->{'content.language'} eq $_ }
    @{$c->app->config('languages')});

  if ($id) {        #edit
    $page->select(
      id      => $id,
      deleted => 0,
      -and    => [\[$c->sql('write_permissions_sql'), $user->id, $user->id]]
    );
    $page->id && $content->select(
      page_id  => $page->id,
      language => $language,
      deleted  => 0,
      -and     => [\[$c->sql('write_permissions_sql'), $user->id, $user->id]]
    );
    $form = {
      (map { 'content.' . $_ => $content->$_() } @{$content->COLUMNS}),
      (map { 'page.' . $_ => $page->$_() } @{$page->COLUMNS}),
      %$form,
    };
    delete $c->stash->{id} unless $page->id;
  }
  else {    #new

  }
  $c->app->log->debug($c->dumper($c->stash('form')));

  if ($c->req->method eq 'POST') {
    $c->_save_page($page, $content, $user);
  }

#$c->render();
  return;

}

sub _save_page {
  my ($c, $page, $content, $user) = @_;
  my $req = $c->req;

  #validate
  my $v    = $c->create_validator;
  my $form = $c->stash('form');
  $v->field('content.title')->required(1)->inflate(\&MYDLjE::M::no_markup_inflate)
    ->message($c->l('The field [_1] is required!', $c->l('title')));
  $v->field('content.language')->in($c->app->config('languages'))
    ->message(
    $c->l('Please use one of the availabe languages or first add a new language!'));

  unless ($form->{'page.alias'}) {
    $form->{'page.alias'} = MYDLjE::Unidecode::unidecode($form->{'content.title'});
  }
  $v->field('page.alias')->regexp($page->FIELDS_VALIDATION->{alias}{regexp})
    ->message('Please enter valid page alias!');
  my $domain_ids;
  foreach my $domain (@{$c->stash('domains')}) {
    push @$domain_ids, $domain->{id};
  }

  $v->field('page.domain_id')->in(@$domain_ids)
    ->message('Please use one of the availabe domains or first add a new domain!');

  # if domain_id is switched remove current pid and set the msession domain id
  if ($form->{'page.domain_id'} ne $page->domain_id) {
    $form->{'page.pid'} = 0;
    $c->msession('domain_id', $form->{'page.domain_id'});
  }
  $v->field('page.page_type')->in($c->stash('page_types'));
  $v->field('page.pid')->regexp($page->FIELDS_VALIDATION->{pid}{regexp});
  $v->field('page.description')->inflate(\&MYDLjE::M::no_markup_inflate);
  $v->field([qw(page.published page.hidden page.cache)])
    ->each(sub { shift->regexp($page->FIELDS_VALIDATION->{cache}{regexp}) });
  $v->field('page.expiry')->regexp($page->FIELDS_VALIDATION->{expiry}{regexp});
  $form->{'page.permissions'} ||= $page->permissions;
  $v->field('page.permissions')
    ->regexp($page->FIELDS_VALIDATION->{permissions}{regexp});

  return unless $c->validate($v, $form);

  #save
  my ($content_data, $page_data) = ({}, {});
  foreach my $field (keys %$form) {
    if ($field =~ /content\.(.+)$/x) {
      $content_data->{$1} = $form->{$field};
    }
    elsif ($field =~ /page\.(.+)$/x) {
      $page_data->{$1} = $form->{$field};
    }
  }

  #we may not have page content yet.
  $content->user_id  || $content->user_id($user->id);
  $content->group_id || $content->group_id($user->group_id);
  $content->alias(MYDLjE::Unidecode::unidecode($content_data->{title}));

#TODO: check for duplicate aliases!!!!
#if( $c->dbix->select('pages','alias',{alias=>$page->alias})->fetch
#|| $c->dbix->select('content','alias',{alias=>$content->alias,data_type=>'page'})->fetch)

  #save
  if ($c->stash('id')) {
    $content->page_id||$content->page_id($page->id);
    $c->dbix->begin;
    $content->save($content_data);
    $page->save($page_data);
    $c->dbix->commit;
  }
  else {
    $content->data($content_data);
    $page = MYDLjE::M::Page->add(
      page_content => $content,
      %$page_data,
      user_id  => $user->id,
      group_id => $user->group_id
    );
    $c->stash(id               => $page->id);
    $c->stash(page_pid_options => $c->_set_page_pid_options($user));
  }

  #after save
  #replace form entries
  $c->stash(
    form => {
      %$form,
      (map { 'content.' . $_ => $content->$_() } @{$content->COLUMNS}),
      (map { 'page.' . $_    => $page->$_() } @{$page->COLUMNS}),
    }
  );
  if (exists $form->{save_and_close}) {
    $c->redirect_to('/site/pages');
  }

  #$c->app->log->debug($c->dumper($form));
  return;
}

#prepares an hierarshical looking list for page.pid select_field
sub _set_page_pid_options {
  my ($c, $user) = @_;
  my $page_pid_options = [{label => '/', value => 0}];
  $c->_traverse_children($user, 0, $page_pid_options, 0);
  return $page_pid_options;

}

sub _traverse_children {
  my ($c, $user, $pid, $page_pid_options, $depth) = @_;
  my $id = $c->stash('id') || 0;

  #hack to make the SQL work the first time this method is called
  $id = time if ($depth == 0);

  #Be reasonable and prevent deadly recursion
  $depth++;
  return if $depth > 10;
  my $domain_id = $c->req->param('page.domain_id') || 0;
  my $pages = $c->dbix->query($c->sql('writable_pages'),
    $pid, $domain_id, $id, $user->id, $user->id)->hashes;
  if (@$pages) {
    foreach my $page (@$pages) {
      if ($page->{value} == $id) {
        $page->{disabled} = 1;
      }
      $page->{label} = '-' x $depth . $page->{label};
      if ($page->{page_type} eq 'root') {

        #there can be only one root in a site
        $page_pid_options->[0]{disabled} = 1;
      }
      push @$page_pid_options, $page;
      $c->_traverse_children($user, $page->{value}, $page_pid_options, $depth, $id);
    }
  }
  return;
}

sub settings {
  my $c = shift;

#$c->render();
  return;
}


1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::ControlPanel::C::Site - Controller class for managing site related stuff

=head1 DESCRIPTION

This is the controller implementing actions to manage domains, pages, templates and translations.

=head1 ACTIONS

=head2 domains

    URL: http://example.com/cpanel/site/domains

Lists domains managed by this MYDLjE installation.

=head2 edit_domain

    ADD URL: http://example.com/cpanel/site/edit_domain
    EDIT URL: http://example.com/cpanel/site/edit_domain/123456

Displays and processes a form for adding and editing a domain.


=head2 pages

    URL: http://example.com/cpanel/site/pages

Displays a tree of pages managed by this MYDLjE installation. 
Pages can be filtered by domain and language.

=head2 edit_page

    ADD URL: http://example.com/cpanel/site/edit_page
    EDIT URL: http://example.com/cpanel/site/edit_page/123456

Displays and processes a form for adding and editing a page.

=head2 templates

    URL: example.com/cpanel/site/templates
    TODO

=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.


