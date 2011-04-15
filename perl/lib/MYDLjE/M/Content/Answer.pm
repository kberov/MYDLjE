package MYDLjE::M::Content::Answer;
use MYDLjE::Base 'MYDLjE::M::Content';

has COLUMNS => sub {
  [ qw(
      id user_id pid  alias title tags
      sorting data_type data_format time_created tstamp
      body invisible language group_id protected accepted bad
      )
  ];
};
has WHERE => sub { {data_type => 'answer'} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Answer -  Content with data_type answer
