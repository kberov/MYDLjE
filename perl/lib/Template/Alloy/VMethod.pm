package Template::Alloy::VMethod;

=head1 NAME

Template::Alloy::VMethod - VMethod role.

=cut

use strict;
use warnings;
use Template::Alloy;
use base qw(Exporter);
our @EXPORT_OK = qw(define_vmethod
                    $ITEM_OPS   $ITEM_METHODS
                    $SCALAR_OPS
                    $LIST_OPS   $LIST_METHODS
                    $HASH_OPS
                    $FILTER_OPS
                    $VOBJS);

sub new { die "This class is a role for use by packages such as Template::Alloy" }

###----------------------------------------------------------------###

our $SCALAR_OPS = our $ITEM_OPS = {
    '0'      => sub { $_[0] },
    abs      => sub { no warnings; abs shift },
    atan2    => sub { no warnings; atan2($_[0], $_[1]) },
    chunk    => \&vmethod_chunk,
    collapse => sub { local $_ = $_[0]; s/^\s+//; s/\s+$//; s/\s+/ /g; $_ },
    cos      => sub { no warnings; cos $_[0] },
    defined  => sub { defined $_[0] ? 1 : '' },
    exp      => sub { no warnings; exp $_[0] },
    fmt      => \&vmethod_fmt_scalar,
    'format' => \&vmethod_format,
    hash     => sub { {value => $_[0]} },
    hex      => sub { no warnings; hex $_[0] },
    html     => sub { local $_ = $_[0]; s/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g; s/\"/&quot;/g; $_ },
    indent   => \&vmethod_indent,
    int      => sub { no warnings; int $_[0] },
    item     => sub { $_[0] },
    js       => sub { local $_ = $_[0]; return if ! $_; s/\n/\\n/g; s/\r/\\r/g; s/(?<!\\)([\"\'])/\\$1/g; $_ },
    lc       => sub { lc $_[0] },
    lcfirst  => sub { lcfirst $_[0] },
    length   => sub { defined($_[0]) ? length($_[0]) : 0 },
    list     => sub { [$_[0]] },
    log      => sub { no warnings; log $_[0] },
    lower    => sub { lc $_[0] },
    match    => \&vmethod_match,
    new      => sub { defined $_[0] ? $_[0] : '' },
    none     => sub { $_[0] },
    null     => sub { '' },
    oct      => sub { no warnings; oct $_[0] },
    print    => sub { no warnings; "@_" },
    rand     => sub { no warnings; rand shift },
    remove   => sub { vmethod_replace(shift, shift, '', 1) },
    repeat   => \&vmethod_repeat,
    replace  => \&vmethod_replace,
    'return' => \&vmethod_return,
    search   => sub { my ($str, $pat) = @_; return $str if ! defined $str || ! defined $pat; return $str =~ /$pat/ },
    sin      => sub { no warnings; sin $_[0] },
    size     => sub { 1 },
    split    => \&vmethod_split,
    sprintf  => sub { no warnings; my $pat = shift; sprintf($pat, @_) },
    sqrt     => sub { no warnings; sqrt $_[0] },
    srand    => sub { no warnings; srand $_[0]; '' },
    stderr   => sub { print STDERR $_[0]; '' },
    substr   => \&vmethod_substr,
    trim     => sub { local $_ = $_[0]; s/^\s+//; s/\s+$//; $_ },
    uc       => sub { uc $_[0] },
    ucfirst  => sub { ucfirst $_[0] },
    upper    => sub { uc $_[0] },
    uri      => \&vmethod_uri,
    url      => \&vmethod_url,
    xml      => sub { local $_ = $_[0]; s/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g; s/\"/&quot;/g; s/\'/&apos;/g; $_ },
};

our $ITEM_METHODS = {
    eval     => \&item_method_eval,
    evaltt   => \&item_method_eval,
    file     => \&item_method_redirect,
    redirect => \&item_method_redirect,
};

our $FILTER_OPS = {}; # generally - non-dynamic filters belong in scalar ops

our $LIST_OPS = {
    defined  => sub { return 1 if @_ == 1; defined $_[0]->[ defined($_[1]) ? $_[1] : 0 ] },
    first    => sub { my ($ref, $i) = @_; return $ref->[0] if ! $i; return [@{$ref}[0 .. $i - 1]]},
    fmt      => \&vmethod_fmt_list,
    grep     => sub { no warnings; my ($ref, $pat) = @_; UNIVERSAL::isa($pat, 'CODE') ? [grep {$pat->($_)} @$ref] : [grep {/$pat/} @$ref] },
    hash     => sub { no warnings; my $list = shift; return {@$list} if ! @_; my $i = shift || 0; return {map {$i++ => $_} @$list} },
    import   => sub { my $ref = shift; push @$ref, grep {defined} map {ref eq 'ARRAY' ? @$_ : undef} @_; '' },
    item     => sub { $_[0]->[ $_[1] || 0 ] },
    join     => sub { my ($ref, $join) = @_; $join = ' ' if ! defined $join; no warnings; return join $join, @$ref },
    last     => sub { my ($ref, $i) = @_; return $ref->[-1] if ! $i; return [@{$ref}[-$i .. -1]]},
    list     => sub { $_[0] },
    map      => sub { no warnings; my ($ref, $code) = @_; UNIVERSAL::isa($code, 'CODE') ? [map {$code->($_)} @$ref] : [map {$code} @$ref] },
    max      => sub { no warnings; $#{ $_[0] } },
    merge    => sub { my $ref = shift; return [ @$ref, grep {defined} map {ref eq 'ARRAY' ? @$_ : undef} @_ ] },
    new      => sub { no warnings; return [@_] },
    null     => sub { '' },
    nsort    => \&vmethod_nsort,
    pick     => \&vmethod_pick,
    pop      => sub { pop @{ $_[0] } },
    push     => sub { my $ref = shift; push @$ref, @_; return '' },
    'return' => \&vmethod_return,
    reverse  => sub { [ reverse @{ $_[0] } ] },
    shift    => sub { shift  @{ $_[0] } },
    size     => sub { no warnings; scalar @{ $_[0] } },
    slice    => sub { my ($ref, $a, $b) = @_; $a ||= 0; $b = $#$ref if ! defined $b; return [@{$ref}[$a .. $b]] },
    sort     => \&vmethod_sort,
    splice   => \&vmethod_splice,
    unique   => sub { my %u; return [ grep { ! $u{$_}++ } @{ $_[0] } ] },
    unshift  => sub { my $ref = shift; unshift @$ref, @_; return '' },
};

our $LIST_METHODS = {
};

our $HASH_OPS = {
    defined  => sub { return 1 if @_ == 1; defined $_[0]->{ defined($_[1]) ? $_[1] : '' } },
    delete   => sub { my $h = shift; delete @{ $h }{map {defined($_) ? $_ : ''} @_}; '' },
    each     => sub { [%{ $_[0] }] },
    exists   => sub { exists $_[0]->{ defined($_[1]) ? $_[1] : '' } },
    fmt      => \&vmethod_fmt_hash,
    hash     => sub { $_[0] },
    import   => sub { my ($a, $b) = @_; @{$a}{keys %$b} = values %$b if ref($b) eq 'HASH'; '' },
    item     => sub { my ($h, $k) = @_; $k = '' if ! defined $k; $Template::Alloy::QR_PRIVATE && $k =~ $Template::Alloy::QR_PRIVATE ? undef : $h->{$k} },
    items    => sub { [ %{ $_[0] } ] },
    keys     => sub { [keys %{ $_[0] }] },
    list     => \&vmethod_list_hash,
    new      => sub { no warnings; return (@_ == 1 && ref $_[-1] eq 'HASH') ? $_[-1] : {@_} },
    null     => sub { '' },
    nsort    => sub { my $ref = shift; [sort {   $ref->{$a} <=>    $ref->{$b}} keys %$ref] },
    pairs    => sub { [map { {key => $_, value => $_[0]->{$_}} } sort keys %{ $_[0] } ] },
    'return' => \&vmethod_return,
    size     => sub { scalar keys %{ $_[0] } },
    sort     => sub { my $ref = shift; [sort {lc $ref->{$a} cmp lc $ref->{$b}} keys %$ref] },
    values   => sub { [values %{ $_[0] }] },
};

our $VOBJS = {
    Text => $SCALAR_OPS,
    List => $LIST_OPS,
    Hash => $HASH_OPS,
};
foreach (values %$VOBJS) {
    $_->{'Text'} = $_->{'fmt'};
    $_->{'Hash'} = $_->{'hash'};
    $_->{'List'} = $_->{'list'};
}

###----------------------------------------------------------------###
### long virtual methods or filters
### many of these vmethods have used code from Template/Stash.pm to
### assure conformance with the TT spec.

sub define_vmethod {
    my ($self, $type, $name, $sub) = @_;
    if (   $type =~ /scalar|item|text/i) { $SCALAR_OPS->{$name} = $sub }
    elsif ($type =~ /array|list/i ) { $LIST_OPS->{  $name} = $sub }
    elsif ($type =~ /hash/i       ) { $HASH_OPS->{  $name} = $sub }
    elsif ($type =~ /filter/i     ) { $FILTER_OPS->{$name} = $sub }
    else { die "Invalid type vmethod type $type" }
    return 1;
}

sub vmethod_fmt_scalar {
    my $str = shift; $str = ''   if ! defined $str;
    my $pat = shift; $pat = '%s' if ! defined $pat;
    no warnings;
    return @_ ? sprintf($pat, $_[0], $str)
              : sprintf($pat, $str);
}

sub vmethod_fmt_list {
    my $ref = shift || return '';
    my $pat = shift; $pat = '%s' if ! defined $pat;
    my $sep = shift; $sep = ' '  if ! defined $sep;
    no warnings;
    return @_ ? join($sep, map {sprintf $pat, $_[0], $_} @$ref)
              : join($sep, map {sprintf $pat, $_} @$ref);
}

sub vmethod_fmt_hash {
    my $ref = shift || return '';
    my $pat = shift; $pat = "%s\t%s" if ! defined $pat;
    my $sep = shift; $sep = "\n"     if ! defined $sep;
    no warnings;
    return ! @_    ? join($sep, map {sprintf $pat, $_, $ref->{$_}} sort keys %$ref)
         : @_ == 1 ? join($sep, map {sprintf $pat, $_[0], $_, $ref->{$_}} sort keys %$ref) # don't get to pick - it applies to the key
         :           join($sep, map {sprintf $pat, $_[0], $_, $_[1], $ref->{$_}} sort keys %$ref);
}

sub vmethod_chunk {
    my $str  = shift;
    my $size = shift || 1;
    my @list;
    if ($size < 0) { # chunk from the opposite end
        $str = reverse $str;
        $size = -$size;
        unshift(@list, scalar reverse $1) while $str =~ /( .{$size} | .+ )/xg;
    } else {
        push(@list, $1)                   while $str =~ /( .{$size} | .+ )/xg;
    }
    return \@list;
}

sub vmethod_indent {
    my $str = shift; $str = '' if ! defined $str;
    my $pre = shift; $pre = 4  if ! defined $pre;
    $pre = ' ' x $pre if $pre =~ /^\d+$/;
    $str =~ s/^/$pre/mg;
    return $str;
}

sub vmethod_format {
    my $str = shift; $str = ''   if ! defined $str;
    my $pat = shift; $pat = '%s' if ! defined $pat;
    if (@_) {
        return join "\n", map{ sprintf $pat, $_[0], $_ } split(/\n/, $str);
    } else {
        return join "\n", map{ sprintf $pat, $_ } split(/\n/, $str);
    }
}

sub vmethod_list_hash {
    my ($hash, $what) = @_;
    $what = 'pairs' if ! $what || $what !~ /^(keys|values|each|pairs)$/;
    return $HASH_OPS->{$what}->($hash);
}


sub vmethod_match {
    my ($str, $pat, $global) = @_;
    return [] if ! defined $str || ! defined $pat;
    my @res = $global ? ($str =~ /$pat/g) : ($str =~ /$pat/);
    return @res ? \@res : '';
}

sub vmethod_nsort {
    my ($list, $field) = @_;
    return defined($field)
        ? [map {$_->[0]} sort {$a->[1] <=> $b->[1]} map {[$_, (ref $_ eq 'HASH' ? $_->{$field}
                                                               : UNIVERSAL::can($_, $field) ? $_->$field()
                                                               : $_)]} @$list ]
        : [sort {$a <=> $b} @$list];
}

sub vmethod_pick {
    my $ref = shift;
    no warnings;
    my $n   = int(shift);
    $n = 1 if $n < 1;
    my @ind = map { $ref->[ rand @$ref ] } 1 .. $n;
    return $n == 1 ? $ind[0] : \@ind;
}

sub vmethod_repeat {
    my ($str, $n, $join) = @_;
    return '' if ! defined $str || ! length $str;
    $n = 1 if ! defined($n) || ! length $n;
    $join = '' if ! defined $join;
    return join $join, ($str) x $n;
}

### This method is a combination of my submissions along
### with work from Andy Wardley, Sergey Martynoff, Nik Clayton, and Josh Rosenbaum
sub vmethod_replace {
    my ($text, $pattern, $replace, $global) = @_;
    $text      = '' unless defined $text;
    $pattern   = '' unless defined $pattern;
    $replace   = '' unless defined $replace;
    $global    = 1  unless defined $global;
    my $expand = sub {
        my ($chunk, $start, $end) = @_;
        $chunk =~ s{ \\(\\|\$) | \$ (\d+) }{
            $1 ? $1
                : ($2 > $#$start || $2 == 0) ? ''
                : substr($text, $start->[$2], $end->[$2] - $start->[$2]);
        }exg;
        $chunk;
    };
    if ($global) {
        $text =~ s{$pattern}{ $expand->($replace, [@-], [@+]) }eg;
    } else {
        $text =~ s{$pattern}{ $expand->($replace, [@-], [@+]) }e;
    }
    return $text;
}

sub vmethod_return {
    my $obj = shift;
    Template::Alloy->throw('return', {return_val => $obj});
}

sub vmethod_sort {
    my ($list, $field) = @_;
    if (! defined $field) {
        return [map {$_->[0]} sort {$a->[1] cmp $b->[1]} map {[$_, lc $_]} @$list ]; # case insensitive
    } elsif (UNIVERSAL::isa($field, 'CODE')) {
        return [sort {int($field->($a, $b))} @$list];
    } else {
        return [map {$_->[0]} sort {$a->[1] cmp $b->[1]} map {[$_, lc(ref $_ eq 'HASH' ? $_->{$field}
                                                                      : UNIVERSAL::can($_, $field) ? $_->$field()
                                                                      : $_)]} @$list ];
    }
}

sub vmethod_splice {
    my ($ref, $i, $len, @replace) = @_;
    @replace = @{ $replace[0] } if @replace == 1 && ref $replace[0] eq 'ARRAY';
    if (defined $len) {
        return [splice @$ref, $i || 0, $len, @replace];
    } elsif (defined $i) {
        return [splice @$ref, $i];
    } else {
        return [splice @$ref];
    }
}

sub vmethod_split {
    my ($str, $pat, $lim) = @_;
    $str = '' if ! defined $str;
    if (defined $lim) { return defined $pat ? [split $pat, $str, $lim] : [split ' ', $str, $lim] }
    else              { return defined $pat ? [split $pat, $str      ] : [split ' ', $str      ] }
}

sub vmethod_substr {
    my ($str, $i, $len, $replace) = @_;
    $i ||= 0;
    return '' if ! defined $str;
    return substr($str, $i)       if ! defined $len;
    return substr($str, $i, $len) if ! defined $replace;
    substr($str, $i, $len, $replace);
    return $str;
}

sub vmethod_uri {
    my $str = shift;
    return '' if ! defined $str;
    utf8::upgrade($str) if defined &utf8::upgrade;
    $str =~ s/([^A-Za-z0-9\-_.!~*\'()])/sprintf('%%%02X', ord($1))/eg;
    return $str;
}

sub vmethod_url {
    my $str = shift;
    return '' if ! defined $str;
    utf8::upgrade($str) if defined &utf8::upgrade;
    $str =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*\'()])/sprintf('%%%02X', ord($1))/eg;
    return $str;
}

sub item_method_eval {
    my $t    = shift;
    my $text = shift; return '' if ! defined $text;
    my $args = shift || {};

    local $t->{'_eval_recurse'} = $t->{'_eval_recurse'} || 0;
    $t->throw('eval_recurse', "MAX_EVAL_RECURSE $Template::Alloy::MAX_EVAL_RECURSE reached")
        if ++$t->{'_eval_recurse'} > ($t->{'MAX_EVAL_RECURSE'} || $Template::Alloy::MAX_EVAL_RECURSE);

    my %ARGS;
    @ARGS{ map {uc} keys %$args } = values %$args;
    delete @ARGS{ grep {! $Template::Alloy::EVAL_CONFIG->{$_}} keys %ARGS };
    $t->throw("eval_strict", "Cannot disable STRICT once it is enabled") if exists $ARGS{'STRICT'} && ! $ARGS{'STRICT'};

    local @{ $t }{ keys %ARGS } = values %ARGS;
    my $out = '';
    $t->process_simple(\$text, $t->_vars, \$out) || $t->throw($t->error);
    return $out;
}

sub item_method_redirect {
    my ($t, $text, $file, $options) = @_;
    my $path = $t->{'OUTPUT_PATH'} || $t->throw('redirect', 'OUTPUT_PATH is not set');
    $t->throw('redirect', 'Invalid filename - cannot include "/../"')
        if $file =~ m{(^|/)\.\./};

    if (! -d $path) {
        require File::Path;
        File::Path::mkpath($path) || $t->throw('redirect', "Couldn't mkpath \"$path\": $!");
    }
    open (my $fh, '>', "$path/$file") || $t->throw('redirect', "Couldn't open \"$file\": $!");
    if (my $bm = (! $options) ? 0 : ref($options) ? $options->{'binmode'} : $options) {
        if (+$bm == 1) { binmode $fh }
        else { binmode $fh, $bm}
    }
    print $fh $text;
    return '';
}

###----------------------------------------------------------------###

1;

__END__

=head1 DESCRIPTION

The Template::Alloy::VMethod role provides all of the extra vmethods,
filters, and virtual objects that add to the base featureset of
Template::Alloy.  Most of the vmethods listed here are similar to
those provided by Template::Toolkit.  We will try to keep
Template::Alloy's in sync.  Template::Alloy also provides several
extra methods that are needed for HTML::Template::Expr support.

=head1 ROLE METHODS

=over 4

=item define_vmethod

Defines a vmethod.  See L<Template::Alloy> for more details.

=item C<vmethod_*>

Methods by these names implement virtual methods that are more complex
than oneliners.  These methods are not exposed via the role.

=item C<filter_*>

Methods by these names implement filters that are more complex than
one liners.  These methods are not exposed via the role.

=back

=head1 VIRTUAL METHOD LIST

The following is the list of builtin virtual methods and filters that
can be called on each type of data.

In Template::Alloy, the "|" operator can be used to call virtual
methods just the same way that the "." operator can.  The main
difference between the two is that on access to hashrefs or objects,
the "|" means to always call the virtual method or filter rather than
looking in the hashref for a key by that name, or trying to call that
method on the object.  This is similar to how TT3 will function.

Virtual methods are also made available via Virtual Objects which
are discussed in a later section.

=head2 SCALAR VIRTUAL METHODS AND FILTERS

The following is the list of builtin virtual methods and filters that
can be called on scalar data types.  In Alloy and TT3, filters and
virtual methods are more closely related than in TT2.  In general
anywhere a virtual method can be used a filter can be used also - and
likewise all scalar virtual methods can be used as filters.

In addition to the filters listed below, Alloy will automatically load
Template::Filters and use them if Template::Toolkit is installed.

In addition to the scalar virtual methods, any scalar will be
automatically converted to a single item list if a list virtual method
is called on it.

Scalar virtual methods are also available through the "Text" virtual
object (except for true filters such as eval and redirect).

All scalar virtual methods are available as top level functions as well.
This is not true of TT2.  In Template::Alloy the following are equivalent:

    [% "abc".length %]
    [% length("abc") %]

You may set VMETHOD_FUNCTIONS to 0 to disable this behavior.

=over 4

=item '0'

    [% item = 'foo' %][% item.0 %] Returns foo.

Allows for scalars to mask as arrays (scalars already will, but this
allows for more direct access).

Not available in TT.

=item abs

    [% -1.abs %] Returns the absolute value

=item atan2

    [% pi = 4 * 1.atan2(1) %]

Returns the arctangent.  The item itself represents Y, the passed argument represents X.

Not available in TT - available in HTML::Template::Expr.

=item chunk

    [% item.chunk(60).join("\n") %] Split string up into a list of chunks of text 60 chars wide.

=item collapse

    [% item.collapse %] Strip leading and trailing whitespace and collapse all other space to one space.

=item cos

    [% item.cos %] Returns the cosine of the item.

Not available in TT - available in HTML::Template::Expr.

=item defined

    [% item.defined %] Always true - because the undef sub translates all undefs to ''.

=item eval

    [% item.eval %]

Process the string as though it was a template.  This will start the
parsing engine and will use the same configuration as the current
process.  Alloy is several times faster at doing this than TT is and
is considered acceptable.

This is a filter and is not available via the Text virtual object.

Template::Alloy has attempted to make the compile process painless and
fast.  By default an MD5 sum of evaled is taken and used to cache the
AST.  This behavior can be disabled using the CACHE_STR_REFS
configuration item.

Template::Alloy also allows for named parameters to be passed to the
eval filter.

    [% '[% 1 + 2 %]'.eval %]

    [% '${ 1 + 2 }'.eval(interpolate => 1) %]

    [% "#get( 1 + 2)"|eval(syntax => 'velocity') %]

    [% '<TMPL_VAR EXPR="1 + 2">'.eval(syntax => 'hte') %]

    [% '<TMPL_VAR EXPR="1 + 2">'.eval(syntax => 'hte') %]

=item evaltt

    Same as the eval filter.

=item exp

    [% 1.exp %] Something like 2.71828182845905

Returns "e" to the power of the item.

=item file

    Same as the redirect filter.

=item fmt

    [% item.fmt('%d') %]
    [% item.fmt('%6s') %]
    [% item.fmt('%*s', 6) %]

Similar to format.  Returns a string formatted with the passed
pattern.  Default pattern is %s.  Opposite from of the sprintf
vmethod.

=item format

    [% item.format('%d') %]
    [% item.format('%6s') %]
    [% item.format('%*s', 6) %]

Print the string out in the specified format.  It is similar to the
"fmt" virtual method, except that the item is split on newline and
each line is processed separately.

=item hash

    [% item.hash %] Returns a one item hash with a key of "value" and a value of the item.


=item hex

    [% "FF".hex %]

Returns the decimal value of the passed hex numbers.  Note that you
may also just use [% 0xFF %].

Not available in TT - available in HTML::Template::Expr.

=item html

    [% item.html %] Performs a very basic html encoding (swaps out &, <, > and " with the corresponding html entities)
    Previously it also encoded the ' but this behavior did not match TT2's behavior.  Use .xml to obtain that behavior.

=item indent

    [% item.indent(3) %] Indent by that number of spaces if an integer is passed (default is 4).

    [% item.indent("Foo: ") %] Add the string "Foo: " to the beginning of every line.

=item int

    [% item.int %] Return the integer portion of the value (0 if none).

=item lc

Same as the lower vmethod.  Returns the lowercased version of the item.

=item lcfirst

    [% item.lcfirst %] Lowercase the leading letter.

=item length

    [% item.length %] Return the length of the string.

=item list

    [% item.list %] Returns a list (arrayref) with a single value of the item.

=item log

    [% 8.exp.log %] Equal to 8.

Returns the natural log base "e" of the item.

Not available in TT - available in HTML::Template::Expr.

=item lower

    [% item.lower %] Return the string lowercased.

=item match

    [% item.match("(\w+) (\w+)") %] Return a list of items matching the pattern.

    [% item.match("(\w+) (\w+)", 1) %] Same as before - but match globally.

In Template::Alloy and TT3 you can use regular expressions notation as well.

    [% item.match( /(\w+) (\w+)/ ) %] Same as before.

    [% item.match( m{(\w+) (\w+)} ) %] Same as before.

Note that you can't use the 'g' regex modifier - you must pass the second
argument to turn on global match.

=item none

Returns the item without modification.  This was added as a compliment case
when the AUTO_FILTER configuration is specified.  Note that it must be
called as a filter to bypass the application of the AUTO_FILTER.

    [% item | none %] Returns the item without modification.

=item null

    [% item.null %] Return nonthing.

If the item contains a coderef it will still be executed, but the result would
be ignored.

=item oct

    [% "377".oct %]

Returns the decimal value of the octal string.  On recent versions of perl you
may also pass numbers starting with 0x which will be interpreted as hexidecimal,
and starting with 0b which will be interpreted as binary.

Not available in TT - available in HTML::Template::Expr.

=item rand

    [% item = 10; item.rand %] Returns a number greater or equal to 0 but less than 10.
    [% 1.rand %]

Note: This filter is not available as of TT2.15.

=item remove

    [% item.remove("\s+") %] Same as replace - but is global and replaces with nothing.

=item redirect

    [% item.redirect("output_file.html") %]

Writes the contents out to the specified file.  The filename must be
relative to the OUTPUT_PATH configuration variable and the OUTPUT_PATH
variable must be set.

This is a filter and is not available via the Text virtual object.

=item repeat

    [% item.repeat(3) %] Repeat the item 3 times

    [% item.repeat(3, ' | ') %] Repeat the item 3 times separated with ' | '

=item replace

    [% item.replace("\s+", "&nbsp;") %] Globally replace all space with &nbsp;

    [% item.replace("foo", "bar", 0) %] Replace only the first instance of foo with bar.

    [% item.replace("(\w+)", "($1)") %] Surround all words with parenthesis.

In Template::Alloy and TT3 you may also use normal regular expression notation.

    [% item.replace(/(\w+)/, "($1)") %] Same as before.

Note that you can't use the 'g' regex modifier - global match is on by default.
You must pass the third argument of false to turn off global match.

=item return

Returns the item from the inner most block, macro, or file.  Similar to the
RETURN directive.

    [% item.return %]
    [% RETURN item %]

=item search

    [% item.search("(\w+)") %] Tests if the given pattern is in the string.

In Template::Alloy and TT3 you may also use normal regular expression notation.

    [% item.search(/(\w+)/) %] Same as before.

=item sin

    [% item.sin %] Returns the sine of the item.

=item size

    [% item.size %] Always returns 1.

=item split

    [% item.split %] Returns an arrayref from the item split on " "

    [% item.split("\s+") %] Returns an arrayref from the item split on /\s+/

    [% item.split("\s+", 3) %] Returns an arrayref from the item split on /\s+/ splitting until 3 elements are found.

In Template::Alloy and TT3 you may also use normal regular expression notation.

    [% item.split( /\s+/, 3 ) %] Same as before.

=item sprintf

    [% item = "%d %d" %]
    [% item.sprintf(7, 8) %]

Uses the pattern stored in self, and passes it to sprintf with the passed arguments.
Opposite from the fmt vmethod.

=item sqrt

    [% item.sqrt %]

Returns the square root of the number.

=item srand

Calls the perl srand function to set the interal random seed.  This
will affect future calls to the rand vmethod.

=item stderr

    [% item.stderr %] Print the item to the current STDERR handle.

=item substr

    [% item.substr(i) %] Returns a substring of item starting at i and going to the end of the string.

    [% item.substr(i, n) %] Returns a substring of item starting at i and going n characters.

=item trim

    [% item.trim %] Strips leading and trailing whitespace.

=item uc

Same as the upper command.  Returns uppercased string.

=item ucfirst

    [% item.ucfirst %] Uppercase the leading letter.

=item upper

    [% item.upper %] Return the string uppercased.

=item uri

    [% item.uri %] Perform a very basic URI encoding.

=item url

    [% item.url %] Perform a URI encoding - but some characters such
                   as : and / are left intact.

=item xml

    [% item.xml %] Performs a very basic xml encoding (swaps out &, <, >, ' and " with the corresponding xml entities)

=back

=head2 LIST VIRTUAL METHODS

The following methods can be called on an arrayref type data
structures (scalar types will automatically promote to a single
element list and call these methods if needed):

Additionally, list virtual methods can be accessed via the List
Virtual Object.

=over 4

=item fmt

    [% mylist.fmt('%s', ', ') %]
    [% mylist.fmt('%6s', ', ') %]
    [% mylist.fmt('%*s', ', ', 6) %]

Passed a pattern and an string to join on.  Returns a string of the
values of the list formatted with the passed pattern and joined with
the passed string.  Default pattern is %s and the default join string
is a space.

=item first

    [% mylist.first(3) %]  Returns a list of the first 3 items in the list.

=item grep

    [% mylist.grep("^\w+\.\w+$") %] Returns a list of all items matching the pattern.

In Template::Alloy and TT3 you may also use normal regular expression notation.

    [% mylist.grep(/^\w+\.\w+$/) %] Same as before.

    [% mylist.grep(->(a){ a.foo.bar }

=item hash

    [% mylist.hash %] Returns a hashref with the array indexes as keys and the values as values.

=item join

    [% mylist.join %] Joins on space.
    [% mylist.join(", ") Joins on the passed argument.

=item last

    [% mylist.last(3) %]  Returns a list of the last 3 items in the list.

=item list

    [% mylist.list %] Returns a reference to the list.

=item map (Not in TT2)

    [% mylist.map(->{ this.upper }) %] Returns a list with the macro played on each item.
    [% mylist.map(->(a){ a.upper }) %] Same thing

The RETURN directive or return list, item, and hash vmethods allow for returning more interesing
items.

    [% [1..3].map(->(a){ [1..a].return }) %]

=item max

    [% mylist.max %] Returns the last item in the array.

=item merge

    [% mylist.merge(list2) %] Returns a new list with all defined items from list2 added.

=item nsort

    [% mylist.nsort %] Returns the numerically sorted items of the list.  If the items are
    hashrefs, a key containing the field to sort on can be passed.

=item pop

    [% mylist.pop %] Removes and returns the last element from the arrayref (the stash is modified).

=item push

    [% mylist.push(23) %] Adds an element to the end of the arrayref (the stash is modified).

=item pick

    [% mylist.pick %] Returns a random item from the list.
    [% ['a' .. 'z'].pick %]

An additional numeric argument is how many items to return.

    [% ['a' .. 'z'].pick(8).join('') %]

Note: This filter is not available as of TT2.15.

=item return

Returns the list from the inner most block, macro, or file.  Similar to the
RETURN directive.

    [% mylist.return %]
    [% RETURN mylist %]

=item reverse

    [% mylist.reverse %] Returns the list in reverse order.

=item shift

    [% mylist.shift %] Removes and returns the first element of the arrayref (the stash is modified).

=item size

    [% mylist.size %] Returns the number of elements in the array.

=item slice

    [% mylist.slice(i, n) %] Returns a list from the arrayref beginning at index i and continuing for n items.

=item sort

    [% mylist.sort %] Returns the alphabetically sorted items of the list.  If the items are
    hashrefs, a key containing the field to sort on can be passed.

=item splice

    [% mylist.splice(i, n) %] Removes items from array beginning at i and continuing for n items.

    [% mylist.splice(i, n, list2) %] Same as before, but replaces removed items with the items
    from list2.

=item unique

    [% mylist.unique %] Return a list of the unique items in the array.

=item unshift

    [% mylist.unshift(23) %] Adds an item to the beginning of the arrayref.

=back

=head2 HASH VIRTUAL METHODS

The following methods can be called on hash type data structures:

Additionally, list virtual methods can be accessed via the Hash
Virtual Object.

=over 4

=item fmt

    [% myhash.fmt('%s => %s', "\n") %]
    [% myhash.fmt('%4s => %5s', "\n") %]
    [% myhash.fmt('%*s => %*s', "\n", 4, 5) %]

Passed a pattern and an string to join on.  Returns a string of the
key/value pairs of the hash formatted with the passed pattern and
joined with the passed string.  Default pattern is "%s\t%s" and the
default join string is a newline.

=item defined

    [% myhash.defined('a') %]  Checks if a is defined in the hash.

=item delete

    [% myhash.delete('a') %]  Deletes the item from the hash.

Unlink Perl the value is not returned.  Multiple values may be passed
and represent the keys to be deleted.

=item each

    [% myhash.each.join(", ") %]  Turns the contents of the hash into a list - subject
    to change as TT is changing the operations of each and list.

=item exists

    [% myhash.exists('a') %]  Checks if a is in the hash.

=item hash

    [% myhash.hash %]  Returns a reference to the hash.

=item import

    [% myhash.import(hash2) %]  Overlays the keys of hash2 over the keys of myhash.

=item item

    [% myhash.item(key) %] Returns the hashes value for that key.

=item items

    [% myhash.items %] Returns a list of the key and values (flattened hash)

=item keys

    [% myhash.keys.join(', ') %] Returns an arrayref of the keys of the hash.

=item list

    [% myhash.list %] Returns an arrayref with the hash as a single value (subject to change).

=item pairs

    [% myhash.pairs %] Returns an arrayref of hashrefs where each hash contains {key => $key, value => $value}
    for each value of the hash.

=item nsort

    [% myhash.nsort.join(", ") %] Returns a list of keys numerically sorted by the values.

=item return

Returns the hash from the inner most block, macro, or file.  Similar to the
RETURN directive.

    [% myhash.return %]
    [% RETURN myhash %]

=item size

    [% myhash.size %] Returns the number of key/value pairs in the hash.

=item sort

    [% myhash.sort.join(", ") Returns a list of keys alphabetically sorted by the values.

=item values

    [% myhash.values.join(', ') %] Returns an arrayref of the values of the hash.

=back

=head1 VIRTUAL OBJECTS

TT3 has a concept of Text, List, and Hash virtual objects which
provide direct access to the scalar, list, and hash virtual methods.
In the TT3 engine this will allow for more concise generated code.
Because Alloy does not generated perl code to be executed later, Alloy
provides for these virtual objects but does so as more of a namespace
(using the methods does not provide a speed optimization in your
template - just may help clarify things).

    [% a = "foo"; a.length %] => 3

    [% a = "foo"; Text.length(a) %] => 3

    [% a = Text.new("foo"); a.length %] => 3


    [% a = [1 .. 30]; a.size %] => 30

    [% a = [1 .. 30]; List.size(a) %] => 30

    [% a = List.new(1 .. 30); a.size %] => 30


    [% a = {a => 1, b => 2}; a.size %] => 2

    [% a = {a => 1, b => 2}; Hash.size(a) %] => 2

    [% a = Hash.new({a => 1, b => 2}); a.size %] => 2

    [% a = Hash.new(a => 1, b => 2); a.size %] => 2

    [% a = Hash.new(a = 1, b = 2); a.size %] => 2

    [% a = Hash.new('a', 1, 'b', 2); a.size %] => 2

One limitation is that if you pass a key named "Text",
"List", or "Hash" in your variable stash - the corresponding
virtual object will be hidden.

Additionally, you can use all of the Virtual object methods with
the pipe operator.

    [% {a => 1, b => 2}
       | Hash.keys
       | List.join(", ") %] => a, b

Again, there aren't any speed optimizations to using the virtual
objects in Alloy, but it can help clarify the intent in some cases.

Note: these aren't really objects.  All of the "virtual objects" are
references to the $SCALAR_OPS, $LIST_OPS, and $HASH_OPS hashes
found in the $VOBJS hash of Template::Alloy.

=head1 AUTHOR

Paul Seamons <perl at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
