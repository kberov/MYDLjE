package MYDLjE::M::Domain;
use MYDLjE::Base 'MYDLjE::M';
use MYDLjE::M::Content;


has WHERE => sub { {} };
has TABLE => sub {'domains'};
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

sub permissions {
  my ($self, $value) = @_;
  if (defined $value) {                     #setting
    $self->{data}{permissions} = $self->validate_field(permissions => $value);
    return $self;
  }
  return $self->{data}{permissions} ||= 'drwxr-xr-x';    #getting
}
1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::M::Domain - record in "domains" table

=head1 SYNOPSIS

    
    my $domain = MYDLjE::M::Domain->select(
      id   => $id,
      -and => [\[$c->sql('write_permissions_sql'), $user->id, $user->id]]
    );
    $domain->description('This our brand new domain');
    $domain->save();

=head1 DESCRIPTION

A MYDLjE-based system can manage one or more web-domains(sites). 
They are stored as records in the table C<domains>.

MYDLjE::M::Domain inherits all its functionality from L<MYDLjE::M>.
It has its own specific data attributes

=head1 ATTRIBUTES

This class inherits all attributes from MYDLjE::M and overrides the ones listed below.

Note also that all table-columns are available as setters and getters for the instantiated object.

=head2 COLUMNS

Retursns an ARRAYREF with all columns from table C<domains>.  These are used to automatically generate getters/setters.

=head2 TABLE

Returns the table name from which rows L<MYDLjE::M::Domain> instances are constructed: C<domains>.

=head2 FIELDS_VALIDATION

Returns a HASHREF with column-names as keys and L<MojoX::Validator> constraints used in the getters/setters when retreiving and inserting values. See below.

=head1 DATA ATTRIBUTES

=head2 id

Primary key.

=head2 domain

A fully qualifed domain name. The field is checked for validity using a regular expression 
shamelesly stollen from L<Regexp::Common>.

=head2 user_id and group_id

Tho which user and which group this domain belongs.


=head2 permissions

This field represents permissions for the current domain very much like permissions 
of a folder on a Unix system. We use i<symbolic notation> to represent permissions. The format is "tuuugggoo" where "t" can be "d","l" or "-". 

"d" is for "directory" - Domains always have the "d" flag set. 

"u" represents permissions for the owner of the page.
Valid values  for each place are "r" - read, "w" - write and "x" - execute. On eache place  instead of "r", "w" or "x" there can be "-" - none .  The last triple is for the rest of the users.

We will try to follow closely the rules for "Traditional Unix permissions" as much as they are applicable here. We will not use octal notation.
 See L<http://en.wikipedia.org/wiki/File_permissions#Traditional_Unix_permissions>.

=head1 SEE ALSO

L<MYDLjE::M::Content>, L<MYDLjE::M::User>, L<MYDLjE::M>

=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров 




