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
use utf8;
use lib ("$ENV{MOJO_HOME}/perl/lib", "$ENV{MOJO_HOME}/perl/site/lib");
use Data::Dumper;
use Test::More;
use Test::Mojo;
use MYDLjE::Config;

my $config = MYDLjE::Config->new(
  files => [
    $ENV{MOJO_HOME} . '/conf/mydlje.development.yaml',
    $ENV{MOJO_HOME} . '/conf/mydlje-controlpanel.development.yaml'
  ]
);
unless ($config->stash('installed')) {
  plan skip_all => 'System is not installed. Will not test i18n.';
}
else {
  plan tests => 12;
}
my $t = Test::Mojo->new(app => $ENV{MOJO_APP});

$t->get_ok('/loginscreen')->status_is(200)
  ->content_like(qr/MYDLjE\:\:ControlPanel\@MYDLjE/x)
  ->text_is('#login_name_label', 'User')->element_exists('#menu_languages');
$t->get_ok('/loginscreen?ui_language=bg')->status_is(200)
  ->text_is('#login_name_label', 'Потребител');

#State is kept in $c->session
$t->get_ok('/loginscreen')->status_is(200)
  ->text_is('#login_name_label', 'Потребител');

#active language is visible
my $active_language =
  $t->tx->res->dom->at('#menu_languages a img[class=active]');
is($active_language->attrs->{alt}, 'bg', 'active language is visible');
