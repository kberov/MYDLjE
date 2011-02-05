package MYDLjE::Base;
use Mojo::Base -base;
use strict;
use warnings FATAL => qw( all );

sub import {
  goto \&Mojo::Base::import;

  #strict->import;
  warnings->import(FATAL => qw( all ));
}

1;
