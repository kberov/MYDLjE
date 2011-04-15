package MYDLjE::M::Content::Question;
use MYDLjE::Base 'MYDLjE::M::Content';

has COLUMNS => sub {
  [ qw(
      id user_id pid alias tags featured
      data_type data_format time_created tstamp title
      body invisible language group_id protected bad
      )
  ];
};

has WHERE => sub { {data_type => 'question'} };

1;

__END__

=head1 NAME

MYDLjE::M::Content - Base class for all content data_types
