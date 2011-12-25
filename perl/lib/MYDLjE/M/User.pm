package MYDLjE::M::User;
use Mojo::Base 'MYDLjE::M';
use Mojo::Util qw();
use Scalar::Util qw(blessed reftype);
use Email::Address;
use List::Util;
use MYDLjE::M::Content;
use MYDLjE::Regexp qw(%MRE);

has TABLE => 'users';

has COLUMNS => sub {
  [ qw(
      id group_id login_name login_password first_name last_name
      email description created_by changed_by tstamp reg_tstamp
      disabled start stop properties
      )
  ];
};
has FIELDS_VALIDATION => sub {
  my $self   = shift;
  my $fields = {
    ##no critic qw(ValuesAndExpressions::ProhibitCommaSeparatedStatements)
    $self->FIELD_DEF('id'),
    $self->FIELD_DEF('group_id'),
    login_name =>
      {required => 1, constraints => [{regexp => qr/^\p{IsAlnum}{4,100}$/x}]},
    login_password =>
      {required => 1, constraints => [{regexp => qr/^[a-f0-9]{32}$/x}]},
    email => {required => 1, constraints => [{'email' => 'email'},]},
    first_name => {constraints => [{length => [3, 100]}]},
    last_name  => {constraints => [{length => [3, 100]}]},
    description => {required => 0, constraints => [{length => [0, 255]},]},
    created_by  => {required => 0, regexp      => qr/^\d+$/x},
    $self->FIELD_DEF('changed_by'),
    disabled => {required => 0, regexp => qr/^[01]$/x},
    start    => {required => 0, regexp => qr/^\d+$/x},
    stop     => {required => 0, regexp => qr/^\d+$/x},

    #TODO: properties
  };
  return $fields;
};

my $FIELDS = {
  %{MYDLjE::M->FIELDS},
  login_name     => {required => 1, allow => qr/^\p{IsAlnum}{4,100}$/x},
  login_password => {required => 1, allow => qr/^[a-f0-9]{32}$/x},
  email          => {
    required => 1,
    allow    => qr/$Email::Address::addr_spec/x
  },
  last_name => {
    default => '',
    allow   => ['', qr/^(\p{IsAlnum}[\p{IsAlnum}\-\.\s]{3,100})$/x]
  },
};
$FIELDS->{first_name} = $FIELDS->{last_name};
$FIELDS->{created_by} = $FIELDS->{changed_by};
$FIELDS->{disabled}   = $FIELDS->{deleted};

sub FIELDS { return $_[1] ? $FIELDS->{$_[1]} : $FIELDS; }

{
  no warnings qw(once);
  *id     = \&MYDLjE::M::Content::id;
  *tstamp = \&MYDLjE::M::Content::tstamp;
  *start  = \&MYDLjE::M::Content::start;
  *stop   = \&MYDLjE::M::Content::stop;
}

has groups => sub {
  my $self = shift;
  return [
    $self->dbix->query(
      'SELECT g.* FROM groups g,user_group ug WHERE ug.user_id=? AND ug.group_id=g.id',
      $self->id
      )->hashes
  ];
};


sub add {
  my ($class, $args) = MYDLjE::M::get_obj_args(@_);
  ($class eq __PACKAGE__)
    || Carp::croak('Call this method only like: ' . __PACKAGE__ . '->add(%args);');
  $args->{namespaces} ||= $ENV{MOJO_APP};

  #groups to which this user will belong
  if ($args->{group_ids}) {
    ref($args->{group_ids}) eq 'ARRAY'
      || Carp::croak('"group_ids" must be an Array reference of group ids');
  }
  else {
    $args->{group_ids} = [];
  }
  my $group_ids  = delete $args->{group_ids};
  my $namespaces = delete $args->{namespaces};
  my $password   = Mojo::Util::md5_sum($args->{login_name} . $args->{login_password});
  my $time       = time();
  my $user       = $class->new(
    %$args,
    login_password => $password,
    tstamp         => $time,
    reg_tstamp     => $time,
  );

  my $dbix    = $user->dbix;
  my $eval_ok = eval {
    $dbix->begin_work;
    $dbix->insert(
      'groups',
      { name        => $args->{login_name},
        description => 'Primary group for ' . $args->{login_name},
        namespaces  => $namespaces,
      }
    );
    $user->group_id($dbix->last_insert_id(undef, undef, 'groups', 'id'));
    my $uid = $user->save();
    unshift @$group_ids, $user->group_id;
    foreach my $gid (@$group_ids) {
      $dbix->query('INSERT INTO user_group (user_id, group_id) VALUES(?,?)', $uid,
        $gid);
    }
    $dbix->commit;
  };
  unless ($eval_ok) {
    $dbix->rollback or Carp::confess($dbix->error);
    Carp::croak("ERROR adding user(rolling back):[$@]");
  }

  return $user;
}

sub _validate_row {
  my ($row) = @_;
  unless ((reftype($row) eq 'HASH')
    && $row->{permissions}
    && $row->{user_id}
    && $row->{group_id})
  {
    local $Carp::CarpLevel = 2;
    Carp::confess(
          'Please pass a HASH reference($db_row_obj->data()) containing at least'
        . '"permissions", "user_id" and "group_id" fields!');
  }
}

