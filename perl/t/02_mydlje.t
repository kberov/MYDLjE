#!/usr/bin/env perl;
use strict;
use warnings;
use File::Basename 'dirname';
use Cwd;

BEGIN {
  $ENV{MOJO_MODE} ||= 'development';

  #$ENV{MOJO_MODE}='production';
  $ENV{MOJO_HOME} = Cwd::abs_path(dirname(__FILE__) . '/../..');
}

use lib ("$ENV{MOJO_HOME}/perl/lib", "$ENV{MOJO_HOME}/perl/site/lib");
use Data::Dumper;
use Test::More tests => 54;
use Test::Mojo;

my @apps = ('MYDLjE', 'MYDLjE::ControlPanel', 'MYDLjE::Site');
my $i = 0;
for my $app (@apps) {
  my $time = time;
  my $hi   = "Controller C from $app\::C with action hi and id 1 says Hi";
  my $t    = Test::Mojo->new(app => $app);
  $t->get_ok('/hi')->status_is(200)->content_like(qr/$hi!/, $hi . '!');
  $t->get_ok('/hi/1')->status_is(200)->content_like(qr/$hi!/, $hi . '!');
  $t->post_ok('/hi/1')->status_is(200)->content_like(qr/$hi!/, $hi . '!');
  $t->get_ok('/c/hi/' . $time)->status_is(200)
    ->content_like(qr/id $time/, 'welcome message on ' . localtime($time));
  #Test msession
  my $i = 0;
  $i++;
  $t->get_ok('/hisession')->status_is(200)
    ->content_like(qr/\:$i/, 'mession is: '.$i );
  $i++;
  $t->get_ok('/hisession')->status_is(200)
    ->content_like(qr/\:$i/, 'mession is: '.$i );
}

