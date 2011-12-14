package MYDLjE::M::Content::Question;
use Mojo::Base 'MYDLjE::M::Content';

use MYDLjE::M::Content::Answer;

has WHERE => sub { {data_type => 'question', deleted => 0} };

has answers => sub {
  my $self = shift;
  my $order = shift || 'time_created DESC';

  return MYDLjE::M::Content::Answer->select_all(pid => $self->id, order => $order)
    ->{'rows'};
};

1;

__END__

=head1 NAME

MYDLjE::M::Content::Question - Questions that have answers.

=head1 DESCRIPTION

