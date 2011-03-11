package MYDLjE::Plugin::DBIx;
use MYDLjE::Base 'Mojolicious::Plugin';
use DBI qw(:utils);
use DBIx::Simple;
use SQL::Abstract::Limit;
our $VERSION = '0.01';

#Singletons
my $DBIX;#DBIx::Simple instance
my %COMMON_DBH_HANDLERS = (
  RaiseError  => 1,
  HandleError => sub { Carp::confess(shift) },
  AutoCommit  => 1,
);
my $DRIVER_DBH_HANDLERS = {
  'DBI:mysql'  => {mysql_enable_utf8 => 1},
  'DBI:SQLite' => {sqlite_unicode    => 1},
  'DBI:Pg'     => {pg_enable_utf8    => 1}
};

sub register {
  my ($self, $app, $config) = @_;

  # Config
  $config ||= {};
  $app->helper('dbix', sub { dbix($config) }); 
  return;
}    #end register

sub dbix {
  my $config = shift;
  if ($DBIX) { return $DBIX; }
  $config->{db_dsn}
    ||= $config->{db_driver}
    . ':database='
    . $config->{db_name}
    . ';host='
    . $config->{db_host};

  $DBIX = DBIx::Simple->connect(
    $config->{db_dsn},
    $config->{db_user},
    $config->{db_password},
    { %COMMON_DBH_HANDLERS,
      %{$DRIVER_DBH_HANDLERS->{$config->{db_driver}} || {}}
    }
  );
  $DBIX->lc_columns = 1;
  $DBIX->abstract = SQL::Abstract::Limit->new(limit_dialect => $DBIX->dbh);
  return $DBIX;
}

1;

__END__


=head1 NAME

MYDLjE::Plugin::DBIx - DBIx::Simple + SQL::Abstract::Limit for MYDLjE

=head1 DESCRIPTION


