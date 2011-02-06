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
use Data::Dumper;
use Test::More tests => 28;
use Test::Mojo;

use MYDLjE;
my $m = MYDLjE->new();

#warn Dumper($m->config);
#exit;
SKIP: {
  my $local = "$ENV{MOJO_HOME}/conf/local.development.yaml";
  skip '$local exists', 1 if -e $local;
  cmp_ok($m->config('site_name'),
    'eq', ref($m), 'site_name is ' . $m->config('site_name'));
}
my @apps = ('MYDLjE', 'MYDLjE::ControlPanel', 'MYDLjE::Site');
for my $app (@apps) {
  my $time = time;
  my $hi   = "Controller C from $app\::C with action hi and id 1 says Hi";
  my $t    = Test::Mojo->new(app => $app);
  $t->get_ok('/hi')->status_is(200)->content_like(qr/$hi!/, $hi . '!');
  $t->get_ok('/hi/1')->status_is(200)->content_like(qr/$hi!/, $hi . '!');
  $t->get_ok('/c/hi/' . $time)->status_is(200)
    ->content_like(qr/id $time/, 'welcome message on ' . localtime($time));
}
