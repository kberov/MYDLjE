package MYDLjE::Plugin::SystemSetup;
use MYDLjE::Base 'Mojolicious::Plugin';
use Time::HiRes;
my $REQUIRED_MODULES = [qw(DBI DBD::mysql Time::Piece GD)];

sub register {
  my ($self, $app, $conf) = @_;
  return if $app->config->{installed};

  # Config
  $conf ||= {};
  $app->routes->get('/check_readables' => \&check_readables);
  $app->routes->get('/check_writables' => \&check_writables);
  $app->routes->get('/check_modules'   => \&check_modules);
  $app->routes->get('/perl_info'       => \&perl_info);
  $app->routes->post('/system_config' => \&system_config);
  return;
}

sub check_readables {
  my $c              = shift;
  my $home           = $c->app->home;
  my $readables      = [qw(conf log pub/home )];
  my $readables_json = {};
  foreach my $d (@$readables) {
    if (-d "$home/$d" and -r "$home/$d") {
      $readables_json->{$d} = {ok => 1};
    }
    else {
      $readables_json->{$d} = {
        ok      => 0,
        message => " $home/$d is not readable."
      };
    }
  }
  $c->render(json => $readables_json);
  return;

}

sub check_writables {
  my $c         = shift;
  my $home      = $c->app->home;
  my $writables = [
    'conf', 'log', 'pub/home', 'tmp',

    #'conf/' . lc(ref($c->app) . '.' . $c->app->mode . '.yaml'),
    'index.xhtml'
  ];
  my $writables_json = {};
  foreach my $df (@$writables) {
    if (-w "$home/$df") {
      $writables_json->{$df} = {ok => 1};
    }
    else {
      $writables_json->{$df} = {
        ok      => 0,
        message => " $home/$df is not writable."
      };
    }
  }
  $c->render(json => $writables_json);
  return;
}

sub check_modules {
  my $c            = shift;
  my $modules_json = {};
  foreach my $module (@$REQUIRED_MODULES) {
    my $ok = eval "require $module";
    if (not $ok or $@) {
      $modules_json->{$module} = {
        ok      => 0,
        message => 'Not installed. Ask your hosting provider to install it.'
      };
    }
    else {
      $modules_json->{$module} = {ok => 1};
    }
  }
  $c->render(json => $modules_json);
  return;
}

sub perl_info {
  my $c = shift;
  foreach my $module (@$REQUIRED_MODULES) {
    my $ok = eval "require $module";
    if (not $ok or $@) { next; }
  }

  my $info_json = {
    Home          => $c->app->home,
    MYDLjE        => $MYDLjE::VERSION,
    Mojolicious   => "$Mojolicious::VERSION ($Mojolicious::CODENAME)",
    '%ENV'        => $c->req->env,
    '@INC'        => \@INC,
    '%INC'        => \%INC,
    Configuration => $c->app->config(),
    Perl          => $],
    PID           => $$,
    Name          => $0,
    Executable    => $^X,
    Time          => scalar localtime(time)
  };
  $c->render(json => $info_json);
  return;
}


sub system_config {
  my $c         = shift;
  my $validator = $c->create_validator;
  my ($form_ok) = _validate_system_config($c, $validator);

  unless ($form_ok) {
    $c->render(json => $c->stash);
    return;
  }
  init_database($c->dbix, $c->app->log);
  create_admin_user($c->dbix, $validator->values);
  _replace_index_xhtml($c);
  save_config($c->app->config, $validator->values);

  $c->render(json => $c->stash);
  return;
}

#write the new configuration to mydlje.yaml so it is shared by all applications
sub save_config {
  my ($config, $values) = @_;

  my $new_config =
    MYDLjE::Config->new(
    files => [$ENV{MOJO_HOME} . '/conf/' . lc("$ENV{MOJO_APP}.$ENV{MOJO_MODE}.yaml")]);
  $new_config->stash('installed', 1);
  $config->{plugins}{system_setup} = 0;
  $new_config->stash('plugins', $config->{plugins});

  foreach my $field_name (keys %$values) {
    if ($field_name =~ /^db_/x) {
      $new_config->stash('plugins')->{'MYDLjE::Plugin::DBIx'}{$field_name} =
        $values->{$field_name};
    }
  }
  $new_config->stash('plugins')->{'MYDLjE::Plugin::DBIx'}{db_dsn} = '';
  $new_config->stash('routes', $config->{routes});
  $new_config->stash('secret', $values->{secret});

  $new_config->write_config_file();

  #replace config
  $config = {};
  foreach my $key (keys %{$new_config->stash}) {
    $config->{$key} = $new_config->stash($key);
  }
  return;
}

