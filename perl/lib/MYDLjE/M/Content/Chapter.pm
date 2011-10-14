package MYDLjE::M::Content::Chapter;
use Mojo::Base 'MYDLjE::M::Content';

has WHERE => sub { {data_type => 'chapter', deleted => 0} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Chapter -  Content with data_type chapter
