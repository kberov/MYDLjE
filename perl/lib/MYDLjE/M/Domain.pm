package MYDLjE::M::Domain;
use MYDLjE::Base 'MYDLjE::M';
use MYDLjE::M::Content;


has WHERE => sub { {} };
has TABLE => sub {'my_domains'};
has COLUMNS => sub {
  [qw(id domain name description user_id group_id permissions)];
};

has FIELDS_VALIDATION => sub {
  my $self = shift;
  return {
    $self->FIELD_DEF('id'),          $self->FIELD_DEF('name'),
    $self->FIELD_DEF('permissions'), $self->FIELD_DEF('user_id'),
    $self->FIELD_DEF('group_id'),    $self->FIELD_DEF('description'),
    $self->FIELD_DEF('domain'),
  };
};
*id       = \&MYDLjE::M::Content::id;
*user_id  = \&MYDLjE::M::Content::user_id;
*group_id = \&MYDLjE::M::Content::group_id;

1;

__END__

=head1 NAME

MYDLjE::M::Domain -  record in my_domains
