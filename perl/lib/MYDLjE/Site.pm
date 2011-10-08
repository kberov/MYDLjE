package MYDLjE::Site;
use MYDLjE::Base 'MYDLjE';
use MYDLjE::Site::C;

has controller_class => 'MYDLjE::Site::C';

my $CONFIG;

sub config {
  shift;
  return $CONFIG->stash(@_);
}

sub startup {
  my $app = shift;
  $CONFIG = MYDLjE::Config->singleton(log => $app->log);
  $app->static->root($app->home . $app->config('static_root'));
  $app->secret($app->config('secret'));
  $app->sessions->cookie_name($app->config('session_cookie_name'));

  #Load Plugins
  $app->load_plugins();

  # Routes
  my $r = $app->routes;
  $r->namespace($app->controller_class);
  $r->route('/hi')->to(action => 'hi', controller => 'Site', id => 1);
  $app->check_if_system_is_installed($CONFIG) || return;
  $app->load_routes($r);

  $app->renderer->root($app->home . '/' . $app->config('templates_root'))
    if $app->config('templates_root');

  #Additional Content-TypeS (formats)
  $app->add_types();

  #Hooks
  $app->hook(before_dispatch => \&MYDLjE::before_dispatch);
  $app->hook(after_dispatch  => \&MYDLjE::after_dispatch);

  return;
}


1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Site - The L<site> Application class

=head1 DESCRIPTION


=head1 ATTRIBUTES

L<MYDLjE::Site> inherits all attributes from L<MYDLjE> and 
implements/overrides the following ones.

=head2 controller_class 

L<MYDLjE::Site::C>


=head1 SEE ALSO

L<MYDLjE::Guides>, L<MYDLjE::Site::C>, L<MYDLjE>



=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

