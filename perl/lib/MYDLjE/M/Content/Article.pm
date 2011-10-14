package MYDLjE::M::Content::Article;
use Mojo::Base 'MYDLjE::M::Content';


has WHERE => sub { {data_type => 'article', deleted => 0} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Article -  Content with data_type article
