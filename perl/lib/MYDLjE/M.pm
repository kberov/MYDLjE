package MYDLjE::M;
use MYDLjE::Base -base;
use MojoX::Validator;
use Carp();

has 'dbix' => sub { MYDLjE::Plugin::DBIx::instance() };
my $SQL;
my $DEBUG = $MYDLjE::DEBUG;

#conveninece for getting key/vaule arguments
sub get_args {
  return ref($_[0]) ? shift() : (@_ % 2) ? shift() : {@_};
}
sub get_obj_args { return (shift, get_args(@_)); }

#tablename
sub TABLE {
  Carp::confess(
    "You must add a table in your class: sub TABLE {'my_tablename'}");
}

#table columns
sub COLUMNS {
  Carp::confess(
    "You must add fields in your class: sub COLUMNS {['id','name','etc']}");
}

has validator => sub { MojoX::Validator->new; };

sub FIELDS_VALIDATION {
  Carp::confess('You must describe your field validations!'
      . ' See MYDLjE::M::Content::FIELDS_VALIDATION for example.');

}

#specific where clause for this class
#which will be preppended to $where argument for the select() method
sub WHERE { return {} }

#METHODS
sub new {
  my ($class, $fieds) = get_obj_args(@_);
  my $self = {data => {}};
  bless $self, $class;
  $class->make_field_attrs();
  $self->data($fieds);
  return $self;
}

#get data from satabase
sub select {    ##no critic (Subroutines::ProhibitBuiltinHomonyms)
  my ($self, $where) = get_obj_args(@_);

  #instantiate if needed
  unless (ref $self) {
    $self = $self->new();
  }
  $where = {%{$self->WHERE}, %$where};

  #TODO: Implement restoring object from session state
  $self->data(
    $self->dbix->select($self->TABLE, $self->COLUMNS, $where)->hash);
  return $self;
}

#fieldvalues HASHREF
sub data {
  my ($self, $args) = get_obj_args(@_);
  if (ref $args && keys %$args) {
    for my $field (keys %$args) {
      unless (grep { $field eq $_ } @{$self->COLUMNS()}) {
        Carp::cluck("There is not such field $field in table "
            . $self->TABLE
            . '! Skipping...');
        next;
      }
      $self->$field($args->{$field});
    }
  }

  #a key
  elsif ($args && (!ref $args)) {
    return $self->{data}{$args};
  }

  #they want all
  return $self->{data};
}

sub save {
  my ($self, $data) = get_obj_args(@_);

  #allow data to be passed directly and overwrite current data
  if (keys %$data) { $self->data($data); }

  if (!$self->id) {
    $self->dbix->insert($self->TABLE, $self->data);
    $self->id($self->dbix->last_insert_id(undef, undef, $self->TABLE, 'id'));
    return $self->id;
  }
  else {
    $self->dbix->update($self->TABLE, $self->data, {id => $self->id});
  }
  return $self->id;
}

#must be executed at the end of each module to make table/or view specific fields
sub make_field_attrs {
  my $class = shift;
  (!ref $class)
    or Carp::croak('Call this method as __PACKAGE__->make_field_attrs()');
  my $code = '';
  foreach my $column (@{$class->COLUMNS()}) {
    next if $class->can($column);    #careful: no redefine
    Carp::carp('Making sub ' . $column) if $DEBUG;
    $code .= <<"SUB";
    sub $column {
      if(\$_[1]){
        \$_[0]->{data}{$column} = \$_[0]->validate_field($column=>\$_[1]);
        #make it chainable
        return \$_[0];
      }
      return \$_[0]->{data}{$column};
    }
SUB

  }

  #I know what I am doing. I think so... warn $code;
  if (!eval $code . '1;')
  {    ##no critic (BuiltinFunctions::ProhibitStringyEval)
    Carp::confess($class . " compiler error: $/$code$/$@$/");
  }
  return;
}

#validates $value for $field against $self->FIELDS_VALIDATION->{$field} rules.
sub validate_field {
  my ($self, $field, $value) = @_;
  my $rules = $self->FIELDS_VALIDATION->{$field};

  return $value unless $rules;    #no validation rules defined

  my $field_obj = $self->validator->field($field);

  if (ref($rules->{constraints}) eq 'ARRAY'
    && scalar @{$rules->{constraints}})
  {
    foreach (@{$rules->{constraints}}) {
      $field_obj->constraint(%$_);
    }
  }
  $self->validator->validate({$field => $value});
  if ($self->validator->errors && $self->validator->errors->{$field}) {
    local $Carp::CarpLevel = 1;
    Carp::confess($self->validator->errors->{$field});
  }
  return $self->validator->values->{$field};

}

#TODO:Utility function used for passing custom SQL in Model Classes.
#$SQL is loaded from file during initialization
sub sql {
  my ($key) = @_;
  if ($key && exists $SQL->{$key}) {
    return $SQL->{$key};
  }
  Carp::cluck('Empty SQL QUERY!!! boom!!?');
  return '';
}

1;

__END__

=head1 NAME

MYDLjE::M - an oversimplified database-based objects class

=head1 DESCRIPTION

This is the base class which all classes representing  a row in a L<MYDLjE> database table should inherit. It provides some useful methods which simplify representing rows from tables as Perl objects. It is not intended to be a full featured ORM. It simply saves you from writing SQl to construct well known MYDLjE objects. If you have to do something complicated you can use L<DBIx::Simple> to issue custom SQL queries.

=head1 SYNOPSIS

  #in your class representing a template for a row in
  #a table or view or whatever database object

  package MYDLjE::M::Content::Note;
  use MYDLjE::Base 'MYDLjE::M::Content';

  sub COLUMNS {[qw(
    id user_id	pid
    data_type data_format time_created tstamp title
    body invisible language bad
  )]}

  #...somwhere in your application
  MYDLjE::M::Content::Note->select({id=>5});
  
  
=head1 ATTRIBUTES

=head1 METHODS


=head1 SEE ALSO
