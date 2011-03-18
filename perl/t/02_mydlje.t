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
use Test::More tests => 36;
use Test::Mojo;

my @apps = ('MYDLjE', 'MYDLjE::ControlPanel', 'MYDLjE::Site');
for my $app (@apps) {
  my $time = time;
  my $hi   = "Controller C from $app\::C with action hi and id 1 says Hi";
  my $t    = Test::Mojo->new(app => $app);
  $t->get_ok('/hi')->status_is(200)->content_like(qr/$hi!/, $hi . '!');
  $t->get_ok('/hi/1')->status_is(200)->content_like(qr/$hi!/, $hi . '!');
  $t->post_ok('/hi/1')->status_is(200)->content_like(qr/$hi!/, $hi . '!');
  $t->get_ok('/c/hi/' . $time)->status_is(200)
    ->content_like(qr/id $time/, 'welcome message on ' . localtime($time));
}
