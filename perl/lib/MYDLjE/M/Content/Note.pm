package MYDLjE::M::Content::Note;
use Mojo::Base 'MYDLjE::M::Content';


has WHERE => sub { {data_type => 'note', deleted => 0} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Note -  Content with data_type note