sub can_read {
  my ($self, $row) = @_;
  _validate_row($row);

  #everybody can read or is owner
  if (
    $row->{permissions} =~ /^[\w\-]{7}r/x
    || ( $self->id == $row->{user_id}
      && $row->{permissions} =~ /^[\w\-]r/x)
    )
  {
    return 1;
  }

  #is in a suitable group
  if ((List::Util::first { $row->{group_id} == $_->{id} } @{$self->groups})
    && $row->{permissions} =~ /^[\w\-]{4}r/x)
  {
    return 1;
  }

  #is in admin group
  return $self->is_admin;
}

sub can_write {
  my ($self, $row) = @_;
  _validate_row($row);

  #everybody can write or is owner
  if (
    $row->{permissions} =~ /^[\w\-]{8}w/x
    || ( $self->id == $row->{user_id}
      && $row->{permissions} =~ /^[\w\-]{2}w/x)
    )
  {
    return 1;
  }

  #is in a suitable group
  if ((List::Util::first { $row->{group_id} == $_->{id} } @{$self->groups})
    && $row->{permissions} =~ /^[\w\-]{5}w/x)
  {
    return 1;
  }

  #is in admin group
  return $self->is_admin;
}

sub can_execute {

  my ($self, $row) = @_;
  _validate_row($row);

  #everybody can write or is owner
  if (
    $row->{permissions} =~ /^[\w\-]{9}x/x
    || ( $self->id == $row->{user_id}
      && $row->{permissions} =~ /^[\w\-]{3}x/x)
    )
  {
    return 1;
  }

  #is in a suitable group
  if ((List::Util::first { $row->{group_id} == $_->{id} } @{$self->groups})
    && $row->{permissions} =~ /^[\w\-]{6}x/x)
  {
    return 1;
  }

  #is in admin group
  return $self->is_admin;
}

sub is_admin {
  my $self = shift;

  #is in admin group
  if (List::Util::first { $_->{name} eq 'admin' } @{$self->groups}) {
    return 1;
  }
  return 0;

}

1;


__END__

=encoding utf8

=head1 NAME

MYDLjE::M::User - MYDLjE::M-based User class

=head1 SYNOPSIS

  my $user = MYDLjE::M::User->select(login_name=>'guest');

=head1 DESCRIPTION

This class is used to instantiate user objects. 

=head1 DATA ATTRIBUTES

This class inherits all attributes from MYDLjE::M and overrides the ones listed below.

Note also that all columns are available as setters and getters for the instantiated object.

  id login_name login_password first_name last_name email
  description created_by changed_by tstamp reg_tstamp
  disabled start stop properties

=head1 ATTRIBUTES

=head2 COLUMNS

Retursns an ARRAYREF with all columns from table C<users>. 

=head2 TABLE

Returns the table name from which rows L<MYDLjE::M::User> instances are constructed: C<users>.


=head2 FIELDS_VALIDATION

Returns a HASHREF with column-names as keys and L<MojoX::Validator> constraints used when retreiving and inserting values.

=head2 groups

Returns a list of HASHREFs. These are the groups the user is member of.


=head1 METHODS


=head2 add

Inserts a new user row in C<users> and adds a new primary group for the new user.

Returns an instance of L<MYDLjE::M::User> - the newly created user.

In case of database error croaks with C<ERROR adding user(rolling back):[$@]>.

Parameters:

    #All columns can be passed as  key-value pairs like MYDLjE::M::select.
    #group_ids - ARRAYREF with additional ids of groups to which the new user will belong
    #namespaces - STRING - comma sparated list ofapplications to which 
    #    the new user group will have login acces - $ENV{MOJO_APP} by default 

Example:

  require MYDLjE::M::User;
  my $new_user = MYDLjE::M::User->add(
    login_name     => $values->{admin_user},
    login_password => $values->{admin_password},
    group_ids      => [1],                         #admin group
    email          => $values->{admin_email},
  );

=head2 can_read

Checks if the user can read the passed database record. The record must be a HASH reference
and have at least "permissions", "user_id" and "group_id" fields. 
Returns 1 on succes, 0 otherwise. Note that it is best to filter records by permissions 
in your SQL queries so you do not have to fetch needleslly data from the database and then check 
if it is accessible by the user. 
This method is for cases when you could not check earlier.

  if($c->msession->user->can_read($page->data)){
    #show the record
  }

=head2 can_write

Checks if the user can edit the passed database record. The record must be a HASH reference
and have at least "permissions", "user_id" and "group_id" fields. 
Returns 1 on succes, 0 otherwise. Note that it is best to filter records by permissions 
in your SQL queries so you do not have to fetch needleslly data from the database and then check 
if it is accessible by the user. 
This method is for cases when you could not check using SQL. See I<conf/mysql.queries.sql>

Examples:

  #in SQL (no check if user is admin)
  SELECT * FROM pages WHERE  
  (
    (user_id = ? AND permissions LIKE '__w%')
    OR ( group_id IN (SELECT group_id FROM user_group WHERE user_id= ?) 
      AND permissions LIKE '_____w%')   
  )
  
  #in perl code
  if($c->msession->user->can_write($page->data)){
    #show the record
  }

=head2 is_admin

Checks if the user is member of the "admin" group.
Returns 1 on succes, 0 otherwise.

=head1 SEE ALSO

L<MYDLjE::M>, L<MYDLjE::M::Session>, L<MYDLjE::M::Content>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.



