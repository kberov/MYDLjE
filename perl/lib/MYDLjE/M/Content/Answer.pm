package MYDLjE::M::Content::Answer;
use Mojo::Base 'MYDLjE::M::Content';

has WHERE => sub { {data_type => 'answer', deleted => 0} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Answer -  Content with data_type answer
