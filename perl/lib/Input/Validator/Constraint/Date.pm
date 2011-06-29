package Input::Validator::Constraint::Date;

use strict;
use warnings;

use base 'Input::Validator::Constraint';

require Time::Local;

sub is_valid {
    my ($self, $value) = @_;

    my %args = @{$self->args};

    my $re = $args{split} || '/';
    my ($year, $month, $day) = split($re, $value);

    return 0 unless $year && $month && $day;

    eval { Time::Local::timegm(0, 0, 0, $day, $month - 1, $year); };

    return $@ ? 0 : 1;
}

1;
__END__

=head1 NAME

Input::Validator::Constraint::Date - Date constraint

=head1 SYNOPSIS

    $validator->field('date')->constraint('date');
    $validator->field('date')->constraint('date', split => '/');

=head1 DESCRIPTION

Checks whether a value is a valid date. Date is a string with a separator (C</>
by default), that is splitted into C<year, month, day> sequence and then
validated.

=head1 METHODS

=head2 C<is_valid>

Validates the constraint.

=head1 SEE ALSO

L<Input::Validator>, L<Input::Constraint>

=cut
