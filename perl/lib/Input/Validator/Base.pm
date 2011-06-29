package Input::Validator::Base;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->BUILD;

    return $self;
}

sub BUILD {
}

1;
