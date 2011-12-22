package MYDLjE::M;
use Mojo::Base -base;
use MojoX::Validator;
use Params::Check;
$Params::Check::WARNINGS_FATAL = 1;
$Params::Check::CALLER_DEPTH   = $Params::Check::CALLER_DEPTH + 1;
use Carp();
use MYDLjE::Regexp qw(%MRE);

sub dbix { return MYDLjE::Plugin::DBIx::instance() }
my $SQL   = {};
my $DEBUG = $MYDLjE::DEBUG;

#conveninece for getting key/vaule arguments
sub get_args {
  return ref($_[0]) ? shift() : (@_ % 2) ? shift() : {@_};
}
sub get_obj_args { return (shift, get_args(@_)); }

#tablename
sub TABLE {
  Carp::confess("You must add a table in your class: sub TABLE {'tablename'}");
}

#table columns
sub COLUMNS {
  Carp::confess("You must add fields in your class: sub COLUMNS {['id','name','etc']}");
}

has validator => sub { MojoX::Validator->new; };

sub FIELDS_VALIDATION {
  Carp::confess('You must describe your field validations!'
      . ' See MYDLjE::M::Content::FIELDS_VALIDATION for example.');

}

#specific where clause for this class
#which will be preppended to $where argument for the select() method
has WHERE => sub { {} };

has rows => sub { [] };

#METHODS
sub new {
  my ($class, $fields) = get_obj_args(@_);
  my $self = {data => {}};
  bless $self, $class;
  $class->make_field_attrs();
  $self->data($fields);
  return $self;
}

#get data from database
sub select {    ##no critic (Subroutines::ProhibitBuiltinHomonyms)
  my ($self, $where) = get_obj_args(@_);

  #instantiate if needed
  unless (ref $self) {
    $self = $self->new();
  }
  $where = {%$where, %{$self->WHERE}};

  $self->{data} = $self->dbix->select($self->TABLE, $self->COLUMNS, $where)->hash;
  return $self;
}

sub select_all {
  my ($self, $where) = get_obj_args(@_);

  #instantiate if needed
  unless (ref $self) {
    $self = $self->new();
  }
  $where = {%$where, %{$self->WHERE}};

  my $order = delete $where->{'order'};

  $self->{rows} =
    [$self->dbix->select($self->TABLE, $self->COLUMNS, $where, $order)->hashes];
  return $self;
}

