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
  $c->stash('current_page_id', $form->{page_id} || 0);
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
sub bricks    { goto &list_content }
sub list      { goto &list_content }

#all types of content are edited using a single template(for now)
sub edit {
  my $c    = shift;
  my $user = $c->msession->user;

  #TODO: be aware of HTTP_X_REQUESTED_WITH
  #$c->stash(TEMPLATE_WRAPPER => 'cpanel/layouts/'
  #    . ucfirst($c->stash('controller')) . '/'
  #    . $c->stash('action')
  #    . '.tt');
  my $data_type = lc($c->req->param('data_type'));
  my $modules   = Mojo::Loader->search('MYDLjE::M::Content');
  my $content;
  for my $module (@$modules) {
    if ($module =~ /$data_type$/xi) {
      $c->stash('data_type', $data_type);
      my $e = Mojo::Loader->load($module);
      Mojo::Exception->throw($e) if $e;
      if ($c->stash('id')) {
        $content = $module->select(id => $c->stash('id'));
      }
      else {
        $content = $module->new();
      }
      $c->stash('content', $content);
      last;
    }
  }
  $c->stash('current_page_id', $content->page_id || 0);
  $c->stash(page_id_options => $c->set_page_pid_options($user));
  $c->stash(pid_options     => $c->set_pid_options($user));

  if ($c->req->method eq 'POST') {
    $c->_save_content($user);
  }
  else {
    $c->stash(form => $content->data);
  }
  $c->render();
  return;
}

#handles POST. Saves form data using the appropriate Content object
sub _save_content {
  my ($c, $user) = @_;
  my $app  = $c->app;
  my $form = {@{$c->req->params->params}};

  #validate
  #TODO: Implement FIELDS_VALIDATION like in MYDLjE::M
  return unless $c->_validate_content($form);

  #save
  my $content = $c->stash('content');
  foreach my $attr (@{$content->COLUMNS}) {
    if (exists $form->{$attr}) {
      $content->$attr($form->{$attr});
    }
  }
  unless ($c->stash->{id}) {
    $content->user_id($user->id);
    $content->group_id($user->group_id);
  }
  $content->tstamp;
  $content->save();
  $form = {%$form, %{$content->data}};
  $c->stash(id => $content->id);
  if (exists $form->{save_and_close}) {
    $c->redirect_to('/content/' . $content->data_type . 's');
  }
  return;
}

sub _validate_content {
  my ($c, $form) = @_;
  my $content        = $c->stash->{content};
  my $config         = $c->app->config;
  my $fields_ui_data = $config->{'MYDLjE::Content::Form::ui'};
  my $v              = $c->create_validator;
  $v->field('title')->required(1)->inflate(\&MYDLjE::M::no_markup_inflate)
    ->length(3, 255)->message($c->l('The field [_1] is required!', $c->l('title')));
  unless ($form->{'alias'}) {
    $form->{'alias'} = MYDLjE::Unidecode::unidecode($form->{'title'});
  }
  $v->field('alias')->regexp($content->FIELDS_VALIDATION->{alias}{regexp})
    ->message('Please enter valid alias!');
  $v->field('description')->inflate(\&MYDLjE::M::no_markup_inflate)->length(0, 255);
  $v->field('data_type')->in(@{$fields_ui_data->{data_type}});
  $v->field('data_format')->in(@{$fields_ui_data->{data_format}});
  $v->field('language')->in(@{$config->{languages}})
    ->message(
    $c->l('Please use one of the availabe languages or first add a new language!'));
  $form->{'permissions'} ||= $content->permissions;
  $v->field('permissions')->regexp($content->FIELDS_VALIDATION->{permissions}{regexp});
  my $ok = $c->validate($v, $form);
  $c->stash(form => {%$form, %{$v->values}});

  return $ok;
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

  #$c->app->log->debug("\n\$sql: $sql\n" . "@bind\n\n");
  $c->stash('list_data' => [$c->dbix->query($sql, @bind)->hashes]);

  #$c->app->log->debug($c->dumper($c->stash('list_data')));

  return;
}

#prepares an hierarshical looking list for pid select_field
sub set_pid_options {
  my ($c, $user) = @_;
  my $pid_options = [{label => '/', value => 0}];
  $c->traverse_content_children($user, 0, $pid_options, 0);
  return $pid_options;
}

#traverses only content which holds other content i.e permissions LIKE 'd%'
sub traverse_content_children {
  my ($c, $user, $pid, $pid_options, $depth) = @_;

  #hack to make the SQL work the first time this method is called
  my $id = ($depth == 0) ? time : 0;

  #Be reasonable and prevent deadly recursion
  $depth++;
  return if $depth > 10;
  my $user_id = $user->id;
  my $elems   = $c->dbix->query($c->sql('writable_content_select_menu'),
    $pid, $id, $user_id, $user_id, $user_id)->hashes;
  $id = ($c->stash('id') || 0);
  if (@$elems) {

    foreach my $elem (@$elems) {
      if ($elem->{value} == $id) {
        $elem->{disabled} = 1;
      }
      $elem->{css_classes} = "level_$depth $elem->{data_type}";
      push @$pid_options, $elem;
      $c->traverse_content_children($user, $elem->{value}, $pid_options, $depth);
    }
  }
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

