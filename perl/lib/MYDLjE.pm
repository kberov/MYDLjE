package MYDLjE;
use MYDLjE::Base 'Mojolicious';
use MYDLjE::Config;
use MYDLjE::C;
require Mojo::Util;

our $VERSION = '01.09.18b0';

has controller_class => 'MYDLjE::C';
has env              => sub {
  if   ($_[1]) { $ENV{$_[1]} }
  else         { \%ENV }
};
our $DEBUG = ((!$ENV{MOJO_MODE} || $ENV{MOJO_MODE} =~ /^dev/x) ? 1 : 0);

my $CONFIG;

sub startup {
  my $app = shift;
  $CONFIG = MYDLjE::Config->singleton(log => $app->log);

  #Fallback to some default secret for today
  $app->secret($app->config('secret') || $app->home . $app->mode . (localtime())[3]);
  $app->sessions->cookie_name($app->config('session_cookie_name')
      || ref($app) . $app->mode);

  #Load Plugins
  $app->load_plugins();

  # Routes
  $app->load_routes();

  #Additional Content-TypeS (formats)
  $app->add_types();

  #Hooks
  $app->hook(before_dispatch => \&before_dispatch);
  $app->hook(after_dispatch  => \&after_dispatch);
  return;
}

sub config {
  shift;
  return $CONFIG->stash(@_);
}

#at the beginning of each response
sub before_dispatch {
  my $c   = shift;
  my $app = $c->app;
  $app->log->debug('New Request:------------------------------------');
  _session_start($c, $app);
  $c->stash('base_url', $c->req->url->base);
  $c->stash->{base_url} =~ s{[^/]+/$}{}x;

  #standalone
  $c->stash->{base_url} =~ m|/$|x
    || do { $c->stash->{base_url} = $c->stash->{base_url} . '/'; };

  return;
}

sub _session_start {
  my ($c, $app) = @_;

#TODO: Refactor all session cookies' related code and move it in MYDLjE::Sessions
  my $base = $c->req->env->{SCRIPT_NAME} || '';
  $base =~ s{[^/]+$}{}x;
  $c->stash('base_path', $base);
  $app->sessions->cookie_path($app->config('session_cookie_path') || $base);
  $app->sessions->default_expiration($app->config('session_default_expiration')
      || $app->sessions->default_expiration);

#NOTE: Storage in database is supported trough $c->msession. See MYDLjE::C::msession.
  my $time = Time::HiRes::time();
  if (not $c->session('start_time')) {
    $c->session('start_time', $time);
    $c->session('id',         Mojo::Util::md5_sum(rand($time) . rand($time) . $time));
  }

  if ($DEBUG) {

    #$app->log->debug($c->dumper($c->session));
  }
  return;
}

#at the end of each response
sub after_dispatch {
  my $c = shift;
  $c->session('requests', ($c->session('requests') || 0) + 1);

  #$c->app->log->debug($c->dumper($c->session));
  $c->app->log->debug('Session:'
      . $c->app->sessions->cookie_name
      . ' End Request:'
      . $c->session('requests')
      . '--------------------------');

  return;
}

#load plugins from config file
sub load_plugins {
  my ($app) = @_;
  $app->plugins->namespaces($app->config('plugins_namespaces'));
  my $plugins = $app->config('plugins') || {};
  foreach my $plugin (keys %$plugins) {
    if ($plugins->{$plugin} && ref($plugins->{$plugin}) eq 'HASH') {
      $app->plugin($plugin => $plugins->{$plugin});
    }
    elsif ($plugins->{$plugin} && $plugins->{$plugin} =~ /^(1|y|true|on)/ix) {
      $app->plugin($plugin);
    }
  }
  return;
}

#load routes, described in config
sub load_routes {
  my ($app, $app_routes, $config_routes) = @_;
  $app_routes ||= $app->routes;
  $config_routes ||= $app->config('routes') || {};

  foreach my $route (
    sort {
      ($config_routes->{$a}{order} || 11111) <=> ($config_routes->{$b}{order} || 11111)
    }
    keys %$config_routes
    )
  {
    next unless $config_routes->{$route}{to};
    my %qrs;
    if (scalar %{$config_routes->{$route}{qrs} || {}}) {
      foreach my $k (keys %{$config_routes->{$route}{qrs}}) {
        $qrs{$k} = qr/$config_routes->{$route}{qrs}{$k}/x;
      }
    }

    my $way = $app_routes->route($route, %qrs);

    #TODO: support other routes descriptions beside 'via'
    if ($config_routes->{$route}{via}) {
      $way->via(@{$config_routes->{$route}{via}});
    }
    $way->to($config_routes->{$route}{to});
  }
  return;
}

