package MYDLjE::M::Content::Article;
use MYDLjE::Base 'MYDLjE::M::Content';

has COLUMNS => sub {
  [ qw(
      id user_id pid alias keywords description tags
      data_type data_format time_created tstamp title
      body invisible language group_id protected bad
      )
  ];
};
has WHERE => sub { {data_type => 'article'} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Article -  Content with data_type article
