#!/usr/bin/env perl;
use strict;
use warnings;
use File::Basename 'dirname';
use Cwd;
use Data::Dumper;

BEGIN {

  $ENV{MOJO_MODE} ||= 'development';

  #$ENV{MOJO_MODE}='production';
  $ENV{MOJO_HOME}    = Cwd::abs_path(dirname(__FILE__) . '/../..');
  $ENV{MOJO_APP}     = 'MYDLjE::ControlPanel';
  $ENV{MYDLjE_ADMIN} = 'admin';
}

use lib ("$ENV{MOJO_HOME}/perl/lib", "$ENV{MOJO_HOME}/perl/site/lib");
use Test::More;
use Test::Mojo;
use MYDLjE::Config;
use MYDLjE::Plugin::DBIx;
use MYDLjE::M::User;

my $config = MYDLjE::Config->new(
  files => [
    $ENV{MOJO_HOME} . '/conf/mydlje.development.yaml',
    $ENV{MOJO_HOME} . '/conf/local.mydlje.development.yaml',
    $ENV{MOJO_HOME} . '/conf/mydlje-controlpanel.development.yaml',
    $ENV{MOJO_HOME} . '/conf/local.mydlje-controlpanel.development.yaml'
  ]
);

#print Dumper();
my $dbix =
  MYDLjE::Plugin::DBIx::dbix($config->stash('plugins')->{'MYDLjE::Plugin::DBIx'});

if (not $config->stash('installed')) {
  plan skip_all => 'System is not installed. Will not test cpanel.';
}
if (not $ENV{MYDLjE_ROOT_URL}) {
  plan(skip_all =>
      'Please set $ENV{MYDLjE_ROOT_URL} to the root url of your installation.');
}
$ENV{MYDLjE_ROOT_URL} =~ m|/$| or do { $ENV{MYDLjE_ROOT_URL} .= '/' };

my $t = Test::Mojo->new();

#Login functionality
#How it looks?
$t->get_ok($ENV{MYDLjE_ROOT_URL} . 'cpanel/loginscreen')->status_is(200)
  ->content_like(qr/guest\@MYDLjE\:\:ControlPanel\@MYDLjE/x)
  ->element_exists('form#login_form')->element_exists('label#login_name_label')
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
like($dom->at('label#login_name_label')->text, qr/User/x, 'Label reads: "User:"');
like($dom->at('label#login_password_label')->text,
  qr/Password/x, 'Label reads: "Password:"');
is($dom->at('button[type="submit"]')->text, 'Login', 'Button reads: "Login"');


#And mainly does it work?
$t->post_form_ok(
  $ENV{MYDLjE_ROOT_URL} . 'cpanel/loginscreen',
  'UTF-8',
  { login_name     => 'admin',
    login_password => 'admin',
  },
)->element_exists('div[class="ui-state-error ui-corner-all"]');
$dom = $t->tx->res->dom;
ok($dom->at('div[class="ui-state-error ui-corner-all"]')->text =~ m/Invalid\ssession/x,
  'Invalid session');
my $user = MYDLjE::M::User->new();

#get the first added user (during setup)
$user->WHERE(
  { disabled => 0,
    -and =>
      [\['exists(select group_id from user_group where user_id=id and group_id=1)']]
  }
);
$user->select();
my $login_name = $user->login_name;
$t = Test::Mojo->new();
$t->get_ok($ENV{MYDLjE_ROOT_URL} . 'cpanel/loginscreen');
$dom = $t->tx->res->dom;
my $session_id = $dom->at('#session_id')->attrs->{value};

$t->post_form_ok(
  $ENV{MYDLjE_ROOT_URL} . 'cpanel/loginscreen',
  'UTF-8',
  { login_name => $login_name,

    #login_password => $user->login_password,
    login_password_md5 => Mojo::Util::md5_sum($session_id . $user->login_password),
    session_id         => $session_id
  },
)->status_is(302)->header_like(Location => qr|home|x);

