package Template::Alloy::Iterator;

=head1 NAME

Template::Alloy::Iterator - Handle foreach iterations

=cut

use strict;
use warnings;

sub new {
    my ($class, $items) = @_;
    $items = [] if ! defined $items;
    if (ref($items) eq 'HASH') {
	$items = [ map { {key => $_, value => $items->{ $_ }} } sort keys %$items ];
    } elsif (UNIVERSAL::can($items, 'as_list')) {
	$items = $items->as_list;
    } elsif (ref($items) ne 'ARRAY') {
        $items = [$items];
    }
    return bless [$items, 0], $class;
}

sub get_first {
    my $self = shift;
    return (undef, 3) if ! @{ $self->[0] };
    return ($self->[0]->[$self->[1] = 0], undef);
}

sub get_next {
    my $self = shift;
    return (undef, 3) if ++ $self->[1] > $#{ $self->[0] };
    return ($self->items->[$self->[1]], undef);
}

sub items { shift->[0] }

sub index { shift->[1] }

sub max { $#{ shift->[0] } }

sub size { shift->max + 1 }

sub count { shift->index + 1 }

sub number { shift->index + 1 }

sub first { (shift->index == 0) || 0 }

sub last { my $self = shift; return ($self->index == $self->max) || 0 }

sub odd { shift->count % 2 ? 1 : 0 }

sub even { shift->count % 2 ? 0 : 1 }

sub parity { shift->count % 2 ? 'odd' : 'even' }

sub prev {
    my $self = shift;
    return undef if $self->index <= 0;
    return $self->items->[$self->index - 1];
}

sub next {
    my $self = shift;
    return undef if $self->index >= $self->max;
    return $self->items->[$self->index + 1];
}

1;

__END__

=head1 DESCRIPTION

Template::Alloy::Iterator provides compatibility with Template::Iterator
and filters that require Template::Iterator.

=head1 TODO

Document all of the methods.

=head1 AUTHOR

Paul Seamons <paul at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
