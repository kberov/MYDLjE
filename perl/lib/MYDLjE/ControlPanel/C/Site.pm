package MYDLjE::ControlPanel::C::Site;
use MYDLjE::Base 'MYDLjE::ControlPanel::C';

#Raw SQL for getting domains that belong to the current user
# OR the user belongs to a grup that has "read" and "write" permisttions
my $permissions_sql_AND =
    "(user_id = ? AND permissions LIKE '_rw%')"
  . " OR (group_id IN (SELECT gid FROM my_users_groups WHERE uid= ?) "
  . " AND permissions LIKE '____rw%')";

#TODO: make this SQL common for ALL tables with the mentioned columns,
#thus achieving commonly used permission rules everywhere.
my $domains_SQL =
  "SELECT * FROM my_domains WHERE $permissions_sql_AND ORDER BY domain";

sub domains {
  my $c   = shift;
  my $uid = $c->msession->user->id;
  $c->stash(domains => [$c->dbix->query($domains_SQL, $uid, $uid)->hashes]);

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
      -and => [\[$permissions_sql_AND, $user->id, $user->id]]
    );
  }
  if ($c->req->method eq 'GET') {
    $c->stash(form => $domain->data);
    return;
  }

  #handle POST
  my $v = $c->create_validator;
  $v->field('domain')->required(1)
    ->regexp($domain->FIELDS_VALIDATION->{domain}{regexp})
    ->message('Please enter valid domain name!');
  $v->field('name')->required(1)->inflate(\&MYDLjE::M::no_markup_inflate)
    ->message('Please enter valid value for human readable name!');
  $v->field('description')->required(1)
    ->inflate(\&MYDLjE::M::no_markup_inflate)
    ->message('Please enter valid value for description!');
  $v->field('permissions')->required(1)
    ->regexp($domain->FIELDS_VALIDATION->{permissions}{regexp})
    ->message('Please enter valid value for permissions like "drwxrwxr--"!');

  my $all_ok = $c->validate($v);
  $c->stash(form => {%{$c->req->body_params->to_hash}, %{$v->values}});

  #$c->app->log->debug($c->dumper($c->stash));
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

}

sub edit_page {
  my $c = shift;

  require MYDLjE::M::Page;
  my $id   = $c->stash('id');
  my $page = MYDLjE::M::Page->new;
  my $user = $c->msession->user;

  $c->domains();
  my $pt_constraints =
    $page->FIELDS_VALIDATION->{page_type}{constraints}[0]{in};
  $c->stash(page_types => $pt_constraints);

  $c->stash(page_pid_options => $c->_set_page_pid_options($user));

#$c->render();
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

  #Be reasonable and prevent deadly recursion
  $depth++;
  return if $depth > 20;
  my $domain_id = $c->req->param('page.domain_id') || 0;
  my $pages = $c->dbix->query(
    'SELECT id as value, alias as label, page_type FROM my_pages'
      . ' WHERE pid=? AND domain_id=? AND id>0' . ' AND '
      . $permissions_sql_AND,
    $pid, $domain_id, $user->id, $user->id)->hashes;
  if (@$pages) {
    foreach my $page (@$pages) {
      push @$page_pid_options, $page;
      $page_pid_options->[-1]{label} =
        '-' x $depth . $page_pid_options->[-1]{label};
      if ($page->{page_type} eq 'root') {

        #there can be only one root in a site
        $page_pid_options->[0]{disabled} = 1;
      }
      $c->_traverse_children($user, $page->{value}, $page_pid_options,
        $depth);
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

