package Template::Alloy::Operator;

=head1 NAME

Template::Alloy::Operator - Operator role.

=cut

use strict;
use warnings;
use Template::Alloy;
use base qw(Exporter);
our @EXPORT_OK = qw(play_operator define_operator
                    $QR_OP $QR_OP_ASSIGN $QR_OP_PREFIX $QR_PRIVATE
                    $OP $OP_ASSIGN $OP_PREFIX $OP_POSTFIX $OP_DISPATCH);

our $VERSION = $Template::Alloy::VERSION;

sub new { die "This class is a role for use by packages such as Template::Alloy" }

###----------------------------------------------------------------###

### setup the operator parsing
our $OPERATORS = [
    # type      precedence symbols              action (undef means play_operator will handle)
    ['prefix',  99,        ['\\'],              undef],
    ['postfix', 98,        ['++'],              undef],
    ['postfix', 98,        ['--'],              undef],
    ['prefix',  97,        ['++'],              undef],
    ['prefix',  97,        ['--'],              undef],
    ['right',   96,        ['**', 'pow'],       sub { no warnings;     $_[0] ** $_[1]  } ],
    ['prefix',  93,        ['!'],               sub { no warnings;   ! $_[0]           } ],
    ['prefix',  93,        ['-'],               sub { no warnings; @_ == 1 ? 0 - $_[0] : $_[0] - $_[1] } ],
    ['left',    90,        ['*'],               sub { no warnings;     $_[0] *  $_[1]  } ],
    ['left',    90,        ['/'],               sub { no warnings;     $_[0] /  $_[1]  } ],
    ['left',    90,        ['div', 'DIV'],      sub { no warnings; int($_[0] /  $_[1]) } ],
    ['left',    90,        ['%', 'mod', 'MOD'], sub { no warnings;     $_[0] %  $_[1]  } ],
    ['left',    85,        ['+'],               sub { no warnings;     $_[0] +  $_[1]  } ],
    ['left',    85,        ['-'],               sub { no warnings; @_ == 1 ? 0 - $_[0] : $_[0] - $_[1] } ],
    ['left',    85,        ['~', '_'],          undef],
    ['none',    80,        ['<'],               sub { no warnings; $_[0] <  $_[1]  } ],
    ['none',    80,        ['>'],               sub { no warnings; $_[0] >  $_[1]  } ],
    ['none',    80,        ['<='],              sub { no warnings; $_[0] <= $_[1]  } ],
    ['none',    80,        ['>='],              sub { no warnings; $_[0] >= $_[1]  } ],
    ['none',    80,        ['lt'],              sub { no warnings; $_[0] lt $_[1]  } ],
    ['none',    80,        ['gt'],              sub { no warnings; $_[0] gt $_[1]  } ],
    ['none',    80,        ['le'],              sub { no warnings; $_[0] le $_[1]  } ],
    ['none',    80,        ['ge'],              sub { no warnings; $_[0] ge $_[1]  } ],
    ['none',    75,        ['=='],              sub { no warnings; $_[0] == $_[1]  } ],
    ['none',    75,        ['eq'],              sub { no warnings; $_[0] eq $_[1]  } ],
    ['none',    75,        ['!='],              sub { no warnings; $_[0] != $_[1]  } ],
    ['none',    75,        ['ne'],              sub { no warnings; $_[0] ne $_[1]  } ],
    ['none',    75,        ['<=>'],             sub { no warnings; $_[0] <=> $_[1] } ],
    ['none',    75,        ['cmp'],             sub { no warnings; $_[0] cmp $_[1] } ],
    ['left',    70,        ['&&'],              undef],
    ['right',   65,        ['||'],              undef],
    ['right',   65,        ['//'],              undef],
    ['none',    60,        ['..'],              sub { no warnings; $_[0] .. $_[1]  } ],
    ['ternary', 55,        ['?', ':'],          undef],
    ['assign',  53,        ['+='],              undef],
    ['assign',  53,        ['-='],              undef],
    ['assign',  53,        ['*='],              undef],
    ['assign',  53,        ['/='],              undef],
    ['assign',  53,        ['%='],              undef],
    ['assign',  53,        ['**='],             undef],
    ['assign',  53,        ['~=', '_='],        undef],
    ['assign',  53,        ['//='],             undef],
    ['assign',  53,        ['||='],             undef],
    ['assign',  52,        ['='],               undef],
    ['prefix',  50,        ['not', 'NOT'],      sub { no warnings; ! $_[0]         } ],
    ['left',    45,        ['and', 'AND'],      undef],
    ['right',   40,        ['or',  'OR' ],      undef],
    ['right',   40,        ['err', 'ERR'],      undef],
];

