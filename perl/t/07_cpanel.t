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

BEGIN {
  if ($Test::More::VERSION < 0.92) {
    no warnings 'redefine';
    sub note { print @_, $/; }
    sub explain { Dumper(@_); }
  }
}
my $config = MYDLjE::Config->new(
  files => [
    $ENV{MOJO_HOME} . '/conf/mydlje.development.yaml',
    $ENV{MOJO_HOME} . '/conf/local.mydlje.development.yaml',
    $ENV{MOJO_HOME} . '/conf/mydlje-controlpanel.development.yaml',
    $ENV{MOJO_HOME} . '/conf/local.mydlje-controlpanel.development.yaml'
  ]
);

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

note 'Login functionality';
note 'How it looks?';
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

note 'Does it seem usable?';
like($dom->at('label#login_name_label')->text, qr/User/x, 'Label reads: "User:"');
like($dom->at('label#login_password_label')->text,
  qr/Password/x, 'Label reads: "Password:"');
is($dom->at('button[type="submit"]')->text, 'Login', 'Button reads: "Login"');


note 'And mainly does it work?';
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

note 'Get the first added user (during setup) and login.';
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
note 'Go to /home and check the main menu.';
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

note 'Test Domains';
$t->get_ok($ENV{MYDLjE_ROOT_URL} . 'cpanel/site/domains')->status_is(200)
  ->element_exists('#domains_form', 'Domains list is present')
  ->element_exists('#domains_form legend .legend_icon a#new_domain_button',
  '"New Domain" button is present')

  #->element_exists('#domains_form_help', '"Domains Help" button is present')
  ->element_exists('#domains_form ul.items', 'Domains list is present')
  ->text_is('#domains_form ul.items li:nth-of-type(1) .columns .column .container',
  'localhost', 'localhost is present');

note ' * Add Domain';
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


note ' * there should be errors';
$t->post_form_ok($ENV{MYDLjE_ROOT_URL} . 'cpanel/site/edit_domain')->text_is(
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

note ' * now really try to add a new domain';
my $time        = time;
my $domain_name = "example-$time.com";
my $permissions = '-rwxr-xr-x';
my $published   = 1;
my $name        = "Example test $time";
$t->post_form_ok(
  $ENV{MYDLjE_ROOT_URL} . 'cpanel/site/edit_domain',
  'UTF-8',
  { domain      => $domain_name,
    name        => $name,
    description => "Description of $time <script>malicious</script>",
    permissions => $permissions,
    published   => $published,
  }
  )->status_is(200)
  ->element_exists('#edit_domain_form', '"Edit Domain form" is present')
  ->element_exists('#edit_domain_form legend:nth-of-type(1)', 'legend is present')
  ->text_is(
  '#edit_domain_form legend:nth-of-type(1)',
  'Edit Domain',
  'legend text is "Edit Domain"'
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

$dom = $t->tx->res->dom;
my $action =
  ($dom->at('#edit_domain_form') ? $dom->at('#edit_domain_form')->attrs->{action} : '');
like($action, qr|site/edit_domain/\d+$|, 'action contains domain_id');
$action =~ m|site/edit_domain/(\d+)$|x;
my $domain_id = $1 || '0';
my $description = "Description of $time scriptmaliciousscript";

is($dom->at('input[type="text"][name="domain"]')->attrs->{value},
  $domain_name, 'name is: ' . $domain_name);
is($dom->at('input[type="text"][name="name"]')->attrs->{value},
  $name, 'name is: ' . $name);
is($dom->at('input[type="text"][name="description"]')->attrs->{value},
  $description, 'description is: ' . $description);
is($dom->at('input[type="text"][name="permissions"]')->attrs->{value},
  $permissions, 'permissions are: ' . $permissions);
is($dom->at('select[name="published"] option[selected="selected"]')->attrs->{value},
  $published, 'published is: ' . $published);

note
  ' * GET the "/site/edit_domain/" form to see that all fields have required values.';
$t->get_ok($ENV{MYDLjE_ROOT_URL} . 'cpanel/site/edit_domain/' . $domain_id)
  ->status_is(200);
$dom = $t->tx->res->dom;
$action =
  ($dom->at('#edit_domain_form') ? $dom->at('#edit_domain_form')->attrs->{action} : '');
like($action, qr|/site/edit_domain/$domain_id$|, 'action contains domain_id');
is($dom->at('input[type="text"][name="domain"]')->attrs->{value},
  $domain_name, 'name is: ' . $domain_name);
is($dom->at('input[type="text"][name="description"]')->attrs->{value},
  $description, 'description is: ' . $description);
is($dom->at('input[type="text"][name="permissions"]')->attrs->{value},
  $permissions, 'permissions are: ' . $permissions);
is($dom->at('select[name="published"] option[selected="selected"]')->attrs->{value},
  $published, 'published is: ' . $published);

note ' * Now edit it.';
$domain_name = 'www.' . $domain_name;
$name        = "Example $time";
$permissions = 'drwxr-xr-x';
$published   = 2;
$description = "Description of $time";

$t->post_form_ok(
  $ENV{MYDLjE_ROOT_URL} . 'cpanel/site/edit_domain/' . $domain_id,
  'UTF-8',
  { domain      => $domain_name,
    name        => $name,
    description => $description,
    permissions => $permissions,
    published   => $published,
  }
)->status_is(200);

note ' * Check it again to see if everything is as we changed it.';
$dom = $t->tx->res->dom;
$action =
  ($dom->at('#edit_domain_form') ? $dom->at('#edit_domain_form')->attrs->{action} : '');
like($action, qr|/site/edit_domain/$domain_id$|, 'action contains domain_id');
is($dom->at('input[type="text"][name="domain"]')->attrs->{value},
  $domain_name, 'name is: ' . $domain_name);
is($dom->at('input[type="text"][name="name"]')->attrs->{value},
  $name, 'name is: ' . $name);
is($dom->at('input[type="text"][name="description"]')->attrs->{value},
  $description, 'description is: ' . $description);
is($dom->at('input[type="text"][name="permissions"]')->attrs->{value},
  $permissions, 'permissions are: ' . $permissions);
is($dom->at('select[name="published"] option[selected="selected"]')->attrs->{value},
  $published, 'published is: ' . $published);

note '... let us clenup this mess.';

#TODO: Add pages and content in this domain
note ' * Delete domain!';
$t->get_ok($ENV{MYDLjE_ROOT_URL} . 'cpanel/site/domains')->status_is(200)
  ->element_exists('#domains_form', 'Domains list is present')
  ->content_like(qr|$domain_name|, "Domain $domain_name is in the list");
$t->get_ok(
  $ENV{MYDLjE_ROOT_URL} . 'cpanel/site/delete_domain/' . $domain_id . '?confirmed=1')
  ->content_unlike(qr|$domain_name|, "Domain $domain_name is NOT in the list");

#ENOUGH!

#TODO: continue with post and get for each route

done_testing();
