package MYDLjE::M::Session;
use MYDLjE::Base 'MYDLjE::M';
use Mojo::Util qw();
use MYDLjE::M::User;
require Time::HiRes;

has TABLE => 'sessions';

has COLUMNS => sub { [qw(id cid user_id tstamp sessiondata)] };

has FIELDS_VALIDATION => sub {
  return {
    id          => {required => 1, constraints => [{regexp => qr/^[a-f0-9]{32}$/x},]},
    cid         => {required => 0, constraints => [{regexp => qr/^\d+$/x},]},
    user_id     => {required => 1, constraints => [{regexp => qr/^\d+$/x},]},
    sessiondata => {
      required => 1,
      inflate  => sub {
        my $self = shift;
        if ($self->value && !ref($self->value)) {
          $self->value(_thaw_sessiondata($self->value));
        }
        return $self->value;
      },
      constraints => [
        { callback => sub {
            my $value = shift;

            #We inflated it but who knows
            return 1 if ($value and ref($value) eq 'HASH');
            return (0, 'Value is not a HASH reference');
            }
        },
      ]
    },
  };
};

sub user {
  my ($self, $user) = @_;
  if ($user) {
    Carp::confess('Please pass a MYDLjE::M::User instance')
      if ref($user) ne 'MYDLjE::M::User';
    $self->{user} = $user;

    $self->dbix->update('msession', {avalue => $user->id}, {name => 'USER_ID'});
  }
  else {
    $self->{user} ||= MYDLjE::M::User->select(login_name => 'guest');

  }
  return $self->{user};
}

sub new_id {
  my ($self, $new_id) = @_;
  if ($new_id) {
    Carp::confess('New session id does not look like an md5_sum!')
      unless $new_id =~ m|^[a-f0-9]{32}$|x;
    $self->{new_id} = $new_id;
  }
  if (!$self->{new_id}) {
    my $time = Time::HiRes::time();
    $self->{new_id} = Mojo::Util::md5_sum(rand($time) . rand($time) . $time);
  }
  return $self->{new_id};
}

sub user_id {
  my ($self, $user_id) = @_;
  if ($user_id) {
    $self->{data}{user_id} = $self->validate_field(user_id => $user_id);

    #synchronize
    unless ($self->{data}{user_id} == $self->user->id) {
      $self->user(MYDLjE::M::User->select(id => $user_id));
      $self->{data}{user_id} = $self->user->id;
    }
    return $self->{data}{user_id};
  }

  #user may be switched meanwhile
  elsif (!$self->{data}{user_id} || $self->{data}{user_id} != $self->user->id) {
    $self->{data}{user_id} = $self->user->id;
  }

  #we always have a user id - "guest user id" by default
  return $self->{data}{user_id};
}

sub sessiondata {
  my ($self, $sessiondata) = @_;
  if ($sessiondata) {

    #not chainable
    $self->{data}{sessiondata} = $self->validate_field(sessiondata => $sessiondata);

  }
  return $self->{data}{sessiondata} ||= {};
}

sub _freeze_sessiondata {
  my $value = shift;
  local $Carp::CarpLevel = 2;
  Carp::confess('Value for sessiondata is not a HASH reference!')
    unless ref($value) eq 'HASH';
  return $value = MIME::Base64::encode_base64(Storable::nfreeze($value));
}

sub _thaw_sessiondata {
  my $value = shift;
  ref($value)
    && Carp::confess('Value for thawing sessiondata must not be a reference!');
  return Storable::thaw(MIME::Base64::decode_base64($value));
}

sub tstamp { return $_[0]->{data}{tstamp} = time; }

sub guest { return $_[0]->user->login_name eq 'guest'; }

sub save {
  my $self = shift;

  $self->sessiondata->{user_data} = $self->user->data;
  if (!$self->id) {    #a fresh new session
    $self->id($self->new_id());
    $self->dbix->insert(
      $self->TABLE,
      { id          => $self->id,
        tstamp      => time,
        user_id     => $self->user_id,
        sessiondata => _freeze_sessiondata($self->sessiondata)
      }
    );
    return $self->id;
  }
  else {
    return $self->dbix->update(
      $self->TABLE,
      { id          => $self->id,
        tstamp      => time,
        user_id     => $self->user_id,
        sessiondata => _freeze_sessiondata($self->sessiondata)
      },
      {id => $self->id}
    );
  }
  return;
}

sub select {    ##no critic (Subroutines::ProhibitBuiltinHomonyms)
  my ($self, $where) = MYDLjE::M::get_obj_args(@_);

  #instantiate if needed
  unless (ref $self) {
    $self = $self->new();
  }
  $where = {%{$self->WHERE}, %$where};

  #TODO: Implement restoring user object from session state
  $self->data($self->dbix->select($self->TABLE, $self->COLUMNS, $where)->hash);
  if ($self->sessiondata && !ref($self->sessiondata)) {
    $self->data(sessiondata => _thaw_sessiondata($self->sessiondata));
  }

  #make a temporary table to reuse well known values in queries
  $self->dbix->dbh->do('DROP TABLE IF EXISTS msession');
  $self->dbix->dbh->do('CREATE TEMPORARY TABLE msession'
      . '(name varchar(30) NOT NULL, avalue text, PRIMARY KEY ( name ))');
  $self->dbix->insert('msession', {name => 'USER_ID', avalue => 2});

  #Restore user object from sessiondata
  if ($self->sessiondata->{user_data}) {
    $self->user(MYDLjE::M::User->new($self->sessiondata->{user_data}));
  }
  unless ($self->id) {
    $self->new_id($where->{id});
  }
  return $self;
}

#hopefully this will get called when the object goes out of scope
sub DESTROY {
  shift->save();
  return;
}

1;

__END__

=head1 NAME

MYDLjE::M::Session - MYDLjE::M based Session storage for MYDLjE

=head1 SYNOPSIS

  # get session data from database or create a new session storage object
  my $session_storage = MYDLjE::M::Session->select(id=>$c->session('id'));
  
  #do we have an authenticated user?
  my $user = $session_storage->user;
  if ($user->login_name ne 'quest'){
      #Do something specific with the user
  }


=head1 DESCRIPTION

MYDLjE::M::Session is to store session data in the MYDLjE database.
It is just an implementation of the abstract class L<MYDLjE::M>.
This functionality is internally used by L<MYDLjE::C/msession>, so if you need database based session storage use L<MYDLjE::C/msession>.

=head1 ATTRIBUTES

=head1 guest

Use this attribute to check if we have a logged in user or  the current user is guest

  sub isauthenticated {
    my $c = shift;
    if (!$c->msession->guest) {
      return 1;
    }
    else{
      $c->redirect_to('/loginscreen');
    }
    return 0;
  }

=head2 tstamp

Always returns current second since the epoch. This is stored in C<sessions.tstamp> field. 

...


=head1 METHODS

....


=head1 SEE ALSO

L<MYDLjE::C/msession>


