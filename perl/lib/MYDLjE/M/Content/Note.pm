package MYDLjE::M::Content::Note;
use MYDLjE::Base 'MYDLjE::M::Content';

has COLUMNS => sub {
  [ qw(
      id user_id pid
      data_type data_format time_created tstamp title alias
      body invisible language groups protected bad
      )
  ];
};
has WHERE => sub { {data_type => 'note'} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Note -  Content with data_type note
