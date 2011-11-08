package MYDLjE::ControlPanel::C::Accounts;
use Mojo::Base 'MYDLjE::ControlPanel::C';
use Mojo::ByteStream qw(b);

sub users {
  my $c = shift;
  $c->stash(form  => {@{$c->req->params->params}});
  $c->stash(users => $c->get_users());
  $c->stash(now   => time);
  return;
}

#Generates and executes an SQL query for selecting suers from db.
#The where qlause is generated from the form.
#returns an array of MYDLjE::M::User objects.
sub get_users {
  my $c     = shift;
  my $form  = $c->stash('form');
  my $where = {};
  if ($form->{field}) {
    $where->{$form->{field}} = {-like => $form->{like}};
  }
  my $users = [];
  my ($sql, @bind) =
    $c->dbix->abstract->select(MYDLjE::M::User->TABLE, MYDLjE::M::User->COLUMNS,
    $where);
  $sql .= $c->sql_limit($form->{offset}, $form->{rows});
  foreach my $user (@{$c->dbix->query($sql, @bind)->hashes}) {
    push @$users, $user;
  }
  return $users;
}

sub settings {
  my $c = shift;

#$c->render();
  return;
}


1;

