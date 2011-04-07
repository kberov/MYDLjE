package MYDLjE::I18N::en;
use base 'MYDLjE::I18N';
use strict;
use warnings;
use utf8;
our %Lexicon = (
  _AUTO          => 1,
  login_name     => 'User',
  login_password => 'Pasword',
  login_name_help =>
    'Please enter your username for the MYDLjE::ControlPanel application.',
  login_password_help =>
    'Please enter your password. It is NOT transmitted in plain text even if you are not using HTTPS protocol.',
);

1;
