package MYDLjE::ControlPanel::C::Site;
use MYDLjE::Base 'MYDLjE::ControlPanel::C';
use Mojo::ByteStream qw(b);

sub domains {
  my $c   = shift;
  my $uid = $c->msession->user->id;
  $c->stash(
    domains => [
      $c->dbix->query(
        "SELECT * FROM my_domains WHERE (user_id = ? AND permissions LIKE 'drw%')"
          . " OR (group_id IN (SELECT gid FROM my_users_groups WHERE uid=?) "
          . " AND permissions LIKE '____rw%') ORDER BY domain",
        $uid, $uid
        )->hashes
    ]
  );

  return;
}

sub settings {
  my $c = shift;

#$c->render();
  return;
}


1;

