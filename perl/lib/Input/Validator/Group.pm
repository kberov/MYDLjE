package Input::Validator::Group;

use strict;
use warnings;

use base 'Input::Validator::Base';

use Input::Validator::ConstraintBuilder;

sub BUILD {
    my $self = shift;

    $self->{constraints} ||= [];
    $self->{fields}      ||= [];

    return $self;
}

sub name {
    my $self = shift;

    return $self->{name} unless @_;

    $self->{name} = $_[0];

    return $self;
}

sub error {
    my $self = shift;

    return $self->{error} unless @_;

    $self->{error} = $_[0];

    return $self;
}

sub unique { shift->constraint('unique') }
sub equal  { shift->constraint('equal') }

sub constraint {
    my $self = shift;

    my $constraint = Input::Validator::ConstraintBuilder->build(@_);

    push @{$self->{constraints}}, $constraint;

    return $self;
}

sub is_valid {
    my $self = shift;

    # Don't check if some field already has an error
    return 0 if grep {$_->error} @{$self->{fields}};

    # Get all the values
    my $values = [map { $_->value } @{$self->{fields}}];

    foreach my $c (@{$self->{constraints}}) {
        my ($ok, $error) = $c->is_valid($values);

        unless ($ok) {
            $self->error( $error ? $error : $c->error);
            return 0;
        }
    }

    return 1;
}

1;
__END__

=head1 NAME

Input::Validator::Group - Run constraint on group of fields

=head1 SYNOPSIS

    $validator->group('passwords' => [qw/password confirm_password/])->equal;

=head1 DESCRIPTION

    Run constraint on group of fields.

=head1 ATTRIBUTES

=head2 C<error>

    my $error = $group->error;

Holds group's error message.

=head2 C<name>

    $group->name('foo');
    my $name = $group->name;

Group name.

=head2 C<equal>

Shortcut

    $group->constraint(equal => @_);

=head2 C<constraint>

    $group->constraint(equal => @_);

Adds constraint to the group.

=head2 C<is_valid>

Checks whether group's constraints are valid.

=head2 C<unique>

    $group->constraint(equal => @_);

=head1 METHODS

=cut
