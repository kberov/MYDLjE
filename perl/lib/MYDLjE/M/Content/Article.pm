package MYDLjE::M::Content::Article;
use MYDLjE::Base 'MYDLjE::M::Content';

sub COLUMNS {
  [ qw(
      id user_id pid
      data_type data_format time_created tstamp title alias
      body invisible language groups protected bad
      )
  ];
}
sub WHERE { {data_type => 'article'} }

1;

__END__

=head1 NAME

MYDLjE::M::Content::Article -  Content with data_type article
