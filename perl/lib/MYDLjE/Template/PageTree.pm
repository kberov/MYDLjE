package MYDLjE::Template::PageTree;
use MYDLjE::Base 'MYDLjE::Template';
use utf8;
our $VERSION = '0.03';
require Mojo::Util;

has pid       => sub { shift->get('id')                           || 0 };
has language  => sub { (shift->c->req->param('content.language')) || 'en' };
has domain_id => sub { shift->msession('domain_id')               || 0 };

sub render {
  my $self = shift;

  return $self->render_pages();
}

sub render_pages {
  my ($self) = @_;
  my $html = '';
  foreach my $p (@{$self->get('pages')}) {
    $html .= $self->process('site/pages_item.html.tt', {p => $p});
  }
  return $html;
}

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Template::PageTree - A back-end Pages Tree and a front-end Site Map

