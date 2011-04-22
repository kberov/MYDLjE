package MYDLjE::M::User;
use MYDLjE::Base 'MYDLjE::M';
use Mojo::Util qw();

has TABLE => 'my_users';

has COLUMNS => sub {
  [ qw(
      id group_id login_name login_password first_name last_name
      email description created_by changed_by tstamp reg_tstamp
      disabled start stop properties
      )
  ];
};
has FIELDS_VALIDATION => sub {
  { group_id => {required => 1, regexp => qr/^\d+$/x},
    login_name =>
      {required => 1, constraints => [{regexp => qr/^\p{IsAlnum}{4,100}$/x}]},
    login_password =>
      {required => 1, constraints => [{regexp => qr/^[a-f0-9]{32}$/x}]},
    email => {required => 1, constraints => [{'email' => 'email'},]},
    first_name => {constraints => [{length => [3, 100]}]},
    last_name  => {constraints => [{length => [3, 100]}]},
    description => {required => 0, constraints => [{length => [0, 255]},]},
    created_by  => {required => 0, regexp      => qr/^\d+$/x},
    changed_by  => {required => 0, regexp      => qr/^\d+$/x},
    disabled => {required => 0, regexp => qr/^[01]$/x},
    start    => {required => 0, regexp => qr/^\d+$/x},
    stop     => {required => 0, regexp => qr/^\d+$/x},

    #TODO: properties
  };
};

sub tstamp { return $_[0]->{data}{tstamp} = time; }

sub add {
  my ($class, $args) = MYDLjE::M::get_obj_args(@_);
  ($class eq __PACKAGE__)
    || Carp::croak(
    'Call this method only like: ' . __PACKAGE__ . '->add(%args);');
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
  my $password =
    Mojo::Util::md5_sum($args->{login_name} . $args->{login_password});
  my $time = time();
  my $user = $class->new(
    %$args,
    login_password => $password,
    tstamp         => $time,
    reg_tstamp     => $time,
  );

  my $dbix = $user->dbix;
  eval {
    $dbix->begin_work;
    $dbix->insert(
      'my_groups',
      { name        => $args->{login_name},
        description => 'Primary group for ' . $args->{login_name},
        namespaces  => $namespaces,
      }
    );
    $user->group_id($dbix->last_insert_id(undef, undef, 'my_groups', 'id'));
    my $uid = $user->save();
    unshift @$group_ids, $user->group_id;
    foreach my $gid (@$group_ids) {
      $dbix->query('INSERT INTO my_users_groups (uid,gid) VALUES(?,?)',
        $uid, $gid);
    }
    $dbix->commit;
  };
  if ($@) {
    Carp::croak("ERROR adding user(rolling back):[$@]");
    $dbix->rollback or Carp::confess($dbix->error);
  }

  return $user;
}

1;


__END__

=head1 NAME

MYDLjE::M::User - MYDLjE::M-based User class

=head1 SYNOPSIS

  my $user = MYDLjE::M::User->select(login_name=>'guest');

=head1 DESCRIPTION

This class is used to instantiate user objects. 

=head1 ATTRIBUTES

This class inherits all attributes from MYDLjE::M and overrides the ones listed below.

Note also that all columns are available as setters and getters for the instantiated object.

  id login_name login_password first_name last_name email
  description created_by changed_by tstamp reg_tstamp
  disabled start stop properties

=head2 COLUMNS

Retursns an ARRAYREF with all columns from table C<my_users>. 

=head2 TABLE

Returns the table name from which rows L<MYDLjE::M::User> instances are constructed: C<my_users>.


=head2 FIELDS_VALIDATION

Returns a HASHREF with column-names as keys and L<MojoX::Validator> constraints used when retreiving and inserting values.

=head1 METHODS


=head2 add

Inserts a new user row in C<my_users>.

A new primary group is created for the new user.

Returns an instance of L<MYDLjE::M::User> - the newly created user.

In case of database error croaks with C<ERROR adding user(rolling back):[$@]>.

Parameters:

    All columns can be passed as  key-value pairs like MYDLjE::M::select.
    group_ids - ARRAYREF with additional ids of groups to which the new user will belong
    namespaces - STRING - comma sparated list ofapplications to which 
        the new user group will have login acces - $ENV{MOJO_APP} by default 

Example:

  require MYDLjE::M::User;
  my $new_user = MYDLjE::M::User->add(
    login_name     => $values->{admin_user},
    login_password => $values->{admin_password},
    group_ids      => [1],                         #admin group
    email          => $values->{admin_email},
  );
    

    

