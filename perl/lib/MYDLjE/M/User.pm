package MYDLjE::M::User;
use MYDLjE::Base 'MYDLjE::M';
use Mojo::Util qw();

has TABLE => 'my_users';

has COLUMNS => sub {
  [ qw(
      id login_name login_password first_name last_name email
      description created_by changed_by tstamp reg_tstamp
      disabled start stop properties
      )
  ];
};
has FIELDS_VALIDATION => sub {
  { login_name =>
      {required => 1, constraints => [{regexp => qr/^\p{IsAlnum}{4,100}$/x}]},
    login_password =>
      {required => 1, constraints => [{regexp => qr/^[a-f0-9]{32}$/x}]},
    email => {required => 1, constraints => [{'email' => 'email'},]},
    first_name => {constraints => [{length => [3, 100]}]},
    last_name  => {constraints => [{length => [3, 100]}]},
    description => {required => 0, constraints => [{length => [0, 100]},]},
    created_by  => {required => 0, regexp      => qr/^\d+$/x},
    changed_by  => {required => 0, regexp      => qr/^\d+$/x},
    disabled => {required => 0, regexp => qr/^[01]$/x},
    start    => {required => 0, regexp => qr/^\d+$/x},
    stop     => {required => 0, regexp => qr/^\d+$/x},

    #TODO: properties
  };
};

sub tstamp { return $_[0]->{data}{tstamp} = time; }


1;


__END__

=head1 NAME

MYDLjE::M::User - MYDLjE::M based User class

=head1 SYNOPSIS

  my $user = MYDLjE::M::User->select(login_name=>'guest');

=head1 DESCRIPTION