sub init_database {
  my ($dbix, $log) = @_;
  my $xml_sql =
    Mojo::Asset::File->new(path => $ENV{MOJO_HOME} . '/conf/mysql.schema.sql')->slurp;
  my $dom = Mojo::DOM->new;
  $dom->parse($xml_sql);
  my ($disable_foreign_key_checks) = $dom->at('#disable_foreign_key_checks');
  my @start_init = split(/;/x, $disable_foreign_key_checks->text);
  for (@start_init) {

    #$log->debug("do:$_");
    $dbix->dbh->do($_);
  }

  # Loop over table|view tags with name attributes only
  for my $e ($dom->find('table[name],view[name]')->each) {
    my ($drop, $create) = split(/\s*?;\s*?/x, $e->text);
    $drop   =~ s/^\s*--.*?$//xmg;
    $create =~ s/^\s*--.*?$//xmg;

    #$log->debug("do:table/view[name]" . $e->attrs->{name});
    #$log->debug("do:table/view[name] text" . $e->text);

    $dbix->dbh->do($drop)   if $drop;
    $dbix->dbh->do($create) if $create;
  }
  my ($constraints) = $dom->at('#constraints');
  my @constraints = split(/;/x, $constraints->text);

  #$log->debug("do:#constraints");
  foreach my $co (@constraints) {

    #$log->debug("do:#constraints:" . $co);
    $dbix->dbh->do($co);
  }
  my ($enable_foreign_key_checks) = $dom->at('#enable_foreign_key_checks');
  my @end_init = split(/;/x, $enable_foreign_key_checks->text);
  $dbix->dbh->do($_) for @end_init;

  #fill the tables with some initial data
  $xml_sql =
    Mojo::Asset::File->new(path => $ENV{MOJO_HOME} . '/conf/mysql.data.sql')->slurp;
  $dom = Mojo::DOM->new;
  $dom->parse($xml_sql);

# Loop over named(!) queries only in the order they are defined in the document.
  for my $e ($dom->find('query[name]')->each) {

    #$log->debug("query[name]" . $e->attrs->{name});
    my $query = $e->text;

    #Treat string as multiple lines.
    $query =~ s/^\s*--.*?$//xmg;

    $query =~ s/\)\s*?;\s*?$/)/xg;    #beware... VALUES may contain ';'
    $dbix->query($query);
  }

  return;
}

sub create_admin_user {
  my ($dbix, $values) = @_;

  #$c->app->log->debug($c->dumper($c->stash));
  require MYDLjE::M::User;
  MYDLjE::M::User->add(
    login_name     => $values->{admin_user},
    login_password => $values->{admin_password},
    group_ids      => [1],                         #admin group
    email          => $values->{admin_email},
  );

  #change existing "admin" password
  $dbix->update(
    'users',
    {login_password => Mojo::Util::md5_sum(rand(Time::HiRes::time()))},
    {login_name     => 'admin'}
  );

  #change existing "guest" password
  $dbix->update(
    'users',
    {login_password => Mojo::Util::md5_sum(rand(0.1 + Time::HiRes::time()))},
    {login_name     => 'guest'}
  );
  return;
}

#TODO: Replaces current index.xhtml with a new one
#which will be generated by the "site" application
#current index.xhtml content will be moved to admin user home as ".index.xhtml"
sub _replace_index_xhtml {
  my ($c) = @_;
  return

}

sub _validate_system_config {
  my ($c, $validator) = @_;
  my @fields = (
    'site_name',   'secret',  'db_driver',   'db_host',
    'db_name',     'db_user', 'db_password', 'admin_user',
    'admin_email', 'admin_password'
  );
  $validator->field(@fields)->each(
    sub {
      my $field = shift;
      $field->required(1)->length(4, 30)
        ->message(
        $field->name . " is required. Field length must be between 4 and 30 symbols");
      if ($field->name eq 'admin_user' && $field->name =~ /(admin|guest)/xi) {
        ->message("The user can not be named \"admin \" nor \"guest\"!!!");
      }
      if ($field->name eq 'admin_password') {
        $field->regexp(qr/[\W]+/x)->length(6, 30)
          ->message($field->name
            . ' is too simple. The password must contain letters, '
            . 'numbers and at least one special character. '
            . 'The lenght must be at least 6 characters');
      }
      elsif ($field->name eq 'db_driver') {
        $field->regexp(qr{^(DBI:mysql|DBI:SQLite|DBI:Pg|DBI:Oracle)$}x)
          ->message('Please select a value for ' . $field->name . '.');
      }
      elsif ($field->name eq 'admin_email') {
        $field->email->message('Please enter a valid email for ' . $field->name . '.');
      }

    }
  );

  #try to connect to the database

  my $db_connect_group = $validator->group(
    'db_connect' => [qw(db_driver db_name db_host db_user db_password)]);
  my $db_connect_error = "";
  if ($db_connect_group->is_valid) {
    my $ok = $db_connect_group->constraint(
      callback => sub {
        my $values = shift;
        $c->app->plugin(
          'MYDLjE::Plugin::DBIx',
          { db_driver   => $values->[0],
            db_name     => $values->[1],
            db_host     => $values->[2],
            db_user     => $values->[3],
            db_password => $values->[4],
          }
        );


        if (not eval { $c->dbix->dbh->ping; 1; }) {
          $db_connect_error =
              substr($@, 0, 120)
            . '... Please check if the database '
            . 'is created and you enterred correctly database username and password.';
          return 0;
        }
        else { $c->app->log->debug('db_connect ok') }

        return 1;
      }
    );

    #if($ok->is_valid)
  }
  my $all_ok = $c->validate($validator);
  if (  not $all_ok
    and $c->stash('validator_errors')->{db_connect}
    and $c->stash('validator_errors')->{db_connect} eq 'CALLBACK_CONSTRAINT_FAILED')
  {
    $c->stash('validator_errors')->{db_connect} = $db_connect_error;
  }

  #$c->app->log->debug($c->dumper($c->stash()));
  return $all_ok;
}

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Plugin::SystemSetup - Checks and actions during installation


=head1 SEE ALSO

L<MYDLjE::Plugin::Helpers>, 
L<MYDLjE::Plugin::DBIx>,
L<Mojolicious::Plugin>, 
L<Mojolicious::Plugin::DefaultHelpers>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.


