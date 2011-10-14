package MYDLjE::ControlPanel::C::System;
use Mojo::Base 'MYDLjE::ControlPanel::C';
use Mojo::ByteStream qw(b);


sub settings {
  my $c = shift;
  $c->stash(stash_ok => 1);
  $c->render();
  return;
}


1;

