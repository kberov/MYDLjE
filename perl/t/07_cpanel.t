#!/usr/bin/env perl;
use strict;
use warnings;
use File::Basename 'dirname';
use Cwd;

BEGIN {
  $ENV{MOJO_MODE} ||= 'development';

  #$ENV{MOJO_MODE}='production';
  $ENV{MOJO_HOME} = Cwd::abs_path(dirname(__FILE__) . '/../..');
  $ENV{MOJO_APP}  = 'MYDLjE::ControlPanel';
}

use lib ("$ENV{MOJO_HOME}/perl/lib", "$ENV{MOJO_HOME}/perl/site/lib");
use Test::More;
use Test::Mojo;
use MYDLjE::Config;

my $config = MYDLjE::Config->new(
  files => [
    $ENV{MOJO_HOME} . '/conf/mydlje.development.yaml',
    $ENV{MOJO_HOME} . '/conf/mydlje-controlpanel.development.yaml'
  ]
);
if (not $config->stash('installed')) {
  plan skip_all => 'System is not installed. Will not test cpanel.';
}
elsif (-d "$ENV{MOJO_HOME}/tmp/ctpl" and not -w "$ENV{MOJO_HOME}/tmp/ctpl") {
  plan skip_all =>
    "$ENV{MOJO_HOME}/tmp/ctpl is not writable. All tests will die.";
}
else {
  plan tests => 19;
}
my $t = Test::Mojo->new(app => $ENV{MOJO_APP});

#Login functionality
#How it looks?
$t->get_ok('/loginscreen')->status_is(200)
  ->content_like(qr/guest\@MYDLjE\:\:ControlPanel\@MYDLjE/x)
  ->element_exists('form#login_form')
  ->element_exists('label#login_name_label')
  ->element_exists('input#login_name[type="text"]')
  ->element_exists('label#login_password_label')
  ->element_exists('input#login_password[type="password"]')
  ->element_exists('input#login_password_md5[type="hidden"]')
  ->element_exists('input#session_id[type="hidden"]')
  ->element_exists('button[type="submit"]')

  #Check other hidden form for testing JS
  ->element_exists('form#other_form');
my $dom   = $t->tx->res->dom;
my $style = $dom->at('form#other_form')->attrs->{style};
ok($style =~ m/display\:none;/x, 'form#other_form is hidden');

#Does it seem usable?
like($dom->at('label#login_name_label')->text,
  qr/User/x, 'Label reads: "User:"');
like($dom->at('label#login_password_label')->text,
  qr/Password/x, 'Label reads: "Password:"');
is($dom->at('button[type="submit"]')->text, 'Login', 'Button reads: "Login"');

#And mainly does it work?
$t->post_form_ok(
  '/loginscreen',
  'UTF-8',
  { login_name     => 'admin',
    login_password => 'admin',
  },
)->element_exists('div[class="ui-state-error ui-corner-all"]');
$dom = $t->tx->res->dom;
ok(
  $dom->at('div[class="ui-state-error ui-corner-all"]')->text
    =~ m/Invalid\ssession/x,
  'Invalid session'
);

#TODO: Tests for all error messages and tests for the full login/logout flow.
