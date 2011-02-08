package MYDLjE;
use MYDLjE::Base 'Mojolicious';
use YAML::Any();
use Hash::Merge();
use Data::Dumper;
has controller_class => 'MYDLjE::C';
has env              => sub {
  if   ($_[1] && exists $ENV{$_[1]}) { $ENV{$_[1]} }
  else                               { \%ENV }
};
has merger => sub { Hash::Merge->new('RIGHT_PRECEDENT') };

#TODO think of merging ARRAYs behavior
#
our $DEBUG = ((!$ENV{MOJO_MODE} || $ENV{MOJO_MODE} =~ /^dev/) ? 1 : 0);

sub startup {
  my $app = shift;

  #Load Plugins
  my $plugins = $app->config('plugins') || [];

  foreach (@$plugins) {
    $app->plugin(ref($_) eq 'HASH' ? %{$_} : $_);
  }

  # Routes
  my $r = $app->routes;

  #TODO: support 'via' and other routes descriptions
  my $routes = $app->config('routes') || [];
  foreach my $route (@$routes) {
    $r->route($route->{route})->to(%{$route->{to}});
  }
  return;
}

sub config {
  my $app = shift;
  if (!$app->{config}) {
    $app->read_config();

    #if($DEBUG){warn Dumper($app->{config})}
  }
  if ($_[0]) {
    return $app->{config}{$_[0]};
  }
  return $app->{config};
}

sub read_config {
  my $app = shift;
  my $args;
  if (ref $_[0] and ref $_[0] eq 'ARRAY') {
    $args = $_[0];
  }
  elsif (@_ > 1) {
    $args = [@_];
  }
  elsif (@_ == 1) {
    $app->log->warn('Only one config file specified:' . $_[0]);
    $args = [@_];
  }

  my ($class, $mode, $home) = (ref($app), $app->mode, $app->home->to_string);
  {
    no strict 'refs';
    $args ||= [@{"${class}::ISA"}];
  }
  push @$args, $class;
  $app->log->debug('read_config @$args: ' . "@$args");
  for my $i (0 .. @$args - 1) {
    my $filename = $args->[$i];
    $filename =~ s|::|-|g;
    $args->[$i] = "$home/conf/" . lc($filename) . ".$mode.yaml";
  }
  if ($args->[-1] !~ /local\./) {
    push @$args, "$home/conf/local.$mode.yaml";
  }
  my $config = {};


  foreach my $filename (@$args) {
    my $conf;
    $app->log->debug('will try to read: ' . $filename);

    if (-r $filename) {
      $conf = YAML::Any::LoadFile($filename);
      $config = $app->merger->merge($config, $conf);
    }
  }
  if ($config->{secret} && $config->{secret} ne $class) {
    $app->secret(b($config->{secret})->md5_bytes);
  }
  return $app->{config} = $config;
}

#stolen from List::MoreUtils
sub _uniq (@) {
  my %seen = ();
  grep { not $seen{$_}++ } @_;
}

1;

__END__

=head1 NAME

MYDLjE - The Application class

=head1 DESCRIPTION

This class extends the L<Mojolicious> application class. It is the base 
class that L<MYDLjE::ControlPanel> and L<MYDLjE::Site> extend.
As the child application classes L<MYDLjE::ControlPanel> and L<MYDLjE::Site> have 
corresponding starter scripts L<cpanel> and L<site> 
this application class has its own L<mydlje> application starter. 
However this class implements only common functionality which is
shared by the L<cpanel> and L<site> applications.

You can make your own applications which inherit L<MYDLjE> or 
L<MYDLjE::ControlPanel> and L<MYDLjE::Site> depending on your needs.
And of course you can inherit directly from L<Mojolicious> and use only 
the bundled files and other perl modules for you own applications


=head1 ATTRIBUTES

L<MYDLjE> inherits all attributes from L<Mojolicious> and implements/overrides the following ones.

=head2 controller_class 

'MYDLjE::C'. See also L<MYDLjE::C>.

=head2 merger

A singleton instance of L<Hash::Merge> instantiated with 
'RIGHT_PRECEDENT' as behavior. You can change it for a while but be sure 
to turn it back as it was so no strange things happen troughout the application.

=head1 METHODS

L<MYDLjE> inherits all methods from L<Mojolicious> and implements the following new ones.

=head2 config

  my $all_config = $app->config;
  my $something = $app->config('something');

Getter for config values found in YAML config files. On the first call it 
checks if configuration is loaded and if not, calls 
L<read_config> to read the config files. On first and every subsequent 
call it returns the value of the specified key as parameter. If no key is 
specified returns the whole configuration hash-reference.
The config files are simply YAML. YAML seems cleaner to me. Note that 
MYDLjE is distributed with L<YAML::Any> and L<YAML::Tiny>. If on the 
system there are no oters YAML implementations installed L<YAML::Tiny> 
is used. Otherwise the implementation specifyed in L<YAML::Any/ORDER>
order of preference is used.

=head2 read_config

  # guess filenames from @ISA
  my $config = $app->read_config;
  #read
  #$ENV{MOJO_HOME}/conf/one.development.yaml
  #$ENV{MOJO_HOME}/conf/second.development.yaml
  #$ENV{MOJO_HOME}/conf/third.development.yaml
  my $config = $app->read_config(qw(one second third));


Reads the list of config files in specifyed order in the C<@_> variable.
If there is no list of files to read, tries C<@ISA> 
+ C<local.$ENV{MOJO_MODE}.yaml>. Foreach element 
converts C<::> to C<->, lowercases it, prepends C<$ENV{MOJO_HOME}/conf/> 
and appends C<.$ENV{MOJO_MODE}> to it. So for example while you develop, 
the list of file which will be read and merged for L<cpanel> is:

  $ENV{MOJO_HOME}/conf/mydlge.development.yaml
  $ENV{MOJO_HOME}/conf/mydlge-controlpanel.development.yaml
  $ENV{MOJO_HOME}/conf/local.development.yaml

Settings in next file overrides settings in previous file.
L<Hash::Merge> is used for merging configuration structures.

Called at the very beginning of L<startup> just after application initialization.

=head2 startup

This method initializes the application. It is called in 
L<MYDLjE::ControlPanel/startup> and L<MYDLjE::Site/startup>, then specific 
for these applications startups are done. 

We load the following plugins 
so they are available for use in  L<mydlje>, L<cpanel> and L<site>.

  charset
  validator
  pod_renderer
  ...others to be listed

Application charset is hard-codded to 'UTF-8'.

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



=head1 SEE ALSO

L<MYDLjE::Guides>, L<MYDLjE::ControlPanel>, L<MYDLjE::Site>, L<Hash::Merge>


