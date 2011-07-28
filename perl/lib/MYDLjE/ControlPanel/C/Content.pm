package MYDLjE::ControlPanel::C::Content;
use MYDLjE::Base 'MYDLjE::ControlPanel::C';
use Mojo::ByteStream qw(b);
use MYDLjE::ControlPanel::C::Site;
use MYDLjE::M::Content::Note;

*set_page_pid_options = \&MYDLjE::ControlPanel::C::Site::set_page_pid_options;
*traverse_children    = \&MYDLjE::ControlPanel::C::Site::traverse_children;
*get_form_language    = \&MYDLjE::ControlPanel::C::Site::get_form_language;
*domains              = \&MYDLjE::ControlPanel::C::Site::domains;
*persist_domain_id    = \&MYDLjE::ControlPanel::C::Site::persist_domain_id;

#all types of content are listed by a single template(for now)
sub list_content {
  my $c    = shift;
  my $user = $c->msession->user;
  my $form = {@{$c->req->params->params}};
  $form->{data_type} ||= '';
  if (!$form->{data_type} && $c->stash('action') !~ /list/) {
    $form->{data_type} = $c->stash('action');

    #just remove "s" - how convennient books --> book
    $form->{data_type} =~ s|s$||x;
  }

  #fill in "domains" stash variable
  $c->domains();
  $c->persist_domain_id($form);

  $c->stash(data_type => $form->{data_type}
      || MYDLjE::M::Content::Note->new->data_type);

  $c->stash(page_id_options => $c->set_page_pid_options($user));
  $form->{'language'} = $c->get_form_language($form->{'language'});

  $c->get_list($form);
  $c->stash(form => $form);
  $c->render(template => 'content/list');
  return;
}
sub pages     { goto &list_content }
sub books     { goto &list_content }
sub articles  { goto &list_content }
sub questions { goto &list_content }
sub answers   { goto &list_content }
sub notes     { goto &list_content }
sub list      { goto &list_content }

#all types of content are edited using a single template(for now)
sub edit {
  my $c = shift;

  #TODO: be aware of HTTP_X_REQUESTED_WITH
  #$c->stash(TEMPLATE_WRAPPER => 'cpanel/layouts/'
  #    . ucfirst($c->stash('controller')) . '/'
  #    . $c->stash('action')
  #    . '.tt');

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
  else {
    $c->stash(form => $data_object->data);

  }
  $c->render();
  return;
}

#handles POST. Saves form data using the appropriate Content object
sub _edit_post {
  my ($c) = @_;
  my $app = $c->app;

  #$app->log->debug($c->dumper($c->req->body_params->to_hash));

  #validate
  #TODO: Implement FIELDS_VALIDATION like in MYDLjE::M
  my $fields_ui_data = $app->config('MYDLjE::Content::Form::ui');
  my $v              = $c->create_validator;
  $v->field('title')->required(1)->inflate(
    sub {
      Mojo::DOM->new->parse(shift->value)->text;
    }
  )->length(3, 255);
  $v->field('description')->length(0, 255);
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
    $data_object->alias();    #internally setting alias
    $data_object->time_created;
  }

  my $user = $c->msession->user;
  $data_object->user_id($user->id)->group_id($user->group_id)->tstamp;
  $data_object->save();
  $form = {%$form, %{$data_object->data}};
  $c->stash(id => $data_object->id);
  return;
}

sub get_list {
  my ($c, $form) = @_;

  my $where = {
    data_type => {like => ($form->{data_type} || '%')},
    deleted   => 0,
    language  => $form->{language}
  };
  $where->{page_id} = $form->{page_id} if $form->{page_id};
  my $order = $form->{order} ? '-asc' : '-desc';
  $form->{order_by} ||= 'id';

  #restrict always to one domain
  my $pages_sql = ' page_id in(SELECT id FROM pages p WHERE p.domain_id ='
    . $c->msession('domain_id') . ') ';

  #See SQL::Abstract#Literal SQL with placeholders and bind values (subqueries)
  my $uid = $c->msession->user->id;
  $where->{-and} =
    [\[$c->sql('read_permissions_sql'), $uid, $uid, $uid], \[$pages_sql]];
  my ($sql, @bind) =
    $c->dbix->abstract->select('content', '*', $where, [{$order => $form->{order_by}}]);
  $sql .= $c->sql_limit($form->{offset}, $form->{rows});

  $c->app->log->debug("\n\$sql: $sql\n" . "@bind\n\n");
  $c->stash('list_data' => [$c->dbix->query($sql, @bind)->hashes]);

  #$c->app->log->debug($c->dumper($c->stash('list_data')));

  return;
}
1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::ControlPanel::C::Content - Controller for handling content in cpanel

=head1 DESCRIPTION


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров

This code is licensed under LGPLv3.

