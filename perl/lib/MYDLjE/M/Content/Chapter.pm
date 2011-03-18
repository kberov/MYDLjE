package MYDLjE::M::Content::Chapter;
use MYDLjE::Base 'MYDLjE::M::Content';

has COLUMNS => sub {
  [ qw(
      id user_id pid alias keywords description tags
      data_type data_format time_created tstamp title
      body invisible language groups protected bad
      )
  ];
};
has WHERE => sub { {data_type => 'chapter'} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Chapter -  Content with data_type chapter
