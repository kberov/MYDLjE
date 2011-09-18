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
use Test::More;
use Test::Mojo;
use MYDLjE::Config;
if (MYDLjE::Config->new->stash('installed')) {
  plan skip_all => 'System is already installed. Will not test system_setup.';
}

my $t = Test::Mojo->new('MYDLjE');

for (qw(/check_readables /check_writables /check_modules)) {
  $t->get_ok($_)->status_is(200)->content_type_is('application/json')
    ->content_like(qr/\{"ok"\:/);
}
$t->get_ok('/system_config')->status_is(404)
  ->content_like(qr/(not found|has not been unboxed yet!)/);
$t->post_ok('/system_config')->status_is(200)->content_like(qr|"validator_errors"\:\{|);
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
  ->content_like(qr|"validator_errors":\{|)->content_like(qr|"admin_password":|)
  ->content_like(qr|"site_name":|)
  ->content_like(qr|"validator_has_unknown_params":null|);


done_testing();

