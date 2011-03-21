#!/usr/bin/env perl;
use strict;
use warnings;
use File::Basename 'dirname';
use Cwd;

BEGIN {
  $ENV{MOJO_MODE} ||= 'development';

  #$ENV{MOJO_MODE}='production';
  $ENV{MOJO_HOME} = Cwd::abs_path(dirname(__FILE__) . '/../..');

  $ENV{MOJO_APP} = 'MYDLjE::ControlPanel';
  @MYDLjE::ControlPanel::ISA = ('MYDLjE');
  $ENV{MOJO_LOG_LEVEL} = 'warn';    #set to 'debug' to see what is going on
}

use lib ("$ENV{MOJO_HOME}/perl/lib", "$ENV{MOJO_HOME}/perl/site/lib");

use Data::Dumper;
use Test::More tests => 20;

my $module = 'MYDLjE::Config';
use_ok($module);
can_ok($module, 'new');
can_ok($module, 'read_config_files');
can_ok($module, 'write_config_file');
can_ok($module, 'files');

#default behavior tests
my $config = $module->new;
isa_ok($config, $module);
cmp_ok(ref($config->files), 'eq', 'ARRAY', 'files are ARRAYREF');
ok(-r $config->files->[0], 'config file is readable');
ok(ref($config->stash)            eq 'HASH', 'config stash is available');
ok(ref($config->stash('plugins')) eq 'HASH', 'plugins are available');
ok($config->stash('one', 1) == 1, 'config stash is setting');
ok($config->stash('one') == 1, 'config stash is getting');

#print Data::Dumper::Dumper($config->stash);
#exit;
ok($config->stash('routes')->{'/users'}{to}{controller} eq 'C::Users',
  'stash is merged ok');
ok($config->stash('routes')->{'/:action'}{to}{controller} eq 'C',
  'stash is merged really ok');

my $singleton  = $module->singleton;
my $singleton2 = $module->singleton;
ok($singleton eq $singleton2, 'singleton is singleton2');
ok($singleton ne $config, 'singleton is not new');
my $config2 = $module->new;

is_deeply($config2->stash, $module->singleton->stash,
  'default settings are allways the same');

#custom configs
my $config3 = $module->new(
  files => [dirname(__FILE__) . '/one.yml', dirname(__FILE__) . '/two.yaml']);
ok($config3->stash('another')->{deeper} eq 'other value', 'override ok');

#print Data::Dumper::Dumper($config3->stash);
ok($config3->stash('another')->{anothermore} eq 'yeah',   'merger ok');
ok($config3->stash('another')->{more}        eq 'always', 'merger realy ok');
