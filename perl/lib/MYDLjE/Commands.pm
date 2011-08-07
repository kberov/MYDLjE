package MYDLjE::Commands;
use Mojo::Base 'Mojolicious::Commands';
has namespaces => sub { [qw/MYDLjE::Command Mojolicious::Command Mojo::Command/] };


1;
__END__

=encoding utf8

=head1 NAME

MYDLjE::Commands - run MYDLjE speciffic commands.

=head1 DESCRIPTION

This class is used only by the mydlje application. It simply prepends the <LMYDLjE::Command> 
namespace to Mojolicious::Commands->namespaces.

=head2 SEE ALSO

L<Mojolicious::Commands>, L<Mojolicious::Command>, L<Mojo::Command> L<MYDLjE>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.


