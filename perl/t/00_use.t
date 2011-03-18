#!/usr/bin/env perl;
use strict;
use warnings;
use Test::More tests => 9;

use_ok('MYDLjE::Base');
use_ok('MYDLjE');
use_ok('MYDLjE::ControlPanel');
use_ok('MYDLjE::Site');
use_ok('MYDLjE::C');
use_ok('MYDLjE::ControlPanel::C');
use_ok('MYDLjE::Site::C');
use_ok('MYDLjE::M');
use_ok('MYDLjE::M::Content');
use_ok('MYDLjE::M::Content::Book');
use_ok('MYDLjE::M::Content::Article');
use_ok('MYDLjE::M::Content::Chapter');
use_ok('MYDLjE::M::Content::Answer');
use_ok('MYDLjE::M::Content::Page');
