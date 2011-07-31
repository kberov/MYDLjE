package MYDLjE::Plugin::DBIx;
use MYDLjE::Base 'Mojolicious::Plugin';
use DBI qw(:utils);
use DBIx::Simple;
use SQL::Abstract;
use Mojo::DOM;
use Carp;
our $VERSION = '0.1';

#Singletons
my $DBIX;    #DBIx::Simple instance
my %COMMON_DBH_HANDLERS = (
  RaiseError  => 1,
  HandleError => sub { Carp::confess(shift) },
  AutoCommit  => 1,
);
my $DRIVER_DBH_HANDLERS = {
  'DBI:mysql'  => {mysql_enable_utf8 => 1, mysql_bind_type_guessing => 1},
  'DBI:SQLite' => {sqlite_unicode    => 1},
  'DBI:Pg'     => {pg_enable_utf8    => 1}
};

sub register {
  my ($self, $app, $config) = @_;

  # Config
  $config ||= {};
  $app->helper('dbix', sub { dbix($config, $self, $app) });

  my $xml_sql =
    Mojo::Asset::File->new(path => $app->home . '/conf/mysql.queries.sql')->slurp;
  my $dom = Mojo::DOM->new(charset => $app->config('plugins')->{charset}{charset});
  $dom->parse($xml_sql);
  my $queries = {};
  for my $q ($dom->find('query[name]')->each) {

    #$app->log->debug("query[name]: " . $q->attrs->{name});
    my $query = $q->text;

    #Treat string as multiple lines.
    $query =~ s/--.*?$//xmg;
    $queries->{$q->attrs->{name}} = $query;
  }

  $app->helper(
    sql => sub {
      my ($c, $name) = @_;
      if (exists $queries->{$name}) {
        return $queries->{$name};
      }
      return $queries;
    }
  );
  $app->helper(
    sql_limit => sub {
      my ($c, $offset, $rows) = @_;
      $offset ||= 0;
      if (!$rows) {
        $rows   = $offset;
        $offset = 0;
      }
      $rows ||= $config->{limit} || 50;
      $queries->{LIMIT} =~ s/offset/$offset/x;
      $queries->{LIMIT} =~ s/rows/$rows/x;
      return $queries->{LIMIT};
    }
  );
  return;
}    #end register

sub dbix {
  my $config = shift;
  my $c      = shift;
  my $app    = shift;
  if ($DBIX) { return $DBIX; }
  $config->{db_dsn}
    ||= $config->{db_driver}
    . ':database='
    . $config->{db_name}
    . ';host='
    . $config->{db_host};

  $DBIX = DBIx::Simple->connect(
    $config->{db_dsn}, $config->{db_user},
    $config->{db_password},
    {%COMMON_DBH_HANDLERS, %{$DRIVER_DBH_HANDLERS->{$config->{db_driver}} || {}}}
  );
  $DBIX->lc_columns = 1;
  if ($config->{debug}) {
    $DBIX->dbh->{Callbacks} = {
      prepare => sub {
        my ($dbh, $query, $attrs) = @_;

        $app && $app->log->debug("Preparing query:\n$query\n");
        return;
      },
    };
  }
  $DBIX->abstract = SQL::Abstract->new();
  return $DBIX;
}

sub instance {
  return $DBIX
    || Carp::confess(__PACKAGE__
      . ' is not instantiated. Do $app->plugin("'
      . __PACKAGE__
      . '"); to instatiate it');
}
1;

__END__


=head1 NAME

MYDLjE::Plugin::DBIx - DBIx::Simple + SQL::Abstract for MYDLjE

=head1 DESCRIPTION

This is a standart Plugin for MYDLjE. It provides two helpers - L<dbix> and L<sql>.