#fieldvalues HASHREF
sub data {
  my ($self, $args) = get_obj_args(@_);
  if (ref $args && keys %$args) {
    for my $field (keys %$args) {
      unless (grep { $field eq $_ } @{$self->COLUMNS()}) {
        Carp::cluck(
          "There is not such field $field in table " . $self->TABLE . '! Skipping...')
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
  local $Carp::MaxArgLen = 0;
  if (!defined $self->id) {
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
  my $code;
  foreach my $column (@{$class->COLUMNS()}) {
    next if $class->can($column);    #careful: no redefine
    $code = "use strict;$/use warnings;$/use utf8;$/" unless $code;

    #Carp::carp('Making sub ' . $column) if $DEBUG;
    $code .= <<"SUB";
sub $class\::$column {
  my (\$self,\$value) = \@_;
  if(defined \$value){ #setting value
    \$self->{data}{$column} = \$self->validate_field($column=>\$value);
    #make it chainable
    return \$self;
  }
  return \$self->{data}{$column}; #getting value
}

SUB

  }
  $code .= "$/1;" if $code;

  #I know what I am doing. I think so... warn $code if $code;
  if ($code && !eval $code) {    ##no critic (BuiltinFunctions::ProhibitStringyEval)
    Carp::confess($class . " compiler error: $/$code$/$@$/");
  }
  return;
}

sub no_markup_inflate {
  my $filed = shift;
  my $value = $filed->value || '';

  #remove everything strange
  $value =~ s/$MRE{no_markup}//gx;

  #normalize spaces
  $value =~ s/\s+/ /gx;
  $value = substr($value, 0, 254) if length($value) > 254;
  return $value;
}

#TODO: Move ALL validation stuff to MYDLjE::Validator which will inherit MojoX::Validator.
sub domain_regexp {

#stollen from Regexp::Common::URI::RFC2396;
  my $digit       = '[0-9]';
  my $upalpha     = '[A-Z]';
  my $lowalpha    = '[a-z]';
  my $alpha       = '[a-zA-Z]';                                     # lowalpha | upalpha
  my $alphanum    = '[a-zA-Z0-9]';                                  # alpha    | digit
  my $port        = "(?:$digit*)";
  my $IPv4address = "(?:$digit+[.]$digit+[.]$digit+[.]$digit+)";
  my $toplabel    = "(?:$alpha" . "[-a-zA-Z0-9]*$alphanum|$alpha)";
  my $domainlabel = "(?:(?:$alphanum" . "[-a-zA-Z0-9]*)?$alphanum)";
  my $hostname    = "(?:(?:$domainlabel\[.])*$toplabel\[.]?)";
  my $host        = "(?:$hostname|$IPv4address)";
  my $hostport    = "(?:$host(?::$port)?)";
  return qr/^$host$/x;
}

#validates $value for $field against $self->FIELDS_VALIDATION->{$field} rules.
sub validate_field {
  my ($self, $field, $value) = @_;
  my $rules = \%{$self->FIELDS_VALIDATION->{$field}};    #copy?!

  return $value unless $rules;                           #no validation rules defined

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

#Common field definitions to be used accross all subclasses
my $id_regexp   = {regexp => qr/^\d+$/x};
my $bool_regexp = {regexp => qr/^[01]$/x};
my $FIELD_DEFS  = {
  id        => {required => 0, %$id_regexp},
  pid       => {required => 1, %$id_regexp},
  domain_id => {required => 1, %$id_regexp},
  alias32   => {required => 1, regexp => qr/^[\-_a-zA-Z0-9]{2,32}$/x,},
  alias     => {required => 1, regexp => qr/^[\-_a-zA-Z0-9]{2,255}$/x,},
  sorting => {
    required => 1,
    %$id_regexp,
    inflate => sub { return ($_[0]->value || time()) },
  },
  permissions => {

    #required => 1,
    inflate => sub { return $_[0]->value ? $_[0]->value : '-rwxr-xr-x'; },
    regexp => qr/^
      $MRE{perms}{ldn} # is this a directory, link or a regular record ?
      $MRE{perms}{rwx} # owner's permissions - (r)ead,(w)rite,e(x)ecute
      $MRE{perms}{rwx} # group's permissions - (r)ead,(w)rite,e(x)ecute
      $MRE{perms}{rwx} # other's permissions - (r)ead,(w)rite,e(x)ecute
      $/x,
  },
  user_id     => {required => 1, %$id_regexp},
  group_id    => {required => 1, %$id_regexp},
  cache       => {required => 0, %$bool_regexp},
  deleted     => {required => 0, %$bool_regexp},
  hidden      => {required => 0, %$bool_regexp},
  changed_by  => {required => 1, %$id_regexp},
  title       => {required => 0, inflate => \&no_markup_inflate},
  description => {required => 0, inflate => \&no_markup_inflate},
  domain      => {required => 1, regexp => domain_regexp()},

};
$FIELD_DEFS->{name} = $FIELD_DEFS->{title};

sub FIELD_DEF {
  my ($self, $key) = @_;
  if ($FIELD_DEFS->{$key}) {
    return ($key => $FIELD_DEFS->{$key});
  }
  Carp::cluck("No field definition for: [$key].");
  return ();
}

#some commonly used fields in tables
# validated via Params::Check::check()
my $id_allow   = {allow => qr/^\d+$/x};
my $bool_allow = {allow => qr/^[01]$/x};
my $FIELDS     = {
  id    => {required => 0, %$id_allow},
  pid   => {required => 1, %$id_allow},
  cache => {required => 0, %$bool_allow, default => 0},
  alias32 => {required => 1, allow => qr/^[\-_a-zA-Z0-9]{2,32}$/x,},
  alias   => {required => 1, allow => qr/^[\-_a-zA-Z0-9]{2,255}$/x,},
  title   => {
    required => 0,
    allow    => sub {
      $_[0] =~ s/$MRE{no_markup}//gx;
      $_[0] =~ s/\s+/ /gx;
      $_[0] = substr($_[0], 0, 254) if length($_[0]) > 254;
      return 1;
      }
  },
  permissions => {
    allow => sub{
      $_[0] ||= '-rwxr-xr-x';
      $_[0] =~ /^
      $MRE{perms}{ldn} # is this a directory, link or a regular record ?
      $MRE{perms}{rwx} # owner's permissions - (r)ead,(w)rite,e(x)ecute
      $MRE{perms}{rwx} # group's permissions - (r)ead,(w)rite,e(x)ecute
      $MRE{perms}{rwx} # other's permissions - (r)ead,(w)rite,e(x)ecute
      $/x
    },
  },
};


$FIELDS->{changed_by} = $FIELDS->{domain_id} = $FIELDS->{user_id} =
  $FIELDS->{group_id} = $FIELDS->{pid};
$FIELDS->{deleted} = $FIELDS->{cache};

#Works only with current package fields!!! So sublass MUST implement it.
sub FIELDS {
  return $_[1] ? $FIELDS->{$_[1]} : $FIELDS;
}


sub _check {
  my ($self, $key, $value) = @_;

  #warn Data::Dumper::Dumper($self->FIELDS);die;
  my $args_out =
    Params::Check::check({$key => $self->FIELDS($key) || {}}, {$key => $value});
  return $args_out->{$key};
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

=encoding utf8

=head1 NAME

MYDLjE::M - an oversimplified database-based objects class.

=head1 DESCRIPTION

This is the base class for all classes that store they data in a L<MYDLjE> database table. It was written in order to decrease dependencies from CPAN modules and keep MYDLjE small and light.

The class provides some useful methods which simplify representing rows from tables as Perl objects. It is not intended to be a full featured ORM at all. It is rather a DBA (Database Abstraction Layer). It simply saves you from writing the same SQl over and over again to construct well known MYDLjE objects stored in tables' rows. If you have to do complicated  SQL queries use directly L<DBIx::Simple/query> method. A L<DBIx::Simple> singleton instance is available as attribute in every L<MYDLjE::M> derived object. Use this base class if you want to construct Perl objects which store their data in table rows. That's it.

This code is fresh and may change at any time but I will try to keep the API relatively stable if I like it.
And of course you can always overwrite all methods from this base class at will and embed complex SQL queries in your subclasses.

=head1 SYNOPSIS

  #in your class representing a template for a row in
  #a table or view or whatever database object

  package MYDLjE::M::Content::Note;
  use Mojo::Base 'MYDLjE::M::Content';

  has TABLE => 'content';
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

  has TABLE => 'users';
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

    my $user = MYDLjE::M::User->new();
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

Instantiates an object from a saved in the database row by constructing and executing an SQL query based on the parameters. These parameters are used to construct the C<WHERE> clause for the SQL C<SELECT> statement. The API is the same as for L<DBIx::Simple/select> or L<SQL::Abstract/select> which is used internally. Prepends the L</WHERE> clause defined by you to the parameters. If a row is found puts in L</data>. Returns C<$self>.

  my $user = MYDLjE::M::User->select(id => $user_id);


=head2 select_all

Selects many records from this class L</TABLE> and this class L</COLUMNS>. 
The paramethers  C<$where> and  C<$order> are the same as described in L<SQL::Abstract>.
Returns an array reference of hashes. If you want objects, you must instantate them one by one.

  my $users_as_hashes = MYDLjE::M::User->select_all($where, $order)->rows;
  #but i need MYDLjE::M::User instances
  my @users_as_objects = map {MYDLjE::M::User->new($_)} @$userS_as_hashes;

=head2 data

Common getter/setter for all L</COLUMNS>. 
Does not validate the field when setting a value. 
Use the field specific setter if you want to be sure the input is validated 
before saving in database.

In L</select>:

  $self->data($self->dbix->select($self->TABLE, $self->COLUMNS, $where)->hash);
  
But also use the autogenereated or defined by you getters/setters.

  my $title = $self->data->{title};
  $self->data('title','My Title');
  $self->title('My Title');
  $self->title; # My Title

=head2 save

DWIM saver. If the object is fresh ( C<if (!$self-E<gt>id)> ) prepares and executes an C<INSERT> statment, otherwise preforms an C<UPDATE>. L</TABLE> is used to construct the SQL.

=head2 make_field_attrs

Called by L</new>. Prepares class specific COLUMNS based getters/setters.
You I<could> overrride it in your specific class if you want to do something special.

=head2 validate_field

Validates C<$value> for $field against C<$self-E<gt>FIELDS_VALIDATION-E<gt>{$field}> rules.
Called each time a field is set either by the specific field setter or by L</data>.

=head2 FIELD_DEF 

Returns a field definition of a commonly used field acrross many tables as 
a hash with only one key.

There are several fieldnames and types that are commonly used in database tables.
This method returns the definition of just one field by given field name.
This is particulary useful when you define a class to represent a row in a table and you 
have to define in L</FIELDS_VALIDATION> a column which is identical to another column already defined in another class.

Currently predefined fields are:

  id      => {required => 0, %$id_regexp},
  pid     => {required => 1, %$id_regexp},
  alias32 => {required => 1, regexp => qr/^[\-_a-zA-Z0-9]{3,32}$/x,},
  alias   => {required => 1, regexp => qr/^[\-_a-zA-Z0-9]{3,255}$/x,},
  sorting => {
    required => 1,
    regexp   => qr/^\d+$/x,
    inflate  => sub { return ($_[0]->value || time()) },
  },
  permissions => {
    required => 0,
    regexp   => qr/^
      [d\-]           # is this a directory - does it actually contain any children ?
      [r\-][w\-][x\-] # owner's permissions - (r)ead,(w)rite,e(x)ecute
      [r\-][w\-][x\-] # group's permissions - (r)ead,(w)rite,e(x)ecute
      [r\-][w\-][x\-] # other's permissions - (r)ead,(w)rite,e(x)ecute
      $/x,
  },
  user_id    => {required => 1, %$id_regexp},
  group_id   => {required => 1, %$id_regexp},
  cache      => {required => 0, %$bool_regexp},
  deleted    => {required => 0, %$bool_regexp},
  hidden     => {required => 0, %$bool_regexp},
  changed_by => {required => 1, %$id_regexp},


See the source of MYDLjE::M::Content and MYDLjE::M::Page for examples.


=head1 SEE ALSO

L<MYDLjE::M::User>, L<MYDLjE::M::Session>, L<MYDLjE::M::Content>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.


