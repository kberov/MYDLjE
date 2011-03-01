package MYDLjE::Plugin::SystemSetup;
use MYDLjE::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app, $conf) = @_;
  return if $app->config->{installed};
  # Config
  $conf ||= {};
  $app->routes->get('/check_readables' => \&check_readables);
  $app->routes->get('/check_writables' => \&check_writables);
  $app->routes->get('/check_modules'   => \&check_modules);
  return;
}

sub check_readables {
  my $c              = shift;
  my $home           = $c->app->home;
  my $readables      = [qw(conf templates log pub pub/home )];
  my $readables_json = {};
  foreach my $d (@$readables) {
    if (-d "$home/$d" and -w "$home/$d") {
      $readables_json->{$d} = {ok => 1};
    }
    else {
      $readables_json->{$d} = {
        ok      => 0,
        message => "'$home/$d' is either not a directory or is not writable."
      };
    }
  }
  $c->render(json => $readables_json);
  return;

}

sub check_writables {
  my $c    = shift;
  my $home = $c->app->home;
  my $writables      = [qw(conf log pub/home tmp )];
  my $writables_json = {};
  foreach my $d (@$writables) {
    if (-d "$home/$d" and -w "$home/$d") {
      $writables_json->{$d} = {ok => 1};
    }
    else {
      $writables_json->{$d} = {
        ok      => 0,
        message => "'$home/$d' is either not a directory or is not writable."
      };
    }
  }
  $c->render(json => $writables_json);
  return;
}

sub check_modules {
  my $c            = shift;
  my $modules      = [qw(DBI DBD::mysql Time::Piece GD)];
  my $modules_json = {};
  foreach my $module (@$modules) {
    my $ok = eval "require $module";
    if (not $ok or $@) {
      $modules_json->{$module} = {
        ok      => 0,
        message => 'Ask your hosting provider to install it.'
      };
    }
    else {
      $modules_json->{$module} = {ok => 1};
    }
  }
  $c->render(json => $modules_json);
  return;
}

1;
