package MYDLjE::ControlPanel::C::Content;
use MYDLjE::Base 'MYDLjE::ControlPanel::C';
use Mojo::ByteStream qw(b);

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
sub edit {
  my $c = shift;

  $c->stash(TEMPLATE_WRAPPER => 'cpanel/layouts/'
      . ucfirst($c->stash('controller')) . '/'
      . $c->stash('action')
      . '.tt');

  my $data_type = lc($c->req->param('data_type'));
  my $modules   = Mojo::Loader->search('MYDLjE::M::Content');
  my $data_object;
  for (@$modules) {
    if ($_ =~ /\:$data_type$/xi) {
      $c->stash('data_type', $data_type);
      Mojo::Loader->load($_);
      my $class = ucfirst($data_type);
      $class = "MYDLjE::M::Content::$class";
      if ($c->stash('id')) {
        $data_object = $class->select(id => $c->stash('id'));
      }
      else {
        $data_object = $class->new();
      }
      $c->stash('data_object', $data_object);
      last;
    }
  }

  if ($c->req->method eq 'POST') {
    $c->_edit_post();
  }
  $c->render(template => 'Content/edit');
  return;
}

#handles POST. Saves form data using the appropriate Content object
sub _edit_post {
  my ($c) = @_;
  my $app = $c->app;
  $app->log->debug($c->dumper($c->req->body_params->to_hash));

  #validate
  #TODO: Implement FIELDS_VALIDATION like in MYDLjE::M
  my $fields_ui_data = $app->config('MYDLjE::Content::Form::ui');
  my $v              = $c->create_validator;
  $v->field('title')->required(1)->inflate(
    sub {

      #strip any ML
      my $value = Mojo::DOM->new->parse(shift->value)->text;
      return b($value)->html_escape;
    }
  )->length(3, 255);
  $v->field('keywords')->inflate(
    sub {
      my $filed = shift;
      my $value = $filed->value;
      $value =~ s/[^\p{IsAlnum}\,\s]//gxi;
      my @words = split /[\,\s]/xi, $value;
      $value = join ", ", @words;
      return $value;
    }
  );
  $v->field('description')->inflate(
    sub {
      my $filed = shift;
      my $value = $filed->value;

      #remove everything strange
      $value =~ s/[^\p{IsAlnum}\,\s\-\!\.\?\(\);]//gxi;
      return $value;
    }
  );
  $v->field('data_type')->in(@{$fields_ui_data->{data_type}});
  $v->field('data_format')->in(@{$fields_ui_data->{data_format}});
  $v->field('language')->in(@{$app->config('languages')});
  my $form = $c->req->body_params->to_hash;
  $form->{id} = $form->{id}[0]
    if (ref($form->{id}) && ref($form->{id}) eq 'ARRAY');
  my $ok = $c->validate($v, $form);
  $app->log->debug($c->dumper($c->stash('validator_errors'), $v->errors));
  $c->stash('form', {%$form, %{$v->values}});
  $form = $c->stash('form');

  return unless $ok;

  #save
  my $data_object = $c->stash('data_object');
  $data_object->data($form);

  #new content needs alias
  if ($form->{id} == 0) {
    require MYDLjE::Unidecode;
    $data_object->alias(MYDLjE::Unidecode::unidecode($form->{title}));
  }
  my $user = $c->msession->user;
  $data_object->user_id($user->id)->group_id(
    $c->dbix->select(
      'my_users_groups', 'gid',
      {uid  => $user->id},
      {-asc => 'id'}
      )->hash->{gid}
  );
  $data_object->save();
  return;
}

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
  $c->stash('list_data', $c->dbix->query($sql, @bind)->hashes);
  return;
}
1;

__END__

=head1 NAME

MYDLjE::ControlPanel::C::Content - Handling content in cpanel

=head1 DESCRIPTION

