package MYDLjE::Template::PageTree;
use MYDLjE::Base 'MYDLjE::Template';
use utf8;
our $VERSION = '0.03';
require Mojo::Util;

has pid      => 0;
has domain   => 'localhost';
has language => 'en';

sub render {
  my $self = shift;
  
  return 'rendered';
}

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Template::PageTree - A back-end Pages Tree and a front-end Site Map

