package MYDLjE::ControlPanel::C::Site;
use MYDLjE::Base 'MYDLjE::ControlPanel::C';
use List::Util qw(first);
use MYDLjE::M::Domain;
use MYDLjE::M::Page;

sub domains {
  my $c = shift;

  #save some selects
  if ($c->msession('domains')) {
    $c->stash(domains => $c->msession('domains'));
  }
  else {
    my $uid         = $c->msession->user->id;
    my $domains_SQL = 'SELECT * FROM domains WHERE ' . $c->sql('read_permissions_sql');
    my $domains     = [$c->dbix->query($domains_SQL, $uid, $uid, $uid)->hashes];
    $c->stash(domains => $domains);
    $c->msession(domains => $domains);

    #choose default domain to work with for this session
    my $domain = $c->req->headers->host;

    # "example.com" =~ /example.com/ and "www.example.com" =~ /example.com/ etc.
    $c->msession(domain => (first { $domain =~ /$_->{domain}/x } @$domains));
    $c->msession(domain_id => $c->msession('domain')->{id});

    #fallback to the last domain for this user
    unless (defined $c->msession('domain_id')) {
      $c->msession(domain_id => $domains->[-1]{id});
      $c->msession(domain    => $domains->[-1]);
    }
  }
  return;
}

sub edit_domain {
  my $c      = shift;
  my $id     = $c->stash('id');
  my $domain = MYDLjE::M::Domain->new;
  my $user   = $c->msession->user;
  if (defined $id) {
    $domain->select(
      id   => $id,
      -and => [\[$c->sql('write_permissions_sql'), $user->id, $user->id, $user->id]]
    );
  }
  else {
    $domain->permissions;    # default permissions
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
  $v->field('published')->required(1)->in(0, 1, 2);


  my $all_ok = $c->validate($v);
  $c->stash(form => {%{$c->req->body_params->to_hash}, %{$v->values}});

  return unless $all_ok;

  my %ug_ids = ();

  #add user_id and group_id only if the domain is not the default or is new
  unless (defined $domain->id) {
    %ug_ids = (user_id => $user->id, group_id => $user->group_id);
  }

  #now we are ready to save
  $domain->save(%{$v->values}, %ug_ids);
  $c->stash(id => $domain->id);
  if (defined $c->stash('form')->{save_and_close}) {
    $c->redirect_to('/site/domains');
  }

  #$c->render();
  return;
}

sub delete_domain {
  my $c         = shift;
  my $id        = $c->stash('id') || 0;
  my $confirmed = $c->req->param('confirmed');
  my $dbix      = $c->dbix;
  if ($confirmed && $id > 0) {
    unless (
      eval {
        $dbix->begin;
        $dbix->query($c->sql('delete_domain_content'), $id);
        $dbix->delete(MYDLjE::M::Page->TABLE,   {domain_id => $id});
        $dbix->delete(MYDLjE::M::Domain->TABLE, {id        => $id});
        $dbix->commit;
      }
      )
    {
      $dbix->rollback or Mojo::Exception->throw($dbix->error);
      Mojo::Exception->throw("Error deleting domain:" . $@);
    }

  }

  delete $c->msession->sessiondata->{domains};
  $c->domains();    #fill in "domains" stash variable
  $c->redirect_to('/site/domains');
  return;
}

sub delete_page {
  my $c         = shift;
  my $id        = $c->stash('id') || 0;
  my $confirmed = $c->req->param('confirmed');
  my $dbix      = $c->dbix;
  if ($confirmed && $id > 0) {
    my $page = MYDLjE::M::Page->select(id => $id);
    $dbix->delete(MYDLjE::M::Page->TABLE, {id => $id});
  }
  else {
    $c->flash(
      message => $c->l(
        'No page deleted! Parameters: $id:[_1], $confirmed:[_2]', $id, $confirmed
      )
    );
  }

  $c->redirect_to('/site/pages');
  return;
}

sub pages {
  my $c    = shift;
  my $form = {@{$c->req->params->params}};
  $c->stash(form => $form);
  $c->domains();
  $c->persist_domain_id($form);
  return;
}

sub persist_domain_id {
  my ($c, $form) = @_;
  if (exists $form->{'page.domain_id'} && defined $form->{'page.domain_id'}) {
    $c->msession('domain_id', $form->{'page.domain_id'});
  }

  return;
}

sub edit_page {
  my $c = shift;
  require MYDLjE::M::Content::Page;
  my $id = $c->stash('id');
  $c->stash('current_page_id', $id || 0);
  my $page    = MYDLjE::M::Page->new;
  my $content = MYDLjE::M::Content::Page->new;
  my $user    = $c->msession->user;
  my $form    = {@{$c->req->params->params}};

  $c->domains();    #fill in "domains" stash variable
  $c->persist_domain_id($form);

  $c->stash(page_types => $page->FIELDS_VALIDATION->{page_type}{constraints}[0]{in});
  $c->stash(page_pid_options => $c->set_page_pid_options($user));
  $form->{'content.language'} = $c->get_form_language($form->{'content.language'});
  if ($id) {        #edit

    #See SQL::Abstract#Literal SQL with placeholders and bind values (subqueries)
    my $uid = $user->id;
    my $and_sql = [$c->sql('write_permissions_sql'), $uid, $uid, $uid];
    $page->select(
      id      => $id,
      deleted => 0,
      -and    => [\$and_sql]
    );
    if ($page->id) {

      $content->select(
        page_id  => $page->id,
        language => $form->{'content.language'},
        deleted  => 0,
        -and     => [\$and_sql]
      );
    }

    delete $c->stash->{id} unless $page->id;
  }
  else {    #new

  }

  #prefill form but keep existing params
  $form = {
    (map { 'content.' . $_ => $content->$_() } @{$content->COLUMNS}),
    (map { 'page.' . $_ => $page->$_() } @{$page->COLUMNS}),
    %$form,
  };

  #$c->debug($c->dumper($form));
  $c->stash(form => $form);

  if ($c->req->method eq 'POST') {
    $c->_save_page($page, $content, $user);
  }

#$c->render();
  return;

}

#detects and sets default language if not present in the form.
sub get_form_language {
  my ($c, $language_field) = @_;
  if (!$language_field) {
    $language_field = $c->app->config('plugins')->{I18N}{default};
  }
  else {
    $language_field = (first { $language_field eq $_ } @{$c->app->config('languages')});
  }
  return $language_field;
}

sub _save_page {
  my ($c, $page, $content, $user) = @_;
  my $req = $c->req;

  #validate
  my $form = $c->stash('form');

  return unless $c->_validate_page($page, $form);

  #save
  my ($content_data, $page_data) = ({}, {});
  foreach my $field (keys %$form) {
    if ($field =~ /content\.(\w+)$/x) {
      $content_data->{$1} = $form->{$field};
    }
    elsif ($field =~ /page\.(\w+)$/x && $field !~ /page\.permissions_(\w+)$/x) {
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
    $content->page_id || $content->page_id($page->id);
    $c->dbix->begin;
    $content->save($content_data);
    $page->data($page_data);
    $page->modify_pid();
    $page->save();
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
    $c->stash(page_pid_options => $c->set_page_pid_options($user));
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
    $c->redirect_to('/site/pages?page.domain_id=' . $form->{'page.domain_id'});
  }
  return;
}

sub _validate_page {
  my ($c, $page, $form) = @_;

  my $v = $c->create_validator;
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

  #$c->debug($c->dumper($c->stash('domains'), $form->{'page.domain_id'}));
  $v->field('page.domain_id')
    ->in(map { exists $_->{id} ? $_->{id} : 0 } @{$c->stash('domains')})
    ->message('Please use one of the availabe domains or first add a new domain!');

  # if domain_id of an existing page is switched, set pid=0
  if (($form->{'page.domain_id'} ne $page->domain_id) && $page->id) {
    $form->{'page.pid'} = 0;
  }
  $v->field('page.page_type')->in($c->stash('page_types'));

  $v->field('page.pid')->regexp($page->FIELDS_VALIDATION->{pid}{regexp});
  $v->field('content.description')->inflate(\&MYDLjE::M::no_markup_inflate);
  $v->field('page.published')->required(1)->in(0, 1, 2);
  $v->field([qw(page.hidden page.cache)])
    ->each(sub { shift->regexp($page->FIELDS_VALIDATION->{cache}{regexp}) });
  $v->field('page.sorting')->regexp($page->FIELDS_VALIDATION->{sorting}{regexp});
  $v->field('page.expiry')->regexp($page->FIELDS_VALIDATION->{expiry}{regexp});
  $form->{'page.permissions'} ||= $page->permissions;
  $v->field('page.permissions')
    ->regexp($page->FIELDS_VALIDATION->{permissions}{regexp});
  my $ok = $c->validate($v, $form);
  $form = {%$form, %{$v->values}};
  return $ok;
}

#prepares an hierarshical looking list for page.pid select_field
sub set_page_pid_options {
  my ($c, $user) = @_;
  my $page_pid_options = [{label => '/', value => 0, permissions => 'd---------'}];
  $c->traverse_children($user, 0, $page_pid_options, 0);
  return $page_pid_options;
}

sub traverse_children {
  my ($c, $user, $pid, $page_pid_options, $depth) = @_;

  #hack to make the SQL work the first time this method is called
  my $id = ($depth == 0) ? time : 0;

  #Be reasonable and prevent deadly recursion
  $depth++;
  return if $depth > 10;
  my ($domain_id) = $c->msession('domain_id');
  my $user_id = $user->id;
  my $disable = ($c->stash('controller') eq 'site');

  if ($disable && $page_pid_options->[-1]{permissions} =~ /^[^d]/x) {
    return;
  }
  my $pages = $c->dbix->query($c->sql('writable_pages_select_menu'),
    $pid, $domain_id, $id, $user_id, $user_id, $user_id)->hashes;
  $id = $c->stash('current_page_id');
  if (@$pages) {
    foreach my $page (@$pages) {
      if (($disable && $page->{value} == $id) || $page->{permissions} =~ /^l/x) {
        $page->{disabled} = 1;
      }
      $page->{css_classes} = "level_$depth $page->{page_type}";
      $page->{label}       = $page->{label};
      push @$page_pid_options, $page;
      $c->traverse_children($user, $page->{value}, $page_pid_options, $depth);
    }
  }
  return;
}

sub settings {
  my $c = shift;

#$c->render();
  return;
}

sub templates {
  my $c = shift;

#$c->render();
  return;
}

sub edit_template {
  my $c = shift;

#$c->render();
  return;
}

sub delete_template {
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


