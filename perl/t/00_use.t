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

use Test::More tests => 31;

use_ok('MYDLjE::Base');
use_ok('MYDLjE');
use_ok('MYDLjE::ControlPanel');
use_ok('MYDLjE::Site');
use_ok('MYDLjE::C');
use_ok('MYDLjE::ControlPanel::C');
use_ok('MYDLjE::ControlPanel::C::Accounts');
use_ok('MYDLjE::ControlPanel::C::Auth');
use_ok('MYDLjE::ControlPanel::C::Content');
use_ok('MYDLjE::ControlPanel::C::Home');
use_ok('MYDLjE::ControlPanel::C::Site');
use_ok('MYDLjE::ControlPanel::C::System');
use_ok('MYDLjE::Site::C');
use_ok('MYDLjE::Site::C::Site');
use_ok('MYDLjE::M');
use_ok('MYDLjE::M::Domain');
use_ok('MYDLjE::M::Session');
use_ok('MYDLjE::M::User');
use_ok('MYDLjE::M::Group');
use_ok('MYDLjE::M::Content');
use_ok('MYDLjE::M::Content::Book');
use_ok('MYDLjE::M::Content::Article');
use_ok('MYDLjE::M::Content::Chapter');
use_ok('MYDLjE::M::Content::Answer');
use_ok('MYDLjE::M::Content::Page');
use_ok('MYDLjE::Template::PageTree');
use_ok('MYDLjE::Template::PageContent');
use_ok('MYDLjE::I18N::en');
use_ok('MYDLjE::I18N::bg');
use_ok('MYDLjE::I18N::ru');
use_ok('MYDLjE::I18N::de');