$t->get_ok($ENV{MYDLjE_ROOT_URL} . 'cpanel/home')->status_is(200)
  ->text_like('#title-main-header', qr/$login_name/x, 'admin user logged in')
  ->element_exists('#main-left-navigation', 'Main left navigation is present')->text_is(
  '#main-left-navigation #site li:nth-of-type(1) a',
  'Domains',
  'Domains menu item text ok'
  )->text_is(
  '#main-left-navigation #site li:nth-of-type(2) a',
  'Pages',
  'Pages menu item text ok'
  )->text_is(
  '#main-left-navigation #site li:nth-of-type(3) a',
  'Templates',
  'Templates menu item text ok'
  )->text_is(
  '#main-left-navigation #site li:nth-of-type(4) a',
  'I18N&L10N',
  'I18N&L10N menu item text ok'
  )->text_is(
  '#main-left-navigation #content li:nth-of-type(1) a',
  'Notes',
  'Notes menu item text ok'
  )->text_is(
  '#main-left-navigation #content li:nth-of-type(2) a',
  'Articles',
  'Articles menu item text ok'
  )->text_is(
  '#main-left-navigation #content li:nth-of-type(3) a',
  'Questions',
  'Articles menu item text ok'
  )->text_is(
  '#main-left-navigation #content li:nth-of-type(4) a',
  'Books',
  'Books menu item text ok'
  )->text_is(
  '#main-left-navigation #accounts li:nth-of-type(1) a',
  'Users',
  'Users menu item text ok'
  )->text_is(
  '#main-left-navigation #accounts li:nth-of-type(2) a',
  'Groups',
  'Groups menu item text ok'
  )->text_is(
  '#main-left-navigation #accounts li:nth-of-type(3) a',
  'Abilities',
  'Abilities menu item text ok'
  )->text_is(
  '#main-left-navigation #system li:nth-of-type(1) a',
  'Settings',
  'Settings menu item text ok'
  )->text_is(
  '#main-left-navigation #system li:nth-of-type(2) a',
  'Cache',
  'Cache menu item text ok'
  )->text_is(
  '#main-left-navigation #system li:nth-of-type(3) a',
  'Plugins',
  'Plugins menu item text ok'
  )->text_is('#main-left-navigation #system li:nth-of-type(4) a',
  'Log', 'Log menu item text ok')->text_is(
  '#main-left-navigation #system li:nth-of-type(5) a',
  'Files',
  'Files menu item text ok'
  )->text_is(
  '#main-left-navigation #system li:nth-of-type(6) a',
  'Preferences',
  'Preferences menu item text ok'
  );

#Test Domains
$t->get_ok($ENV{MYDLjE_ROOT_URL} . 'cpanel/site/domains')->status_is(200)
  ->element_exists('#domains_form', 'Domains list is present')
  ->element_exists('#domains_form legend .legend_icon a#new_domain_button',
  '"New Domain" button is present')

  #->element_exists('#domains_form_help', '"Domains Help" button is present')
  ->element_exists('#domains_form ul.items', 'Domains list is present')
  ->text_is('#domains_form ul.items li:nth-of-type(1) .columns .column .container',
  'localhost', 'localhost is present');

#Add Domain
$t->get_ok($ENV{MYDLjE_ROOT_URL} . 'cpanel/site/edit_domain')->status_is(200)
  ->element_exists('#edit_domain_form', '"New Domain form" is present')
  ->element_exists('#edit_domain_form legend:nth-of-type(1)', 'legend is present')
  ->text_is(
  '#edit_domain_form legend:nth-of-type(1)',
  'New Domain',
  'legend text is "New Domain"'
  )->text_is('#domain_label', 'Domain:', '"Domain:" label is ok')
  ->element_exists('input[type="text"][name="domain"]',
  '"domain" input type text is present')
  ->text_is('#name_label', 'Title/Name:', '"Title/Name:" label is ok')
  ->element_exists('input[type="text"][name="name"]',
  '"name" input type text is present')
  ->text_is('#description_label', 'Description:', '"Description:" label is ok')
  ->element_exists(
  'input[type="text"][name="description"]',
  '"description" input type text is present'
  )->text_is('#permissions_label', 'Permissions:', '"Permissions:" label is ok')
  ->element_exists(
  'input[type="text"][name="permissions"]',
  '"permissions" input type text is present'
  )->element_exists('#buttons_unit', 'Form buttons should be present')->element_exists(
  '#buttons_unit button[type="submit"][name="save"]',
  '"Save" button is present'
  )->element_exists(
  '#buttons_unit button[type="submit"][name="save_and_close"]',
  '"Save and close" button is present'
  )->element_exists('#buttons_unit button[type="reset"]', '"Reset" button is present');

#$dom = $t->tx->res->dom;

$t->post_form_ok($ENV{MYDLjE_ROOT_URL} . 'cpanel/site/edit_domain')

#there should be errors
  ->text_is(
  '#domain_error .container',
  'Please enter valid domain name!',
  '"Please enter valid domain name!" error is ok'
  )->text_is(
  '#name_error .container',
  'Please enter valid value for human readable name!',
  '"Please enter valid value for human readable name!" error is ok'
  )->text_is(
  '#description_error .container',
  'Please enter valid value for description!',
  '"Please enter valid value for description!" error is ok'
  );

#warn $dom->to_xml;
#TODO: continue with post and get for each route
#now really try to add a new domain
$t->post_form_ok($ENV{MYDLjE_ROOT_URL} . 'cpanel/site/edit_domain');

done_testing();
