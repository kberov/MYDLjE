package MYDLjE::Plugin::SystemSetup;
use MYDLjE::Base 'Mojolicious::Plugin';

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
    'conf/' . lc(ref($c->app) . '.' . $c->app->mode . '.yaml')
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
    '%ENV'        => \%ENV,
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
  _save_config($c, $validator);
  $c->render(json => $c->stash);
  return;
}

#write the new configuration to mydlje.yaml so it is shared by all applications
sub _save_config {
  my ($c, $validator) = @_;
  my $config = $c->app->config;
  my $new_config =
    MYDLjE::Config->new(files =>
      [$c->app->home . '/conf/' . lc("$ENV{MOJO_APP}.$ENV{MOJO_MODE}.yaml")]);
  $new_config->stash('installed', 1);
  delete $config->{plugins}{system_setup};
  $new_config->stash('plugins', $config->{plugins});
  foreach my $field_name (keys %{$validator->values}) {
    if ($field_name =~ /^db_/) {
      $new_config->stash('plugins')->{'MYDLjE::Plugin::DBIx'}{$field_name} =
        $validator->values->{$field_name};
    }
  }
  $new_config->stash('plugins')->{'MYDLjE::Plugin::DBIx'}{db_dsn} = '';
  $new_config->stash('site_name', $validator->values->{site_name});
  $new_config->stash('routes',    $config->{routes});
  $new_config->stash('secret',    $validator->values->{secret});
  $new_config->write_config_file(lc(ref($c->app)));
}

sub _validate_system_config {
  my ($c, $validator) = @_;
  my @fields = (
    'site_name', 'secret',  'db_driver',   'db_host',
    'db_name',   'db_user', 'db_password', 'admin_user',
    'admin_password'
  );
  $validator->field(@fields)->each(
    sub {
      my $field = shift;
      $field->required(1)->length(3, 30)
        ->message($field->name
          . " is required. Field length must be between 3 and 30 symbols");
      if ($field->name eq 'admin_password') {
        $field->regexp(qr/[\W]+/)->length(6, 30)
          ->message($field->name
            . ' is too simple. The password must contain letters, '
            . 'numbers and at least one special character. '
            . 'The lenght must be at least 6 characters');
      }
      elsif ($field->name eq 'db_driver') {
        $field->regexp(qr{^(DBI:mysql|DBI:SQLite|DBI:Pg|DBI:Oracle)$})
          ->message('Please select a value for ' . $field->name . '.');
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

        eval { $c->dbix->dbh->ping; };
        if ($@) {
          $db_connect_error =
            substr($@, 0, 120) . '... Please check if the database 
          is created and you enterred correctly database username and password.';
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
    and $c->stash('validator_errors')->{db_connect} eq
    'CALLBACK_CONSTRAINT_FAILED')
  {
    $c->stash('validator_errors')->{db_connect} = $db_connect_error;
  }

  #$c->app->log->debug($c->dumper($c->stash()));
  return $all_ok;
}

1;

__END__

=head1 NAME

MYDLjE::Plugin::SystemSetup - Checks and actions during installation

