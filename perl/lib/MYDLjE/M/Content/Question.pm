package MYDLjE::M::Content::Question;
use MYDLjE::Base 'MYDLjE::M::Content';

has WHERE => sub { {data_type => 'question', deleted => 0} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Question - Questions that have answers.

=head1 DESCRIPTION

