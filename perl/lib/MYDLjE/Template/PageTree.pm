package MYDLjE::Template::PageTree;
use MYDLjE::Base 'MYDLjE::Template';
use utf8;

require Mojo::Util;

has pid => sub { shift->get('id') || 0 };
has language => sub {
  ($_[0]->c->req->param('content.language'))
    || $_[0]->app->config('plugins')->{I18N}{default};
};
has domain_id => sub { shift->msession('domain_id') || 0 };
has item_template => 'site/pages_item.html.tt';

sub render {
  my $self = shift;
  return $self->render_pages($self->_get_pages($self->c, $self->pid));
}

sub render_pages {
  my ($self, $pages) = @_;
  my $html     = '';
  my $template = $self->item_template;
  my $depth    = $self->{depth};
  foreach my $p (@$pages) {
    my $subpages_html = '';
    if ($p->{permissions} =~ /^d/x) {
      $subpages_html = $self->render_pages($self->_get_pages($self->c, $p->{id}));
    }
    $html .= $self->process(
      $template,
      { p             => $p,
        subpages_html => $subpages_html,
        depth         => $depth,
      }
    );

  }
  return $html;
}

#get pages from database or msession by pid.
sub _get_pages {
  my ($self, $c, $pid) = @_;
  $pid ||= 0;
  $self->{depth}++;
  return if $self->{depth} > 10;

  my $domain_id = $c->msession('domain_id') || 0;

  my $sql = <<"SQL";
  SELECT id, user_id, group_id, pid, alias, page_type, permissions, c.title, c.description
  FROM pages p,
  (SELECT title,description, page_id from content WHERE language=?) as c 
  WHERE p.pid=? AND p.domain_id=? and p.id !=0 
  AND p.id=c.page_id 
SQL
  $sql .= ' AND ' . $c->sql('read_permissions_sql') . ' ORDER BY sorting';

  #$c->debug($sql);
  my $uid = $c->msession->user->id;
  my $pages =
    $c->dbix->query($sql, $self->language, $pid, $domain_id, $uid, $uid, $uid)->hashes
    || [];
  return $pages;
}


1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Template::PageTree - A back-end Pages Tree and a front-end Site Map

=head1 SEE ALSO

L<MYDLjE::Template>, L<MYDLjE::PageContent>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

