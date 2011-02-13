#!/usr/bin/env perl;
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec;
use Cwd;

use Test::More tests => 16;

BEGIN {
  $ENV{MOJO_MODE} = 'development';
  $ENV{MOJO_HOME} =
    Cwd::realpath(File::Spec->rel2abs(dirname(__FILE__) . '/../..'));
}

$ENV{MOJO_APP} = 'MYDLjE::ControlPanel';
require MYDLjE::ControlPanel;
my $cp = MYDLjE::ControlPanel->new;
can_ok('MYDLjE::ControlPanel', ('config'));
isa_ok($cp, 'MYDLjE::ControlPanel');
isa_ok($cp, 'MYDLjE');
isa_ok($cp, 'Mojolicious');

require MYDLjE::ControlPanel::C;
my $cpc = MYDLjE::ControlPanel::C->new;

can_ok('MYDLjE::ControlPanel::C', ('hi'));
isa_ok($cpc, 'MYDLjE::ControlPanel::C');
isa_ok($cpc, 'MYDLjE::C');
isa_ok($cpc, 'Mojolicious::Controller');

$ENV{MOJO_APP} = 'MYDLjE::Site';
require MYDLjE::Site;
my $site = MYDLjE::Site->new;
can_ok('MYDLjE::Site', ('config'));
isa_ok($site, 'MYDLjE::Site');
isa_ok($site, 'MYDLjE');
isa_ok($site, 'Mojolicious');

require MYDLjE::Site::C;
my $sitec = MYDLjE::Site::C->new;
can_ok('MYDLjE::Site::C', ('hi'));
isa_ok($sitec, 'MYDLjE::Site::C');
isa_ok($sitec, 'MYDLjE::C');
isa_ok($sitec, 'Mojolicious::Controller');


