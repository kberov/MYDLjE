package MYDLjE::Base;
use Mojo::Base -base;
use warnings FATAL => qw( all );

sub import {
  goto \&Mojo::Base::import;

  #strict->import;
  if( exists $ENV{MYDLjE_FATAL_WARNINGS}
     && $ENV{MYDLjE_FATAL_WARNINGS} ){
    warnings->import(FATAL => qw( all ));
  }
}

1;
