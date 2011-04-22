package MYDLjE::M;
use MYDLjE::Base -base;
use MojoX::Validator;
use Carp();

sub dbix { return MYDLjE::Plugin::DBIx::instance() }
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
has WHERE => sub { {} };

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
  $where = {%$where, %{$self->WHERE}};

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
            . '! Skipping...')
          if $DEBUG;
        next;
      }
      $self->$field($args->{$field});
    }
  }

  #a key
  elsif ($args && (!ref $args)) {
    return $self->$args;
  }

  #they want all what we have in $self->{data}
  return $self->{data};
}

sub save {
  my ($self, $data) = get_obj_args(@_);

  #allow data to be passed directly and overwrite current data
  if (keys %$data) { $self->data($data); }

  if (!$self->id) {
    delete $self->{data}{id} if exists $self->{data}{id};
    $self->dbix->insert($self->TABLE, $self->data);
    $self->id($self->dbix->last_insert_id(undef, undef, $self->TABLE, 'id'));
    return $self->id;
  }
  else {
    return $self->dbix->update($self->TABLE, $self->data, {id => $self->id});
  }
  return;
}

sub make_field_attrs {
  my $class = shift;
  (!ref $class)
    || Carp::croak('Call this method as __PACKAGE__->make_field_attrs()');
  my $code = '';
  foreach my $column (@{$class->COLUMNS()}) {
    next if $class->can($column);    #careful: no redefine

    #Carp::carp('Making sub ' . $column) if $DEBUG;
    $code .= <<"SUB";
    sub $class\::$column {
      if(\$_[1]){ #setting value
        \$_[0]->{data}{$column} = \$_[0]->validate_field($column=>\$_[1]);
        #make it chainable
        return \$_[0];
      }
      return \$_[0]->{data}{$column};#getting value
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

  my $field_obj   = $self->validator->field($field);
  my $constraints = delete $rules->{constraints};
  for my $method (keys %$rules) {
    $field_obj->$method($rules->{$method});
  }

  if (ref($constraints) eq 'ARRAY'
    && scalar @$constraints)
  {
    foreach (@$constraints) {
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

MYDLjE::M - an oversimplified database-based objects class.

=head1 DESCRIPTION

This is the base class for all classes that store they data in a L<MYDLjE> database table. It was written in order to not increase dependencies from CPAN modules and keep MYDLjE small and light.

The class provides some useful methods which simplify representing rows from tables as Perl objects. It is not intended to be a full featured ORM at all. It simply saves you from writing SQl to construct well known MYDLjE objects stored in tables. If you have to do complicated  SQL queries use L<DBIx::Simple/query> method. Use this base class if you want to have perl objects which store their data in table rows. That's it.

This code is fresh and may change at any time but I will try to keep the API relatively stable if I like it.
And of course you can always overwite all methods from the base class at will and embed complex SQL queries in your subclasses.

=head1 SYNOPSIS

  #in your class representing a template for a row in
  #a table or view or whatever database object

  package MYDLjE::M::Content::Note;
  use MYDLjE::Base 'MYDLjE::M::Content';

  has TABLE => 'my_content';
  has COLUMNS => sub {
    [ qw(
        id user_id pid
        data_type data_format time_created tstamp title alias
        body invisible language groups protected bad
        )
    ];
  };
  has WHERE => sub { {data_type => 'note'} };
  
  sub FIELDS_VALIDATION {
  return {
    id      => {required => 0, constraints => [{regexp => qr/^\d+$/x},]},
    user_id => {required => 1, constraints => [{regexp => qr/^\d+$/x},]},
    alias   => {
      required    => 1,
      constraints => [{regexp => qr/^[\-_a-z0-9]{2,255}$/x},]
    },
    #...
  }
}


  #...somewhere in your application or controller or a custom script
  my $note = MYDLjE::M::Content::Note->select({id=>5});
  #or
  my $user = MYDLjE::M::User->select(login_name => 'guest')
  $user->password(Mojo::Util::md5_sum('myverysecReTPasWord123'));
  
  #do whatwever you do with this object, then save it
  $user->save;
  
  #or create something really fresh
  my $question = MYDLjE::M::Content::Question->new(
    user_id => $c->msession->user_id,
    title   => 'How to cook with MYDLjE?',
    body    => '<p>I really want to know where to start from. Should I....</p>'
    ...
  );
  
  
=head1 ATTRIBUTES

=head2 dbix

This is an L<MYDLjE::Plugin::DBIx/instance> and (as you guessed) provides direct access
to the current DBIx::Simple instance with L<SQL::Abstract> support.

=head2 TABLE

You must define this attribute in your subclass. This is the table where your object
will store its data. Must return a string - the table name. It is used  internally in L<select>
when retreiving a row from the database and when saving object data.

  has TABLE => 'my_users';
  # in select()
  $self->data(
    $self->dbix->select($self->TABLE, $self->COLUMNS, $where)->hash);

  

=head2 COLUMNS

You must define this attribute in your subclass. 
It must return an ARRAYREF with table columns to which the data is written.
It is used  internally in L<select> when retreiving a row from the database and when saving object data.

  has COLUMNS => sub { [qw(id cid user_id tstamp sessiondata)] };
  # in select()
  $self->data(
    $self->dbix->select($self->TABLE, $self->COLUMNS, $where)->hash);


=head2 FIELDS_VALIDATION

You must define this attribute in your subclass. 
It must return a HASHREF with column names as keys and "types" constratints as values
interpretted by L<validate_field> which will check and validate the value of a column
each time a new value is set.

  has FIELDS_VALIDATION => sub {
    { login_name =>
        {required => 1, constraints => [{regexp => qr/^\p{IsAlnum}{4,100}$/x}]},
      login_password =>
        {required => 1, constraints => [{regexp => qr/^[a-f0-9]{32}$/x}]},
      email => {required => 1, constraints => [{'email' => 'email'},]},
      first_name => {constraints => [{length => [3, 100]}]},
      last_name  => {constraints => [{length => [3, 100]}]},
      #...
    }
  };
  
=head2 validator

MojoX::Validator instance used to validate the fields as described in L</FIELDS_VALIDATION>.

=head2 WHERE

Specific C<WHERE> clause for your class which will be appended to C<where> arguments for the L</select> method. Empty by default.

  has WHERE => sub { {data_type => 'note'} };

You can redefine the WHERE clause for the object data population just after instatntiating an empty object and before calling select to populate it with data.

    my $user =MYDLjE::M::User->new();
    $user->WHERE({disabled =>0, });
    $user->select(id=>1);

=head1 METHODS

=head2 new

The constructor. Instantiates a fresh MYDLjE::M based object. Generates getters and setters for the fields described in L</COLUMNS>. Sets the passed parameters as fields if they exists as column names.

  #Restore user object from sessiondata
  if($self->sessiondata->{user_data}){
    $self->user(MYDLjE::M::User->new($self->sessiondata->{user_data}));
  }

=head2 select

Restores a saved in the database object by constructing an SQL query based on the parameters. The API is the same as for L<DBIx::Simple/select> or L<SQL::Abstract/select> which is used internally. Prepends the L</WHERE> clause defined by you to the parameters. If a row is found puts in L</data>. Returns C<$self>.

  my $user = MYDLjE::M::User->select(id => $user_id);
  
=head2 data

Common getter/setter for all L</COLUMNS>.

In L</select>:

  $self->data($self->dbix->select($self->TABLE, $self->COLUMNS, $where)->hash);
  
But also use the autogenereated or defined by you getters/setters.

  my $title = $self->data->{title};
  $self->data('title','My Title');
  $self->title('My Title');
  $self->title; # My Title

=head2 save

DWIM saver. If the object is fresh inserts it in the L</TABLE>, otherwise updates it.

=head2 make_field_attrs

Called by L</new>. Prepares class specific COLUMNS based getters/setters.
You could overrride it in your specific class if you want to do something special.

=head2 validate_field

Validates C<$value> for $field against C<$self-E<gt>FIELDS_VALIDATION-E<gt>{$field}> rules.
Called each time a field is set either by the specific field setter or by L</data>.


=head1 SEE ALSO

L<MYDLjE::M::User>, L<MYDLjE::M::Session>, L<MYDLjE::M::Content>
