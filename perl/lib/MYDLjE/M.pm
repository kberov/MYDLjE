package MYDLjE::M;
use MYDLjE::Base -base;

my $SQL;

has data => sub {{}};
has table => '';
has fields =>sub {[]};
#Utility function used for passing custom SQL in Model Classes.
#$SQL is loaded from file during initialization
sub sql {
  my($key) = @_;
  if($key && exists $SQL->{$key}){
    return $SQL->{$key};
  }
  Carp::cluck('Empty SQL QUERY!!! boom!!?');
  return '';
}
1;

__END__

=head1 NAME

MYDLjE::M - base class for MYDLjE models

=head1 DESCRIPTION

Thhis is the base class which all Models should inherit.

=head1 ATTRIBUTES

=head1 METHODS


=head1 SEE ALSO
