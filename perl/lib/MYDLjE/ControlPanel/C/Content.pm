package MYDLjE::ControlPanel::C::Content;
use MYDLjE::Base 'MYDLjE::ControlPanel::C';

#all types of content are listed by a single template(for now)
sub list_content {
  my $c      = shift;
  my $params = $c->req->params->to_hash;
  my $class  = $c->stash('action');        #just remove "s" - how convennient
  chop($class);
  $c->stash('data_type', $class);
  $c->get_list($params, 'MYDLjE::M::Content::' . ucfirst($class));
  $c->render(template => 'Content/list');
  return;
}
sub pages     { goto &list_content }
sub books     { goto &list_content }
sub articles  { goto &list_content }
sub questions { goto &list_content }
sub answers   { goto &list_content }
sub notes     { goto &list_content }

#all types of content are edited using a single template(for now)
sub edit_content {
  my $c = shift;
  $c->stash->{id} ||= 0;
  $c->render(template => 'Content/edit');
  return;
}
sub edit_page     { goto &edit_content }
sub edit_book     { goto &edit_content }
sub edit_article  { goto &edit_content }
sub edit_question { goto &edit_content }
sub edit_answer   { goto &edit_content }
sub edit_note     { goto &edit_content }

sub get_list {
  my ($c, $params, $class) = @_;

  # Load
  if (my $e = Mojo::Loader->load($class)) {

    # Doesn't exist
    unless (ref $e) {
      $c->app->log->debug("$class does not exist, maybe a typo?");
      return;
    }

    # Error
    $c->app->log->error($e);
    return $e;
  }
  my $where = $class->WHERE;
  if ($params->{where}) {
    my $add_where;
    foreach my $column (keys %$params) {
      if ($column =~ /where_(\w+)$/x && exists $class->COLUMNS->{$1}) {
        $add_where->{$1} = $params->{"where_$1"};
      }
    }
    $where = {%$add_where, %$where};
  }

#TODO: implement "LIMIT" just for supported databases. See SQL::Abstract::Limit;
  my ($sql, @bind) =
    $c->dbix->abstract->select($class->TABLE, $class->COLUMNS, $where,
    {-desc => 'id'});
  $sql
    .= " LIMIT "
    . ($params->{offset} ? " $params->{offset}, " : '')
    . ($params->{rows} || 50);

  #$c->app->log->debug("\n\$sql: $sql\n" . "@bind\n\n");
  $c->stash('list', $c->dbix->query($sql, @bind)->hashes);
  return;
}
1;

__END__

=head1 NAME

MYDLjE::ControlPanel::C::Content - Handling content in cpanel

=head1 DESCRIPTION