sub add_types {
  my ($app) = @_;
  my $types = $app->types;
  my $config_types = $app->config('types') || {};
  foreach my $k (keys %$config_types) {
    $types->type($k => $config_types->{$k});
  }
  return;
}


1;

__END__

=encoding utf8

=head1 NAME

MYDLjE - The base Application class

=head1 DESCRIPTION

This class extends the L<Mojolicious> application class. It is the base 
class that L<MYDLjE::ControlPanel> and L<MYDLjE::Site> extend.
As the child application classes L<MYDLjE::ControlPanel> and L<MYDLjE::Site> have 
corresponding starter scripts L<cpanel> and L<site>. 
This application class has its own L<mydlje> application starter. 
However this class implements only common functionality which is
shared by the L<cpanel> and L<site> applications.

You can make your own applications which inherit L<MYDLjE> or 
L<MYDLjE::ControlPanel> and L<MYDLjE::Site> depending on your needs.
And of course you can inherit directly from L<Mojolicious> and use only 
the bundled files and other perl modules for you own applications.


=head1 ATTRIBUTES

L<MYDLjE> inherits all attributes from L<Mojolicious> and implements/overrides the following ones.

=head2 controller_class 

'MYDLjE::C'. See also L<MYDLjE::C>.

=head1 METHODS

L<MYDLjE> inherits all methods from L<Mojolicious> and implements the following new ones.

=head2 config

  my $all_config = $app->config;
  my $something = $app->config('something');

Getter for config values found in YAML config files.  On first and every subsequent 
call it returns the value of the specified key as parameter. If no key is 
specified returns the whole configuration hash-reference.
The config files are simply YAML. YAML seems cleaner to me. Note that 
MYDLjE is distributed with L<YAML::Any> and L<YAML::Tiny>. If on the 
system there are no oters YAML implementations installed L<YAML::Tiny> 
is used. Otherwise the implementation specifyed in L<YAML::Any/ORDER>
order of preference is used.


=head2 startup

This method initializes the application L<mydlje>. See also
L<MYDLjE::ControlPanel/startup> and L<MYDLjE::Site/startup>. 

We load the following plugins using L<load_plugins>
so they are available for use in  L<mydlje>, L<cpanel> and L<site>.

  system_setup #Enablend only before the system is setup
  helpers #MYDLjE specific helpers
  charset
  validator
  PODRenderer
  I18N
  MYDLjE::Plugin::DBIx
  powered_by #MYDLjE (Mojolicious (Perl))

Application charset is set to 'UTF-8'.

The following routes are pre-defined here:

  route                       name
  
  /perldoc                    perldoc              
  /:action                    action               
  /:action/:id                actionid             
  /:controller/:action/:id    controlleractionid   

The other routes are read from the configuration files. 
You can see all defined routes for the corresponding 
application on the commandline by executing it with the route command.

  Example:
  krasi@krasi-laptop:~/opt/public_dev/MYDLjE$ ./cpanel routes

=head2 load_plugins

Loads all plugins as described in YAML configuration files. Each plugin is 
treated as key=>value pair. The key is the plugin name and must be a string. 
The value can be either a scalar (interpreted as true/false) or a 
hash-reference. When the value is hash-reference it is passed as second argument 
to $app-E<gt>L<plugin|Mojolicious/plugin>.

Example plugins configuration:

  #in MYDLjE/conf/mydlje.development.yaml
  plugins:
    charset: 
        charset: 'UTF-8'
    #enabled
    validator: 1
    #disabled
    pod_renderer: 0

=head1 VERSION 

01.09.18b3

The version represents a date in format YY.mm.dd 
with attached abbreviation for the release quality.
The year part is the year of the release -10 years. 
It also shows roughly the MYDLjE age. MYDLjE first commit on GitHub was on January 24, 2011.

The letter means: a -alpha, b - beta, s - stable.
The numbers after the letter will mean an iteration/milestone number 
of implementing features fixing bugs, etc.


=head1 SEE ALSO

L<MYDLjE::Guides>, L<MYDLjE::ControlPanel>, 
L<MYDLjE::Site>, L<MYDLjE::Config>,L<Hash::Merge::Simple>, L<YAML::Tiny>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

MYDLjE::Guides by Красимир Беров is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Based on a work at github.com.

