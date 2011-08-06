package MYDLjE::Regexp;
use Mojo::Base 'Exporter';

use strict;
use warnings;    # FATAL => qw( all );
use utf8;
our %MRE       = ();
our @EXPORT_OK = qw(%MRE);
my $none = $MRE{permissions}{'-'} = "\-";
$MRE{permissions}{ldn} = qr/[ld$none]/x;
$MRE{permissions}{l}   = qr/l/x;
$MRE{permissions}{d}   = qr/d/x;
$MRE{permissions}{rwx} = qr/[r$none][w$none][x$none]/x;
$MRE{permissions}{r}   = qr/r[wx$none]{2}/x;
$MRE{permissions}{w}   = qr/rw[x$none]/x;
$MRE{permissions}{x}   = qr/[rw$none]{2}x/x;
$MRE{perms}            = $MRE{permissions};
$MRE{no_markup}        = qr/[^\p{IsAlnum}\,\s\-\!\.\?\(\);]/x;
my $data_types = qr/(note|article|chapter|content|brick)/x;
$MRE{data_types} = qr/(page|question|answer|book)|$data_types/x;


1;

__END__

=encoding utf8

=head1 MYDLjE::Regexp - a collection of comonly used regexes.

=head1 DESCRIPTION

This module simply shares the idea to put in one place commonly used regexes 
in one place. This is what L<Regexp::Common|Regexp::Common> does.
Note that this module is not (I<yet>) a subclass of Regexp::Common.
It simply supports its most commonly used standart API.
When we see that we can not cope without Regexp::Common, we will add it 
to the L<MYDLjE> distribution package.

=head1 EXPORTS

Currently the only exported by request thing is the C<%MRE> hash where our patterns are stored.

=head1 PATTERNS

Every pattern is stored as a C<key =E<gt> value> pair. The value may be a reference to a hash 
holding C<key =E<gt> value> pairs with subpatterns.
The existing patterns are

=over

=item * C<$MRE{permissions}> or C<$MRE{perms}> - HASHREF holding the parts of 
a permissions regexp the keys are  C<ldn>, C<l>, C<d>, C<r>, C<w>, C<x> and C<rwx>;

=item * - C<$MRE{data_types}> - matches content for allowed data_type;

=item * - C<$MRE{no_markup}> - used to replace anything strange from titles and descriptions;

=item * -

=item * -

=back

=head1 SEE ALSO

L<Regexp::Common>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.


