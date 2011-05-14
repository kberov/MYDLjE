package MYDLjE::ControlPanel::C::Site;
use MYDLjE::Base 'MYDLjE::ControlPanel::C';

#Raw SQL for getting domains that belong to the current user
# OR the user belongs to a grup that has "read" and "write" permisttions
my $domain_sql_AND =
    "(user_id = ? AND permissions LIKE 'drw%')"
  . " OR (group_id IN (SELECT gid FROM my_users_groups WHERE uid=?) "
  . " AND permissions LIKE '____rw%')";

#TODO: make this SQL common for ALL tables with the mentioned columns,
#thus achieving commonly used permission rules everywhere.

sub domains {
  my $c   = shift;
  my $uid = $c->msession->user->id;
  $c->stash(
    domains => [
      $c->dbix->query(
        "SELECT * FROM my_domains WHERE $domain_sql_AND ORDER BY domain",
        $uid, $uid)->hashes
    ]
  );

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
      -and => [\[$domain_sql_AND, $user->id, $user->id]]
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

sub settings {
  my $c = shift;

#$c->render();
  return;
}


1;

