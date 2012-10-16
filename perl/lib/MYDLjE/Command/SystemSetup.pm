package MYDLjE::Command::SystemSetup;
use Mojo::Base 'Mojo::Command';
use MYDLjE;
use MYDLjE::Plugin::SystemSetup;
use MYDLjE::Plugin::DBIx;
use Getopt::Long 'GetOptions';

has description => <<'EOF';
Sets up the MYDLjE system on the command line
EOF

has message => <<"EOF";

Try: $0 help SystemSetup 
for more explanations.

EOF

my $secret  = Mojo::Util::md5_sum(rand(time) . $ENV{MOJO_HOME});
my @symbols = qw|! / . < ^ & * = - > + ?|;
my %fields  = (
  'site_name'      => 'MYDLjE',
  'secret'         => $secret,
  'db_driver'      => 'DBI:mysql',
  'db_host'        => 'localhost',
  'db_name'        => '',
  'db_user'        => 'mydlje',
  'db_password'    => 'mydlje',
  'admin_user'     => 'mydlje',
  'admin_email'    => 'mydlje_' . substr($secret, 1, 3) . '@example.com',
  'admin_password' => $symbols[rand(12)]
    . substr($secret, 0, 3)
    . $symbols[rand(12)]
    . uc(substr($secret, 4, 3))
);
has usage => <<"EOF";
usage: $0 SystemSetup [OPTIONS]

$0 SystemSetup --db_name=$fields{db_name} --db_user=$fields{db_user} --db_password=mydlje...
  
These options are available:
    --db_name     Defaults to "$fields{db_name}". Note that the database must exists.
        example SQL for creating the database can be found at the beginning of:
        $ENV{MOJO_HOME}/conf/mysql.schema.sql
    --db_user     Defaults to "$fields{db_user}".
    --db_password Defaults to "$fields{db_password}".
    --db_driver   Defaults to DBI:mysql. Currently only MySQL is supported.
    Feel invited to help with support for DBI:SQLite, DBI:Pg, DBI:Oracle.
    
    --site_name      Defaults to "$fields{site_name}".
    --secret         Defaults to a random md5 sum: "$secret"
    --admin_user     Defaults to "$fields{admin_user}"
         Note: The user can not be named "admin" nor "guest"!!!
    --admin_email    Defaults to "$fields{admin_email}"
    --admin_password is a random string "$fields{admin_password}"
        The password must contain letters, numbers and at least one special character. 
        The lenght must be at least 6 characters.

EOF

has config => sub { MYDLjE::Config->singleton(); };

sub run {
  my $self = shift;
  my $local_config =
    "$ENV{MOJO_HOME}/conf/local." . lc("$ENV{MOJO_APP}.$ENV{MOJO_MODE}.yaml");
  if ($self->config->stash('installed')) {
    print "System is already installed.$/If you want to reinstall it edit$/"
      . "$local_config$/and set:$/$/installed: 0$/plugins:$/  system_setup: 1$/$/";
    return;
  }
  GetOptions(
    \%fields,       'db_name=s',     'db_user=s',   'db_password=s',
    'site_name=s',  'secret=s',      'db_driver=s', 'db_host=s',
    'admin_user=s', 'admin_email=s', 'admin_password=s'
  );
  foreach (keys %fields) {
    unless ($fields{$_}) {
      print 'All fields are required. please add --' . $_ . $self->message;
      return;
    }
  }

  my $db_config = {
    'db_name'     => $fields{db_name},
    'db_user'     => $fields{db_user},
    'db_driver'   => $fields{db_driver},
    'db_password' => $fields{db_password},
    'db_host'     => $fields{db_host},
  };
  my $dbix;
  unless (eval { $dbix = MYDLjE::Plugin::DBIx::dbix($db_config) }) {
    print $@
      . qq|$/May be a typo? Please check if the database "$fields{db_name} "|
      . "exists and you enterred correctly database username and password.$/";
    return 0;
  }

  MYDLjE::Plugin::SystemSetup::init_database($dbix, $self->config->log);
  MYDLjE::Plugin::SystemSetup::create_admin_user($dbix, \%fields);
  MYDLjE::Plugin::SystemSetup::save_config($self->config->stash, \%fields);

  print "System is operational now.$/"
    . "The following options were used:$/"
    . Data::Dumper->Dump([\%fields], ['options'])
    . "The local configuration file is:$/$local_config"
    . "$/Now log in to the administration application cpanel  "
    . "and start building your site!$/And do not forget to have fun!$/$/";

  return;
}

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Command::SystemSetup - Setup MYDLjE via commandline

=head1 SYNOPSIS

Create an empty database and give enough priviledges to your C<db_user>.

    $ mysql>
    CREATE USER 'mydlje'@'localhost' IDENTIFIED BY  'mydlje';
    GRANT USAGE ON * . * TO  'mydlje'@'localhost' IDENTIFIED BY  'mydljep' WITH
        MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 
        MAX_USER_CONNECTIONS 0 ;
    CREATE DATABASE IF NOT EXISTS  `mydlje`;
    GRANT ALL PRIVILEGES ON  `mydlje` . * TO  'mydlje'@'localhost';
    ALTER DATABASE  `mydlje` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    mysql> quit;
    Bye

On the commandline:

    # Create an empty database and give enough priviledges to db_user.
    $ cd $MOJO_HOME #Go to the folder where you unpacked MYDLjE.
    $ ./mydlje help SystemSetup
    $ ./mydlje SystemSetup --db_user=mydlje --db_name=mydlje
    System is operational now.
    The following options were used:...

=head1 DESCRIPTION

This is the command to setup MYDLjE using a terminal. 
Some people prefer to set it up this way.
This is a preferred option in cases when one wants to use aa custom server setup.
The setup using C<http://example.com/index.xhtml> is tested and is known to work 
only under Apache 2. Thus this command was implemented.

MYDLjE is finaly a set of Mojolicious applications so they should 
work in different environments.
We had some success running L<cpanel|MYDLjE::ControlPanel> under NGINX. 

=head1 SEE ALSO

L<MYDLjE::Plugin::SystemSetup>, 
L<MYDLjE::Plugin::DBIx>,
L<Mojo::Command>, 
L<Mojolicious:Commands>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.


