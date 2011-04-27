package MYDLjE::M::Content::Answer;
use MYDLjE::Base 'MYDLjE::M::Content';

has COLUMNS => sub {
  [ qw(
      id alias pid page_id user_id sorting data_type data_format
      time_created tstamp title description keywords tags
      body language group_id permissions featured bad start stop accepted
      )
  ];
};

has WHERE => sub { {data_type => 'answer', deleted => 0} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Answer -  Content with data_type answer
