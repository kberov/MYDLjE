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
use Test::More tests => 25;
use Test::Mojo;
my $t = Test::Mojo->new(app => 'MYDLjE');

for (qw(/check_readables /check_writables /check_modules)) {
  $t->get_ok($_)->status_is(200)->content_type_is('application/json')
    ->content_like(qr/\{"ok"\:/);
}
$t->get_ok('/system_config')->status_is(404)
  ->content_like(qr/has not been unboxed yet!/);
$t->post_ok('/system_config')->status_is(200)
  ->content_like(qr|"validator_errors"\:\{|);
$t->post_form_ok(
  '/system_config',
  'UTF-8',
  { site_name      => '',
    secret         => 'mydljemydljemydlje',
    db_name        => 'mydlje',
    db_user        => 'mydlje',
    db_password    => 'mydlje',
    db_host        => 'localhost',
    admin_user     => 'mydlje',
    admin_password => 'simple',
  }
  )->status_is(200)->content_type_is('application/json')
  ->content_like(qr|"validator_errors":\{|)
  ->content_like(qr|"admin_password":|)->content_like(qr|"site_name":|)
  ->content_like(qr|"validator_has_unknown_params":null|);
