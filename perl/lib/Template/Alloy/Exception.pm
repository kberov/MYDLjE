package Template::Alloy::Exception;

=head1 NAME

Template::Alloy::Exception - Handle exceptions

=cut

use strict;
use warnings;

use overload
    '""' => \&as_string,
    bool => sub { defined shift },
    fallback => 1;

sub new {
    my ($class, $type, $info, $node, $pos, $doc) = @_;
    return bless [$type, $info, $node, $pos, $doc], $class;
}

sub type   { $_[0]->[0] }
sub info   { $_[0]->[1] = $_[1] if @_ >= 2; $_[0]->[1] }
sub node   { $_[0]->[2] = $_[1] if @_ >= 2; $_[0]->[2] }
sub offset { $_[0]->[3] = $_[1] if @_ >= 2; $_[0]->[3] }
sub doc    { $_[0]->[4] = $_[1] if @_ >= 2; $_[0]->[4] }

sub as_string {
    my $self = shift;
    if ($self->type =~ /^parse/) {
        if (my $doc = $self->doc) {
            my ($line, $char) = Template::Alloy->get_line_number_by_index($doc, $self->offset, 'include_char');
            return $self->type ." error - $doc->{'name'} line $line char $char: ". $self->info;
        } else {
            return $self->type .' error - '. $self->info .' (At char '. $self->offset .')';
        }
    } else {
        return $self->type .' error - '. $self->info;
    }
}

###----------------------------------------------------------------###

1;

__END__

=head1 DESCRIPTION

Template::Alloy::Exception provides compatibility with Template::Exception
and filters that require Template::Exception.

=head1 TODO

Document all of the methods.

=head1 AUTHOR

Paul Seamons <paul at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
