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
  $app->routes->get('/perl_info'   => \&perl_info);
  return;
}

sub check_readables {
  my $c              = shift;
  my $home           = $c->app->home;
  my $readables      = [qw(conf log pub/home )];
  my $readables_json = {};
  foreach my $d (@$readables) {
    if (-d "$home/$d" and -w "$home/$d") {
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
  my $c              = shift;
  my $home           = $c->app->home;
  my $writables      = [qw(conf log pub/home tmp )];
  my $writables_json = {};
  foreach my $d (@$writables) {
    if (-d "$home/$d" and -w "$home/$d") {
      $writables_json->{$d} = {ok => 1};
    }
    else {
      $writables_json->{$d} = {
        ok      => 0,
        message => " $home/$d is not writable."
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
    '%ENV'         => \%ENV,
    '@INC'         => \@INC,
    '%INC'         => \%INC,
    Configuration  => $c->app->config(),
    'Perl Version' => $]
  };
  $c->render(json => $info_json);
  return;
}

1;

__END__

=head1 NAME

MYDLjE::Plugin::SystemSetup - Checks and actions during installation

