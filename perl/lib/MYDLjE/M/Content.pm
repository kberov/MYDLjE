package MYDLjE::M::Content;
use MYDLjE::Base 'MYDLjE::M';

sub TABLE {'my_content'}

sub COLUMNS {
  [ qw(
      id user_id	pid
      sorting data_type data_format time_created tstamp title alias
      body invisible language groups protected accepted bad
      )
  ];
}

1;

__END__

=head1 NAME

MYDLjE::M::Content - Base class for all content data_types
