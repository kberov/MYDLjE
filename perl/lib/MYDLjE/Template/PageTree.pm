package MYDLjE::Template::PageTree;
use MYDLjE::Base 'MYDLjE::Template';
use utf8;
our $VERSION = '0.03';
require Mojo::Util;

has pid      => 0;
has language => 'en';

sub render {
  my $self = shift;

  return 'rendered';
}

sub render_pages {
  my ($self) = @_;
  my $uid = $self->user->id;
  $self->dbix->query(
    'SELECT id, pid, alias, page_type, permissions'
      . ' FROM pages WHERE pid=? AND domain_id AND '
      . $self->c->sql('write_permissions_sql'),
    $self->pid, $self->msession('domain_id'), $uid, $uid
  )->hashes;

}

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Template::PageTree - A back-end Pages Tree and a front-end Site Map

