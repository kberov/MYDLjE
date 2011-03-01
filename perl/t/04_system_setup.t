#!/usr/bin/env perl;
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec;
use Cwd;

BEGIN {
  $ENV{MOJO_MODE} = 'development';
  $ENV{MOJO_HOME} =
    Cwd::realpath(File::Spec->rel2abs(dirname(__FILE__) . '/../..'));
}
use Test::More tests => 12;
use Test::Mojo;
my $t = Test::Mojo->new(app => 'MYDLjE');

for (qw(/check_readables /check_writables /check_modules)) {
  $t->get_ok($_)->status_is(200)->content_type_is('application/json')
    ->content_like(qr/\{"ok"\:/);
}