our ($QR_OP, $QR_OP_PREFIX, $QR_OP_ASSIGN, $OP, $OP_PREFIX, $OP_DISPATCH, $OP_ASSIGN, $OP_POSTFIX, $OP_TERNARY);
_build_ops();

###----------------------------------------------------------------###

sub _op_qr { # no mixed \w\W operators
    my %used;
    my $chrs = join '|', reverse sort map {quotemeta $_} grep {++$used{$_} < 2} grep {! /\{\}|\[\]/} grep {/^\W{2,}$/} @_;
    my $chr  = join '',          sort map {quotemeta $_} grep {++$used{$_} < 2} grep {/^\W$/}     @_;
    my $word = join '|', reverse sort                    grep {++$used{$_} < 2} grep {/^\w+$/}    @_;
    $chr = "[$chr]" if $chr;
    $word = "\\b(?:$word)\\b" if $word;
    return join('|', grep {length} $chrs, $chr, $word) || die "Missing operator regex";
}

sub _build_ops {
    $QR_OP        = _op_qr(map {@{ $_->[2] }} grep {$_->[0] ne 'prefix'} @$OPERATORS);
    $QR_OP_PREFIX = _op_qr(map {@{ $_->[2] }} grep {$_->[0] eq 'prefix'} @$OPERATORS);
    $QR_OP_ASSIGN = _op_qr(map {@{ $_->[2] }} grep {$_->[0] eq 'assign'} @$OPERATORS);
    $OP           = {map {my $ref = $_; map {$_ => $ref}      @{$ref->[2]}} grep {$_->[0] ne 'prefix' } @$OPERATORS}; # all non-prefix
    $OP_PREFIX    = {map {my $ref = $_; map {$_ => $ref}      @{$ref->[2]}} grep {$_->[0] eq 'prefix' } @$OPERATORS};
    $OP_DISPATCH  = {map {my $ref = $_; map {$_ => $ref->[3]} @{$ref->[2]}} grep {$_->[3]             } @$OPERATORS};
    $OP_ASSIGN    = {map {my $ref = $_; map {$_ => 1}         @{$ref->[2]}} grep {$_->[0] eq 'assign' } @$OPERATORS};
    $OP_POSTFIX   = {map {my $ref = $_; map {$_ => 1}         @{$ref->[2]}} grep {$_->[0] eq 'postfix'} @$OPERATORS}; # bool is postfix
    $OP_TERNARY   = {map {my $ref = $_; map {$_ => 1}         @{$ref->[2]}} grep {$_->[0] eq 'ternary'} @$OPERATORS}; # bool is ternary
}

###----------------------------------------------------------------###

