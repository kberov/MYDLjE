package MYDLjE::M::Content::Question;
use MYDLjE::Base 'MYDLjE::M::Content';

sub COLUMNS {
    [   qw(
          id user_id pid
          data_type data_format time_created tstamp title alias
          body invisible language groups protected bad
          )
    ];
}
sub WHERE { {data_type => 'question'} }

1;

__END__

=head1 NAME

MYDLjE::M::Content - Base class for all content data_types
