package MYDLjE;

use strict;
use warnings FATAL => qw( all );
use Mojo::Base 'Mojolicious';
use YAML::Any();

sub startup {
    my $app = shift;
    
    #Load Plugins
    $app->plugin(charset => 'UTF-8');
    $app->plugin('validator');
    $app->plugin('pod_renderer');

    # Routes
    my $r = $app->routes;
    $app->controller_class('MYDLjE::C');

    $r->route('/hi')->to(controller => 'C', action => 'hi');

    #TODO: Define routes using description from config file

}


1;

__END__

=head1 NAME

MYDLjE - The Application class