sub play_operator {
    my ($self, $tree) = @_;
    ### $tree looks like [undef, '+', 4, 5]

    return $OP_DISPATCH->{$tree->[1]}->(@$tree == 3 ? $self->play_expr($tree->[2]) : ($self->play_expr($tree->[2]), $self->play_expr($tree->[3])))
        if $OP_DISPATCH->{$tree->[1]};

    my $op = $tree->[1];

    ### do custom and short-circuitable operators
    if ($op eq '=') {
        my $val = $self->play_expr($tree->[3]);
        $self->set_variable($tree->[2], $val);
        return $val;

   } elsif ($op eq '||' || $op eq 'or' || $op eq 'OR') {
        my $val = $self->play_expr($tree->[2]) || $self->play_expr($tree->[3]);
        return defined($val) ? $val : '';

    } elsif ($op eq '&&' || $op eq 'and' || $op eq 'AND') {
        my $val = $self->play_expr($tree->[2]) && $self->play_expr($tree->[3]);
        return defined($val) ? $val : '';

    } elsif ($op eq '//' || $op eq 'err' || $op eq 'ERR') {
        my $val = $self->play_expr($tree->[2]);
        return $val if defined $val;
        return $self->play_expr($tree->[3]);

    } elsif ($op eq '?') {
        no warnings;
        return $self->play_expr($tree->[2]) ? $self->play_expr($tree->[3]) : $self->play_expr($tree->[4]);

    } elsif ($op eq '~' || $op eq '_') {
        no warnings;
        my $s = '';
        $s .= $self->play_expr($tree->[$_]) for 2 .. $#$tree;
        return $s;

    } elsif ($op eq '[]') {
        return [map {$self->play_expr($tree->[$_])} 2 .. $#$tree];

    } elsif ($op eq '{}') {
        no warnings;
        my @e;
        push @e, $self->play_expr($tree->[$_]) for 2 .. $#$tree;
        return {@e};

    } elsif ($op eq '++') {
        no warnings;
        my $val = 0 + $self->play_expr($tree->[2]);
        $self->set_variable($tree->[2], $val + 1);
        return $tree->[3] ? $val : $val + 1; # ->[3] is set to 1 during parsing of postfix ops

    } elsif ($op eq '--') {
        no warnings;
        my $val = 0 + $self->play_expr($tree->[2]);
        $self->set_variable($tree->[2], $val - 1);
        return $tree->[3] ? $val : $val - 1; # ->[3] is set to 1 during parsing of postfix ops

    } elsif ($op eq '@()') {
        local $self->{'CALL_CONTEXT'} = 'list';
        return $self->play_expr($tree->[2]);

    } elsif ($op eq '$()') {
        local $self->{'CALL_CONTEXT'} = 'item';
        return $self->play_expr($tree->[2]);

    } elsif ($op eq '\\') {
        my $var = $tree->[2];

        my $ref = $self->play_expr($var, {return_ref => 1});
        return $ref if ! ref $ref;
        return sub { sub { $$ref } } if ref $ref eq 'SCALAR' || ref $ref eq 'REF';

        my $self_copy = $self;
        eval {require Scalar::Util; Scalar::Util::weaken($self_copy)};

        my $last = ['temp deref key', $var->[-1] ? [@{ $var->[-1] }] : 0];
        return sub { sub { # return a double sub so that the current play_expr will return a coderef
            local $self_copy->{'_vars'}->{'temp deref key'} = $ref;
            $last->[-1] = (ref $last->[-1] ? [@{ $last->[-1] }, @_] : [@_]) if @_;
            return $self->play_expr($last);
        } };
    } elsif ($op eq '->') {
        my $code = $self->_macro_sub($tree->[2], $tree->[3]);
        return sub { $code }; # do the double sub dance
    } elsif ($op eq 'qr') {
        return $tree->[3] ? qr{(?$tree->[3]:$tree->[2])} : qr{$tree->[2]};
    }

    $self->throw('operator', "Un-implemented operation $op");
}

###----------------------------------------------------------------###

sub define_operator {
    my ($self, $args) = @_;
    push @$OPERATORS, [@{ $args }{qw(type precedence symbols play_sub)}];
    _build_ops();
    return 1;
}

###----------------------------------------------------------------###

1;

__END__

=head1 DESCRIPTION

The Template::Alloy::Operator role provides the regexes necessary for
Template::Alloy::Parse to parse operators and place them in their
appropriate precedence.  It also provides the play_operator method
which is used by Template::Alloy::Play and Template::Alloy::Compile
for playing out the stored operator ASTs.

=head1 ROLE METHODS

=over 4

=item play_operator

Takes an operator AST in the form of

    [undef, '+', 1, 2]

Essentially, all operators are stored in RPN notation with
a leading "undef" to disabiguate operators in a normal
Alloy expression AST.

=item define_operator

Used for defining new operators.

See L<Template::Alloy> for more details.

=back

=head1 OPERATOR LIST

The following operators are available in Template::Alloy.  Except
where noted these are the same operators available in TT.  They are
listed in the order of their precedence (the higher the precedence the
tighter it binds).

=over 4

=item C<.>

The dot operator.  Allows for accessing sub-members, methods, or
virtual methods of nested data structures.

    my $obj->process(\$content, {a => {b => [0, {c => [34, 57]}]}}, \$output);

    [% a.b.1.c.0 %] => 34

Note: on access to hashrefs, any hash keys that match the sub key name
will be used before a virtual method of the same name.  For example if
a passed hash contained pair with a keyname "defined" and a value of
"2", then any calls to hash.defined(another_keyname) would always
return 2 rather than using the vmethod named "defined."  To get around
this limitation use the "|" operator (listed next).  Also - on objects
the "." will always try and call the method by that name.  To always
call the vmethod - use "|".

=item C<|>

The pipe operator.  Similar to the dot operator.  Allows for
explicit calling of virtual methods and filters (filters are "merged"
with virtual methods in Template::Alloy and TT3) when accessing
hashrefs and objects.  See the note for the "." operator.

The pipe character is similar to TT2 in that it can be used in place
of a directive as an alias for FILTER.  It similar to TT3 in that it
can be used for virtual method access.  This duality is one source of
difference between Template::Alloy and TT2 compatibility.  Templates
that have directives that end with a variable name that then use the
"|" directive to apply a filter will be broken as the "|" will be
applied to the variable name.

The following two cases will do the same thing.

    [% foo | html %]

    [% foo FILTER html %]

Though they do the same thing, internally, foo|html is stored as a
single variable while "foo FILTER html" is stored as the variable foo
which is then passed to the FILTER html.

A TT2 sample that would break in Template::Alloy or TT3 is:

    [% PROCESS foo a = b | html %]

Under TT2 the content returned by "PROCESS foo a = b" would all be
passed to the html filter.  Under Template::Alloy and TT3, b would
be passed to the html filter before assigning it to the variable "a"
before the template foo was processed.

A simple fix is to do any of the following:

    [% PROCESS foo a = b FILTER html %]

    [% | html %][% PROCESS foo a = b %][% END %]

    [% FILTER html %][% PROCESS foo a = b %][% END %]

This shouldn't be too much hardship and offers the great return of disambiguating
virtual method access.

=item C<\>

Unary.  The reference operator.  Not well publicized in TT.  Stores a reference
to a variable for use later.  Can also be used to "alias" long names.

    [% f = 7 ; foo = \f ; f = 8 ; foo %] => 8

    [% foo = \f.g.h.i.j.k; f.g.h.i.j.k = 7; foo %] => 7

    [% f = "abcd"; foo = \f.replace("ab", "-AB-") ; foo %] => -AB-cd

    [% f = "abcd"; foo = \f.replace("bc") ; foo("-BC-") %] => a-BC-d

    [% f = "abcd"; foo = \f.replace ; foo("cd", "-CD-") %] => ab-CD-

=item C<++ -->

Pre and post increment and decrement.  My be used as either a prefix
or postfix operator.

    [% ++a %][% ++a %] => 12

    [% a++ %][% a++ %] => 01

    [% --a %][% --a %] => -1-2

    [% a-- %][% a-- %] => 0-1

=item C<**  ^  pow>

Right associative binary.  X raised to the Y power.  This isn't available in TT 2.15.

    [% 2 ** 3 %] => 8

=item C<!>

Prefix not.  Negation of the value.

=item C<->

Prefix minus.  Returns the value multiplied by -1.

    [% a = 1 ; b = -a ; b %] => -1

=item C<*>

Left associative binary. Multiplication.

=item C</  div  DIV>

Left associative binary. Division.  Note that / is floating point division, but div and
DIV are integer division.

   [% 10  /  4 %] => 2.5
   [% 10 div 4 %] => 2

=item C<%  mod  MOD>

Left associative binary. Modulus.

   [% 15 % 8 %] => 7

=item C<+>

Left associative binary.  Addition.

=item C<->

Left associative binary.  Minus.

=item C<_  ~>

Left associative binary.  String concatenation.

    [% "a" ~ "b" %] => ab

=item C<< <  >  <=  >= >>

Non associative binary.  Numerical comparators.

=item C<lt  gt  le  ge>

Non associative binary.  String comparators.

=item C<eq>

Non associative binary.  String equality test.

=item C<==>

Non associative binary. In TT syntaxes the V2EQUALS configuration
item defaults to true which means this operator will operate
the same as the "eq" operator.  Setting V2EQUALS to 0 will
change this operator to mean numeric equality.  You could also use [% ! (a <=> b) %]
but that is a bit messy.

The HTML::Template syntaxes default V2EQUALS to 0 which means
that it will test for numeric equality just as you would normally
expect.

In either case - you should always use "eq" when you mean "eq".
The V2EQUALS will most likely eventually default to 0.

=item C<ne>

Non associative binary.  String non-equality test.

=item C<!=>

Non associative binary. In TT syntaxes the V2EQUALS configuration
item defaults to true which means this operator will operate
the same as the "ne" operator.  Setting V2EQUALS to 0 will
change this operator to mean numeric non-equality.
You could also use [% (a <=> b) %] but that is a bit messy.

The HTML::Template syntaxes default V2EQUALS to 0 which means
that it will test for numeric non-equality just as you would
normally expect.

In either case - you should always use "ne" when you mean "ne".
The V2EQUALS will most likely eventually default to 0.

=item C<< <=> >>

Non associative binary.  Numeric comparison operator.  Returns -1 if the first argument is
less than the second, 0 if they are equal, and 1 if the first argument is greater.

=item C<< cmp >>

Non associative binary.  String comparison operator.  Returns -1 if the first argument is
less than the second, 0 if they are equal, and 1 if the first argument is greater.

=item C<&&>

Left associative binary.  And.  All values must be true.  If all values are true, the last
value is returned as the truth value.

    [% 2 && 3 && 4 %] => 4

=item C<||>

Right associative binary.  Or.  The first true value is returned.

    [% 0 || '' || 7 %] => 7

Note: perl is left associative on this operator - but it doesn't matter because
|| has its own precedence level.  Setting it to right allows for Alloy to short
circuit earlier in the expression optree (left is (((1,2), 3), 4) while right
is (1, (2, (3, 4))).

=item C<//>

Right associative binary.  Perl 6 err.  The first defined value is returned.

    [% foo // bar %]

=item C<..>

Non associative binary.  Range creator.  Returns an arrayref containing the values
between and including the first and last arguments.

    [% t = [1 .. 5] %] => variable t contains an array with 1,2,3,4, and 5

It is possible to place multiple ranges in the same [] constructor.  This is not available in TT.

    [% t = [1..3, 6..8] %] => variable t contains an array with 1,2,3,6,7,8

The .. operator is the only operator that returns a list of items.

=item C<? :>

Ternary - right associative.  Can be nested with other ?: pairs.

    [% 1 ? 2 : 3 %] => 2
    [% 0 ? 2 : 3 %] => 3

=item C<*= += -= /= **= %= ~=>

Self-modifying assignment - right associative.  Sets the left hand side
to the operation of the left hand side and right (clear as mud).
In order to not conflict with SET, FOREACH and other operations, this
operator is only available in parenthesis.

   [% a = 2 %][%  a += 3  %] --- [% a %]    => --- 5   # is handled by SET
   [% a = 2 %][% (a += 3) %] --- [% a %]    => 5 --- 5

=item C<=>

Assignment - right associative.  Sets the left-hand side to the value of the righthand side.  In order
to not conflict with SET, FOREACH and other operations, this operator is only
available in parenthesis.  Returns the value of the righthand side.

   [%  a = 1  %] --- [% a %]    => --- 1   # is handled by SET
   [% (a = 1) %] --- [% a %]    => 1 --- 1

=item C<not  NOT>

Prefix. Lower precedence version of the '!' operator.

=item C<and  AND>

Left associative. Lower precedence version of the '&&' operator.

=item C<or OR>

Right associative. Lower precedence version of the '||' operator.

=item C<err ERR>

Right associative.  Lower precedence version of the '//' operator.

=item C<-E<gt>> (Not in TT2)

Macro operator.  Works like the MACRO directive but can be used in
map, sort, and grep list operations.  Syntax is based on the Perl 6
pointy sub.  There are two diffences from the MACRO directive.  First
is that if no argument list is specified, a default argument list with
a single parameter named "this" will be used.  Second, the C<-E<gt>>
operator parses its block as if it was already in a template tag.

    [% foo = ->{ "Hi" } %][% foo %] => Hi
    [% foo = ->{ this.repeat(2) } %][% foo("Hi") %] => HiHi
    [% foo = ->(n){ n.repeat(2) } %][% foo("Hi") %] => HiHi
    [% foo = ->(a,b){ a; "|"; b } %][% foo(2,3) %]  => 2|3

    [% [0..10].grep(->{ this % 2 }).join %] => 1 3 5 7 9
    [% ['a'..'c'].map(->{ this.upper }).join %] => A B C

    [% [1,2,3].sort(->(a,b){ b <=> a }).join %] prints 3 2 1

    [% c = [{k => "wow"}, {k => "wee"}, {k => "a"}] %]
    [% c.sort(->(a,b){ a.k cmp b.k }).map(->{this.k}).join %] => a wee wow

Note: Care should be used when attempting to sort large lists.
The mini-language of Template::Alloy is a interpreted language running
in Perl which is an interpreted language.  There are likely to be
performance issues when trying to do low level functions such as sort
on large lists.

The RETURN directive and return item, list, and hash vmethods can be
used to return more interesting values from a MACRO.

  [% a = ->(n){ [1..n].return } %]
  [% a(3).join %]    => 1 2 3
  [% a(10).join %]   => 1 2 3 4 5 6 7 8 9 10

The Schwartzian transform is now possible in Template::Alloy (somebody
somewhere is rolling over in their grave).

  [%- qw(Z a b D y M)
        .map(->{ [this.lc, this].return })
        .sort(->(a,b){a.0 cmp b.0})
        .map(->{this.1})
        .join %]          => a b D M y Z

=item C<{}>

This operator is not exposed for external use.  It is used internally
by Template::Alloy to delay the creation of a hash until the
execution of the compiled template.

=item C<[]>

This operator is not exposed for external use.  It is used internally
by Template::Alloy to delay the creation of an array until the
execution of the compiled template.

=item C<@()>

List context specifier.  Methods or functions inside this operator
will always be called in list context and will always return an
arrayref of the results.  See the CALL_CONTEXT configuration
directive.

=item C<$()>

Item context specifier.  Methods or functions inside this operator
will always be called in item (scalar) context.  See the CALL_CONTEXT
configuration directive.

=item C<qr>

This operator is not exposed for external use.  It is used internally
by Template::Alloy to store a regular expression and its options.
It will return a compiled Regexp object when compiled.

=item C<-temp->

This operator is not exposed for external use.  It is used internally
by some directives to pass temporary, literal data into play_expr
to allow additional vmethods or filters to be called on existing data.

=back

=head1 AUTHOR

Paul Seamons <paul at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
