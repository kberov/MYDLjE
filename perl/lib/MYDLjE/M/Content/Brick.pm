package MYDLjE::M::Content::Brick;
use Mojo::Base 'MYDLjE::M::Content';


has WHERE => sub { {data_type => 'brick', deleted => 0} };

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::M::Content::Brick -  Content with data_type brick

=head DESCRIPTION

Bricks are different. They are used mostly as building blocks.
We put usually in a brick Template code snippets which may do whatever 
the author of the brick conceived. A common case is to put advertizings in bricks.

=head1 SEE ALSO

L<MYDLjE::M>, L<MYDLjE::M::Content>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

