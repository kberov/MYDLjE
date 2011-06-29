package Input::Validator::Constraint::In;

use strict;
use warnings;

use base 'Input::Validator::Constraint';

sub is_valid {
    my ($self, $value) = @_;

    return (grep { $value eq $_ } @{$self->args}) ? 1 : 0;
}

1;
__END__

=head1 NAME

Input::Validator::Constraint::In - In constraint

=head1 SYNOPSIS

    $validator->field('order')->in(1, 2, 3);

=head1 DESCRIPTION

Checks whether the value contains in the array provided.

=head1 METHODS

=head2 C<is_valid>

Validates the constraint.

=head1 SEE ALSO

L<Input::Validator>, L<Input::Constraint>

=cut
