#!/usr/bin/env perl;
use strict;
use warnings;
use Test::More tests => 18;

use MYDLjE::ControlPanel::C;
my $cpc = MYDLjE::ControlPanel::C->new;

can_ok('MYDLjE::ControlPanel::C', ('hi'));
isa_ok($cpc, 'MYDLjE::ControlPanel::C');
isa_ok($cpc, 'MYDLjE::C');
isa_ok($cpc, 'Mojolicious::Controller');

use MYDLjE::Site::C;
my $sitec = MYDLjE::Site::C->new;
can_ok('MYDLjE::Site::C', ('hi'));
isa_ok($sitec, 'MYDLjE::Site::C');
isa_ok($sitec, 'MYDLjE::C');
isa_ok($sitec, 'Mojolicious::Controller');

use MYDLjE::ControlPanel my $cp = MYDLjE::ControlPanel->new;
can_ok('MYDLjE::ControlPanel', ('config'));
can_ok('MYDLjE::ControlPanel', ('read_config'));
isa_ok($cp, 'MYDLjE::ControlPanel');
isa_ok($cp, 'MYDLjE');
isa_ok($cp, 'Mojolicious');

use MYDLjE::Site;
my $site = MYDLjE::Site->new;
can_ok('MYDLjE::Site', ('config'));
can_ok('MYDLjE::Site', ('read_config'));
isa_ok($site, 'MYDLjE::Site');
isa_ok($site, 'MYDLjE');
isa_ok($site, 'Mojolicious');


