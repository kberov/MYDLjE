package MYDLjE::Site;

use strict;
use warnings FATAL => qw( all );
use Mojo::Base 'MYDLjE';

sub startup {
  my $app = shift;
  $app->SUPER::startup;
  my $r = $app->routes;
  $app->controller_class('MYDLjE::Site::C');

  #TODO: Define routes using description from config file

}


1;

__END__

=head1 NAME

MYDLjE::Site - The Application class

