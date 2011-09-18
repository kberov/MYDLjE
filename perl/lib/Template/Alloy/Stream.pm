package Template::Alloy::Stream;

=head1 NAME

Template::Alloy::Stream - Stream role - allows for playing out the AST and printing straight to file handle

=cut

use strict;
use warnings;
use Template::Alloy;
use Template::Alloy::Play;

our $VERSION = $Template::Alloy::VERSION;

sub new { die "This class is a role for use by packages such as Template::Alloy" }

###----------------------------------------------------------------###

sub stream_tree {
    my ($self, $tree) = @_;

    local $Template::Alloy::Play::DIRECTIVES->{'CLEAR'} = \&stream_CLEAR;

    # node contains (0: DIRECTIVE,
    #                1: start_index,
    #                2: end_index,
    #                3: parsed tag details,
    #                4: sub tree for block types
    #                5: continuation sub trees for sub continuation block types (elsif, else, etc)
    #                6: flag to capture next directive
    for my $node (@$tree) {
        ### text nodes are just the bare text
        if (! ref $node) {
            print $node if defined $node;
            next;
        }

        print $self->debug_node($node) if $self->{'_debug_dirs'} && ! $self->{'_debug_off'};

        my $out = '';
        $Template::Alloy::Play::DIRECTIVES->{$node->[0]}->($self, $node->[3], $node, \$out);
        print $out;
    }
}

sub stream_CLEAR {
    my ($self, $undef, $node) = @_;
    $self->throw('stream', 'Cannot use CLEAR directive when STREAM is being used', $node);
}

###----------------------------------------------------------------###

1;

__END__

=head1 DESCRIPTION

The Template::Alloy::Stream role works similar to the PLAY role, but instead
of accumulating the data, it prints it as soon as it is available.

All directives are supported except for the CLEAR directive which is meaningless.

Most configuration items are supported - except for the TRIM directive which cannot
be used because the output is not buffered into a variable that can be trimmed.

The WRAPPER directive is still supported - but it essentially turns off STREAM as
the content must be generated before playing the WRAPPER templates.

=head1 ROLE METHODS

=over 4

=item C<stream_tree>

Similar to play_tree from the Play role, but prints output to the screen
as soon as it is ready.

=back

=head1 AUTHOR

Paul Seamons <paul at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
