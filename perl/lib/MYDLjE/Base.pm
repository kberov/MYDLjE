package MYDLjE::Base;
use Mojo::Base -base;
use warnings FATAL => qw( all );

sub import {
  #strict->import;
  if (exists $ENV{MYDLjE_FATAL_WARNINGS} && $ENV{MYDLjE_FATAL_WARNINGS})
  {
    warnings->import(FATAL => qw( all ));
  }

  goto \&Mojo::Base::import;
}

1;
