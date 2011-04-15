package MYDLjE::ControlPanel;
use MYDLjE::Base 'MYDLjE';


has controller_class => 'MYDLjE::ControlPanel::C';

#TODO:: think of better config implementation - may be subclass Mojolicious::Plugin::Config
my $CONFIG;

sub startup {
  my $app = shift;
  $CONFIG = MYDLjE::Config->singleton(log => $app->log);
  $app->secret($app->config('secret'));
  $app->sessions->cookie_name($app->config('session_cookie_name'));

  #Load Plugins
  $app->load_plugins();

  # Routes
  my $r = $app->routes;
  $r->route('/hi')->to(action=>'hi',controller=>'Home');
  $r->namespace($app->controller_class);
  my $bridge_to = $app->config('routes')->{'/isauthenticated'}->{to};
  my $login_required_routes = $r->bridge('/')->to(%$bridge_to);
  $login_required_routes->namespace($app->controller_class);

  #Login Required Routes (bridged trough login)
  $app->load_routes($login_required_routes,
    $app->config('login_required_routes'));

  $app->load_routes();

  $app->renderer->root($app->home . '/' . $app->config('templates_root'))
    if $app->config('templates_root');

  #Additional Content-TypeS (formats)
  $app->add_types();

  #Hooks
  $app->hook(before_dispatch => \&MYDLjE::before_dispatch);
  $app->hook(after_dispatch  => \&MYDLjE::after_dispatch);

  return;
}

sub config {
  shift;
  return $CONFIG->stash(@_);
}

1;

__END__

=head1 NAME

MYDLjE::ControlPanel - The L<cpanel> Application class

=head1 DESCRIPTION


=head1 ATTRIBUTES

L<MYDLjE::ControlPanel> inherits most attributes from L<MYDLjE> and implements/overrides the following ones.

=head2 controller_class 

L<MYDLjE::ControlPanel::C>

