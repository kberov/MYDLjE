package MYDLjE::M::Content::Page;
use MYDLjE::Base 'MYDLjE::M::Content';

has COLUMNS => sub {
  [ qw(
      id user_id pid alias keywords description tags
      data_type data_format time_created tstamp title
      body invisible language group_id protected featured
      )
  ];
};
has WHERE => sub { {data_type => 'page'} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Note -  Content with data_type 'page'

=head1 DESCRIPTION

This content/data type is a little different from the others. It is not exactly content.
It is used as a placeholder for other data types. May be I should have named it I<screen>, but left it I<page> for historical reasons.

For example we can have a page in the site called I<Home>. We can show on it many different types of content like latest articles, latest questions, featured books etc.

We could also have a page called I<News>. In this page we will store articles intended as news.
Let say this page has id=20.
All articles C<WHERE A.PID=P.ID AND P.ID=20> are news just because they have this column C<PID>(parent id).

Balabala

