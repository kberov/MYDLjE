package MYDLjE::M::Content::Book;
use Mojo::Base 'MYDLjE::M::Content';

has WHERE => sub { {data_type => 'book', deleted => 0} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Book -  Content with data_type book
