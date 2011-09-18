package Template::Alloy::Parse;

=head1 NAME

Template::Alloy::Parse - Common parsing role for creating AST from templates

=cut

use strict;
use warnings;
use base qw(Exporter);
use Template::Alloy;
use Template::Alloy::Operator qw($QR_OP $QR_OP_ASSIGN $QR_OP_PREFIX
                                 $OP $OP_ASSIGN $OP_PREFIX $OP_POSTFIX);

our $VERSION   = $Template::Alloy::VERSION;
our @EXPORT_OK = qw(define_directive define_syntax
                    $ALIASES $DIRECTIVES $TAGS $QR_DIRECTIVE $QR_COMMENTS);

sub new { die "This class is a role for use by packages such as Template::Alloy" }

###----------------------------------------------------------------###

our $TAGS = {
    asp       => ['<%',     '%>'    ], # ASP
    default   => ['\[%',    '%\]'   ], # default
    html      => ['<!--',   '-->'   ], # HTML comments
    mason     => ['<%',     '>'     ], # HTML::Mason
    metatext  => ['%%',     '%%'    ], # Text::MetaText
    php       => ['<\?',    '\?>'   ], # PHP
    star      => ['\[\*',   '\*\]'  ], # TT alternate
    template  => ['\[%',    '%\]'   ], # Normal Template Toolkit
    template1 => ['[\[%]%', '%[%\]]'], # TT1
    tt2       => ['\[%',    '%\]'   ], # TT2
};

our $SYNTAX = {
    alloy    => sub { shift->parse_tree_tt3(@_) },
    ht       => sub { my $self = shift; local $self->{'V2EQUALS'} = 0; local $self->{'EXPR'} = 0; $self->parse_tree_hte(@_) },
    hte      => sub { my $self = shift; local $self->{'V2EQUALS'} = 0; $self->parse_tree_hte(@_) },
    tt3      => sub { shift->parse_tree_tt3(@_) },
    tt2      => sub { my $self = shift; local $self->{'V2PIPE'} = 1; $self->parse_tree_tt3(@_) },
    tt1      => sub { my $self = shift; local $self->{'V2PIPE'} = 1; local $self->{'V1DOLLAR'} = 1; $self->parse_tree_tt3(@_) },
    tmpl     => sub { shift->parse_tree_tmpl(@_) },
    velocity => sub { shift->parse_tree_velocity(@_) },
};

our $DIRECTIVES = {
    #name       parse_sub        play_sub         block    postdir  continue  no_interp
    BLOCK   => [\&parse_BLOCK,   \&play_BLOCK,    1],
    BREAK   => [sub {},          \&play_control],
    CALL    => [\&parse_CALL,    \&play_CALL],
    CASE    => [\&parse_CASE,    undef,           0,       0,       {SWITCH => 1, CASE => 1}],
    CATCH   => [\&parse_CATCH,   undef,           0,       0,       {TRY => 1, CATCH => 1}],
    CLEAR   => [sub {},          \&play_CLEAR],
    '#'     => [sub {},          sub {}],
    COMMENT => [sub {},          sub {},          1],
    CONFIG  => [\&parse_CONFIG,  \&play_CONFIG],
    DEBUG   => [\&parse_DEBUG,   \&play_DEBUG],
    DEFAULT => [\&parse_DEFAULT, \&play_DEFAULT],
    DUMP    => [\&parse_DUMP,    \&play_DUMP],
    ELSE    => [sub {},          undef,           0,       0,       {IF => 1, ELSIF => 1, UNLESS => 1}],
    ELSIF   => [\&parse_IF,      undef,           0,       0,       {IF => 1, ELSIF => 1, UNLESS => 1}],
    END     => [sub {},          sub {}],
    EVAL    => [\&parse_EVAL,    \&play_EVAL],
    FILTER  => [\&parse_FILTER,  \&play_FILTER,   1,       1],
    '|'     => [\&parse_FILTER,  \&play_FILTER,   1,       1],
    FINAL   => [sub {},          undef,           0,       0,       {TRY => 1, CATCH => 1}],
    FOR     => [\&parse_FOR,     \&play_FOR,      1,       1],
    FOREACH => [\&parse_FOR,     \&play_FOR,      1,       1],
    GET     => [\&parse_GET,     \&play_GET],
    IF      => [\&parse_IF,      \&play_IF,       1,       1],
    INCLUDE => [\&parse_INCLUDE, \&play_INCLUDE],
    INSERT  => [\&parse_INSERT,  \&play_INSERT],
    LAST    => [sub {},          \&play_control],
    LOOP    => [\&parse_LOOP,    \&play_LOOP,     1,       1],
    MACRO   => [\&parse_MACRO,   \&play_MACRO],
    META    => [\&parse_META,    \&play_META],
    NEXT    => [sub {},          \&play_control],
    PERL    => [sub {},          \&play_PERL,     1,       0,       0,        1],
    PROCESS => [\&parse_PROCESS, \&play_PROCESS],
    RAWPERL => [sub {},          \&play_RAWPERL,  1,       0,       0,        1],
    RETURN  => [\&parse_RETURN,  \&play_control],
    SET     => [\&parse_SET,     \&play_SET],
    STOP    => [sub {},          \&play_control],
    SWITCH  => [\&parse_SWITCH,  \&play_SWITCH,   1],
    TAGS    => [\&parse_TAGS,    sub {}],
    THROW   => [\&parse_THROW,   \&play_THROW],
    TRY     => [sub {},          \&play_TRY,      1],
    UNLESS  => [\&parse_UNLESS,  \&play_UNLESS,   1,       1],
    USE     => [\&parse_USE,     \&play_USE],
    VIEW    => [\&parse_VIEW,    \&play_VIEW,     1],
    WHILE   => [\&parse_WHILE,   \&play_WHILE,    1,       1],
    WRAPPER => [\&parse_WRAPPER, \&play_WRAPPER,  1,       1],
    #name       parse_sub        play_sub         block    postdir  continue  no_interp
};
our $ALIASES = {
    EVALUATE => 'EVAL',
};


our $QR_DIRECTIVE = '( [a-zA-Z]+\b | \| )';
our $QR_COMMENTS  = '(?-s: \# .* \s*)*';
our $QR_FILENAME  = '([a-zA-Z]]:/|/)? [\w\.][\w\-\.]* (?:/[\w\-\.]+)*';
our $QR_BLOCK     = '\w+\b (?: :\w+\b)* )';
our $QR_NUM       = '(?:\d*\.\d+ | \d+) (?: [eE][+-]?\d+ )?';
our $QR_AQ_SPACE  = '(?: \\s+ | \$ | (?=;) )';

our $_escapes = {n => "\n", r => "\r", t => "\t", '"' => '"', '\\' => '\\', '$' => '$'};
our $QR_ESCAPES = qr{[nrt\"\$\\]};

sub define_directive {
    my ($self, $name, $args) = @_;
    $DIRECTIVES->{$name} = [@{ $args }{qw(parse_sub play_sub is_block is_postop continues no_interp)}];
    return 1;
}

sub define_syntax {
    my ($self, $name, $sub) = @_;
    $SYNTAX->{$name} = $sub;
    return 1;
}

###----------------------------------------------------------------###

sub parse_tree {
    my $syntax = $_[0]->{'SYNTAX'} || 'alloy';
    my $meth   = $SYNTAX->{$syntax} || $_[0]->throw('config', "Unknown SYNTAX \"$syntax\"");
    return $meth->(@_);
}

###----------------------------------------------------------------###

sub parse_expr {
    my $self    = shift;
    my $str_ref = shift;
    my $ARGS    = shift || {};
    my $is_aq   = $ARGS->{'auto_quote'} ? 1 : 0;
    my $mark    = pos $$str_ref;

    ### allow for custom auto_quoting (such as hash constructors)
    if ($is_aq) {
        if ($$str_ref =~ m{ \G \s* $QR_COMMENTS $ARGS->{'auto_quote'} }gcx) {
            return $1;

        ### allow for ${foo.bar} type constructs
        } elsif ($$str_ref =~ m{ \G \$\{ }gcx) {
            my $var = $self->parse_expr($str_ref);
            $$str_ref =~ m{ \G \s* $QR_COMMENTS \} }gcxo
                || $self->throw('parse', 'Missing close "}" from "${"', undef, pos($$str_ref));
            return $var;

        ### allow for auto-quoted $foo
        } elsif ($$str_ref =~ m{ \G \$ }gcx) {
            return $self->parse_expr($str_ref)
                || $self->throw('parse', "Missing variable", undef, pos($$str_ref));
        }
    }

    $$str_ref =~ m{ \G \s* $QR_COMMENTS }gcxo;

    ### allow for macro definer
    if ($$str_ref =~ m{ \G -> \s* }gcxo) { # longest token would be nice - until then this comes before prefix
        local $self->{'_operator_precedence'} = 0; # reset presedence
        my $args;
        if ($$str_ref =~ m{ \G \( \s* }gcx) {
            $args = $self->parse_args($str_ref, {positional_only => 1});
            $$str_ref =~ m{ \G \) \s* }gcx || $self->throw('parse.missing', "Missing close ')'", undef, pos($$str_ref));
        }
        $$str_ref =~ m{ \G \{ $QR_COMMENTS }gcx || $self->throw('parse.missing', "Missing open '{'", undef, pos($$str_ref));
        local $self->{'END_TAG'} = qr{ \} }x;
        my $tree = $self->parse_tree_tt3($str_ref, 'one_tag_only');
        return [[undef, '->', $args || [['this',0]], $tree]];
    }

    ### test for leading prefix operators
    my $has_prefix;
    while (! $is_aq && $$str_ref =~ m{ \G ($QR_OP_PREFIX) }gcxo) {
        push @{ $has_prefix }, $1;
        $$str_ref =~ m{ \G \s* $QR_COMMENTS }gcxo;
    }

    my @var;
    my $is_literal;
    my $is_namespace;
    my $already_parsed_args;

    ### allow hex
    if ($$str_ref =~ m{ \G 0x ( [a-fA-F0-9]+ ) }gcx) {
        my $number = eval { hex $1 } || 0;
        push @var, \ $number;
        $is_literal = 1;

    ### allow for numbers
    } elsif ($$str_ref =~ m{ \G ( $QR_NUM ) }gcx) {
        my $number = 0 + $1;
        push @var, \ $number;
        $is_literal = 1;

    ### allow for quoted array constructor
    } elsif (! $is_aq && $$str_ref =~ m{ \G qw ([^\w\s]) \s* }gcxo) {
        my $quote = $1;
        $quote =~ y|([{<|)]}>|;
        $$str_ref =~ m{ \G (.*?) (?<!\\) \Q$quote\E }gcxs
            || $self->throw('parse.missing.array_close', "Missing close \"$quote\"", undef, pos($$str_ref));
        my $str = $1;
        $str =~ s{ ^ \s+ }{}x;
        $str =~ s{ \s+ $ }{}x;
        $str =~ s{ \\ \Q$quote\E }{$quote}gx;
        push @var, [undef, '[]', split /\s+/, $str];

    ### looks like a normal variable start
    } elsif ($$str_ref =~ m{ \G (\w+) }gcx) {
        push @var, $1;
        $is_namespace = 1 if $self->{'NAMESPACE'} && $self->{'NAMESPACE'}->{$1};

    ### allow for regex constructor
    } elsif (! $is_aq && $$str_ref =~ m{ \G / }gcx) {
        $$str_ref =~ m{ \G (.*?) (?<! \\) / ([msixeg]*) }gcxs
            || $self->throw('parse', 'Unclosed regex tag "/"', undef, pos($$str_ref));
        my ($str, $opts) = ($1, $2);
        $self->throw('parse', 'e option not allowed on regex',   undef, pos($$str_ref)) if $opts =~ /e/;
        $self->throw('parse', 'g option not supported on regex', undef, pos($$str_ref)) if $opts =~ /g/;
        $str =~ s|\\n|\n|g;
        $str =~ s|\\t|\t|g;
        $str =~ s|\\r|\r|g;
        $str =~ s|\\\/|\/|g;
        $str =~ s|\\\$|\$|g;
        $self->throw('parse', "Invalid regex: $@", undef, pos($$str_ref)) if ! eval { "" =~ /$str/; 1 };
        push @var, [undef, 'qr', $str, $opts];

    ### allow for single quoted strings
    } elsif ($$str_ref =~ m{ \G \' (.*?) (?<! \\) \' }gcxs) {
        my $str = $1;
        $str =~ s{ \\\' }{\'}xg;
        return $str if $is_aq;
        push @var, \ $str;
        $is_literal = 1;

    ### allow for double quoted strings
    } elsif ($$str_ref =~ m{ \G \" }gcx) {
        my @pieces;
        while ($$str_ref =~ m{ \G (.*?) ([\"\$\\]) }gcxs) {
            my ($str, $item) = ($1, $2);
            if (length $str) {
                if (defined($pieces[-1]) && ! ref($pieces[-1])) { $pieces[-1] .= $str; } else { push @pieces, $str }
            }
            if ($item eq '\\') {
                my $chr = ($$str_ref =~ m{ \G ($QR_ESCAPES) }gcxo) ? $_escapes->{$1} : '\\';
                if (defined($pieces[-1]) && ! ref($pieces[-1])) { $pieces[-1] .= $chr; } else { push @pieces, $chr }
                next;
            } elsif ($item eq '"') {
                last;
            } elsif ($self->{'AUTO_EVAL'}) {
                if (defined($pieces[-1]) && ! ref($pieces[-1])) { $pieces[-1] .= '$'; } else { push @pieces, '$' }
                next;
            }

            my $not  = $$str_ref =~ m{ \G ! }gcx;
            my $mark = pos($$str_ref);
            my $ref;
            if ($$str_ref =~ m{ \G \{ }gcx) {
                local $self->{'_operator_precedence'} = 0; # allow operators
                $ref = $self->parse_expr($str_ref);
                $$str_ref =~ m{ \G \s* $QR_COMMENTS \} }gcxo
                    || $self->throw('parse', 'Missing close }', undef, pos($$str_ref));
            } else {
                local $self->{'_operator_precedence'} = 1; # no operators
                $ref = $self->parse_expr($str_ref)
                    || $self->throw('parse', "Error while parsing for interpolated string", undef, pos($$str_ref));
            }
            if (! $not && $self->{'SHOW_UNDEFINED_INTERP'}) {
                $ref = [[undef, '//', $ref, '$'.substr($$str_ref, $mark, pos($$str_ref)-$mark)], 0];
            }
            push @pieces, $ref if defined $ref;
        }
        if (! @pieces) { # [% "" %]
            return '' if $is_aq;
            push @var, \ '';
            $is_literal = 1;
        } elsif (@pieces == 1 && ref $pieces[0]) { # [% "$foo" %] or [% "${ 1 + 2 }" %]
            return $pieces[0] if $is_aq;
            push @var, @{ $pieces[0] };
            $already_parsed_args = 1;
        } elsif ($self->{'AUTO_EVAL'}) {
            push @var, [undef, '~', @pieces], 0, '|', 'eval', 0;
            return \@var if $is_aq;
            $already_parsed_args = 1;
        } elsif (@pieces == 1) { # [% "foo" %]
            return $pieces[0] if $is_aq;
            push @var, \ $pieces[0];
            $is_literal = 1;
        } else { # [% "foo $bar baz" %]
            push @var, [undef, '~', @pieces];
            return [$var[0], 0] if $is_aq;
        }

    ### allow for leading $foo type constructs
    } elsif ($$str_ref =~ m{ \G \$ (\w+) \b }gcx) {
        if ($self->{'V1DOLLAR'}) {
            push @var, $1;
            $is_namespace = 1 if $self->{'NAMESPACE'} && $self->{'NAMESPACE'}->{$1};
        } else {
            push @var, [$1, 0];
        }

    ### allow for ${foo.bar} type constructs
    } elsif ($$str_ref =~ m{ \G \$\{ }gcx) {
        push @var, $self->parse_expr($str_ref);
        $$str_ref =~ m{ \G \s* $QR_COMMENTS \} }gcxo
            || $self->throw('parse', 'Missing close "}" from "${"', undef, pos($$str_ref));

    ### looks like an array constructor
    } elsif (! $is_aq && $$str_ref =~ m{ \G \[ }gcx) {
        local $self->{'_operator_precedence'} = 0; # reset presedence
        my $arrayref = [undef, '[]'];
        while (defined(my $var = $self->parse_expr($str_ref))) {
            push @$arrayref, $var;
            $$str_ref =~ m{ \G \s* $QR_COMMENTS , }gcxo;
        }
        $$str_ref =~ m{ \G \s* $QR_COMMENTS \] }gcxo
            || $self->throw('parse.missing.square_bracket', "Missing close \]", undef, pos($$str_ref));
        push @var, $arrayref;

    ### looks like a hash constructor
    } elsif (! $is_aq && $$str_ref =~ m{ \G \{ }gcx) {
        local $self->{'_operator_precedence'} = 0; # reset precedence
        my $hashref = [undef, '{}'];
        while (defined(my $key = $self->parse_expr($str_ref, {auto_quote => "(\\w+\\b) (?! \\.) \\s* $QR_COMMENTS"}))) {
            $$str_ref =~ m{ \G \s* $QR_COMMENTS (?: = >? | [:,]) }gcxo;
            my $val = $self->parse_expr($str_ref);
            push @$hashref, $key, $val;
            $$str_ref =~ m{ \G \s* $QR_COMMENTS , }gcxo;
        }
        $$str_ref =~ m{ \G \s* $QR_COMMENTS \} }gcxo
            || $self->throw('parse.missing.curly_bracket', "Missing close \}", undef, pos($$str_ref));
        push @var, $hashref;

    ### looks like a paren grouper or a context specifier
    } elsif (! $is_aq && $$str_ref =~ m{ \G ([\$\@]?) \( }gcx) {
        local $self->{'_operator_precedence'} = 0; # reset precedence
        my $ctx = $1;
        my $var = $self->parse_expr($str_ref, {allow_parened_ops => 1});

        $$str_ref =~ m{ \G \s* $QR_COMMENTS \) }gcxo
            || $self->throw('parse.missing.paren', "Missing close \) in group", undef, pos($$str_ref));

        $self->throw('parse', 'Paren group cannot be followed by an open paren', undef, pos($$str_ref))
            if $$str_ref =~ m{ \G \( }gcx;
        $already_parsed_args = 1;

        if (! ref $var) {
            push @var, \$var, 0;
            $is_literal = 1;
        } elsif (! defined $var->[0]) {
            push @var, $var, 0;
        } else {
            push @var, @$var;
        }
        if ($ctx) {
            my $copy = [@var];
            @var = ([undef, "$ctx()", $copy], 0);
        }

    ### nothing to find - return failure
    } else {
        pos($$str_ref) = $mark if $is_aq || $has_prefix;
        return;
    }

    # auto_quoted thing was too complicated
    if ($is_aq) {
        pos($$str_ref) = $mark;
        return;
    }

    ### looks for args for the initial
    if ($already_parsed_args) {
        # do nothing
    } elsif ($$str_ref =~ m{ \G \( }gcxo) {
        local $self->{'_operator_precedence'} = 0; # reset precedence
        my $args = $self->parse_args($str_ref, {is_parened => 1});
        $$str_ref =~ m{ \G \s* $QR_COMMENTS \) }gcxo
            || $self->throw('parse.missing.paren', "Missing close \) in args", undef, pos($$str_ref));
        push @var, $args;
    } else {
        push @var, 0;
    }

    ### allow for nested items
    while ($$str_ref =~ m{ \G \s* $QR_COMMENTS ( \.(?!\.) | \|(?!\|) ) }gcx) {
        if ($1 eq '|' && $self->{'V2PIPE'}) {
            pos($$str_ref) -= 1;
            last;
        }

        push(@var, $1) if ! $ARGS->{'no_dots'};

        $$str_ref =~ m{ \G \s* $QR_COMMENTS }gcxo;

        ### allow for interpolated variables in the middle - one.$foo.two
        if ($$str_ref =~ m{ \G \$ (\w+) \b }gcxo) {
            push @var, $self->{'V1DOLLAR'} ? $1 : [$1, 0];

        ### or one.${foo.bar}.two
        } elsif ($$str_ref =~ m{ \G \$\{ }gcx) {
            push @var, $self->parse_expr($str_ref);
            $$str_ref =~ m{ \G \s* $QR_COMMENTS \} }gcxo
                || $self->throw('parse', 'Missing close "}" from "${"', undef, pos($$str_ref));

        ### allow for names (foo.bar or foo.0 or foo.-1)
        } elsif ($$str_ref =~ m{ \G (-? \w+) }gcx) {
            push @var, $1;

        } else {
            $self->throw('parse', "Not sure how to continue parsing", undef, pos($$str_ref));
        }

        ### looks for args for the nested item
        if ($$str_ref =~ m{ \G \( }gcx) {
            local $self->{'_operator_precedence'} = 0; # reset precedence
            my $args = $self->parse_args($str_ref, {is_parened => 1});
            $$str_ref =~ m{ \G \s* $QR_COMMENTS \) }gcxo
                || $self->throw('parse.missing.paren', "Missing close \) in args of nested item", undef, pos($$str_ref));
            push @var, $args;
        } else {
            push @var, 0;
        }

    }

    ### flatten literals and constants as much as possible
    my $var;
    if ($is_literal) {
        $var = ${ $var[0] };
        if ($#var != 1) {
            $var[0] = [undef, '~', $var];
            $var = \@var;
        }
    } elsif ($is_namespace) {
        my $name = $var[0];
        local $self->{'_vars'}->{$name} = $self->{'NAMESPACE'}->{$name};
        $var = $self->play_expr(\@var, {is_namespace_during_compile => 1});
    } else {
        $var = \@var;
    }

    ### allow for all "operators"
    if (! $self->{'_operator_precedence'}) {
        my $tree;
        my $found;
        while (1) {
            my $mark = pos $$str_ref;

            $$str_ref =~ m{ \G \s* $QR_COMMENTS }gcxo;

            if ($self->{'_end_tag'} && $$str_ref =~ m{ \G [+=~-]? $self->{'_end_tag'} }gcx) {
                pos($$str_ref) = $mark;
                last;
            } elsif ($$str_ref !~ m{ \G ($QR_OP) }gcxo) {
                pos($$str_ref) = $mark;
                last;
            }
            if ($OP_ASSIGN->{$1} && ! $ARGS->{'allow_parened_ops'}) { # only allow assignment in parens
                pos($$str_ref) = $mark;
                last;
            }
            local $self->{'_operator_precedence'} = 1;
            my $op = $1;
            $op = 'eq' if $op eq '==' && (! defined($self->{'V2EQUALS'}) || $self->{'V2EQUALS'});
            $op = 'ne' if $op eq '!=' && (! defined($self->{'V2EQUALS'}) || $self->{'V2EQUALS'});

            ### allow for postfix - doesn't check precedence - someday we might change - but not today (only affects post ++ and --)
            if ($OP_POSTFIX->{$op}) {
                $var = [[undef, $op, $var, 1], 0]; # cheat - give a "second value" to postfix ops
                next;

            ### allow for prefix operator precedence
            } elsif ($has_prefix && $OP->{$op}->[1] < $OP_PREFIX->{$has_prefix->[-1]}->[1]) {
                if ($tree) {
                    if ($#$tree == 1) { # only one operator - keep simple things fast
                        $var = [[undef, $tree->[0], $var, $tree->[1]], 0];
                    } else {
                        unshift @$tree, $var;
                        $var = $self->apply_precedence($tree, $found, $str_ref);
                    }
                    undef $tree;
                    undef $found;
                }
                $var = [[undef, $has_prefix->[-1], $var ], 0];
                pop @$has_prefix;
                $has_prefix = undef if ! @$has_prefix;
            }

            ### add the operator to the tree
            my $var2 = $self->parse_expr($str_ref);
            $self->throw('parse', 'Missing variable after "'.$op.'"', undef, pos($$str_ref)) if ! defined $var2;
            push (@{ $tree ||= [] }, $op, $var2);
            $found->{$OP->{$op}->[1]}->{$op} = 1; # found->{precedence}->{op}
        }

        ### if we found operators - tree the nodes by operator precedence
        if ($tree) {
            if (@$tree == 2) { # only one operator - keep simple things fast
                if ($OP->{$tree->[0]}->[0] eq 'assign' && $tree->[0] =~ /(.+)=/) {
                    $var = [[undef, '=', $var, [[undef, $1, $var, $tree->[1]], 0]], 0]; # "a += b" => "a = a + b"
                } else {
                    $var = [[undef, $tree->[0], $var, $tree->[1]], 0];
                }
            } else {
                unshift @$tree, $var;
                $var = $self->apply_precedence($tree, $found, $str_ref);
            }
        }
    }

    ### allow for prefix on non-chained variables
    if ($has_prefix) {
        $var = [[undef, $_, $var], 0] for reverse @$has_prefix;
    }

    return $var;
}

### this is used to put the parsed variables into the correct operations tree
sub apply_precedence {
    my ($self, $tree, $found, $str_ref) = @_;

    my @var;
    my $trees;
    ### look at the operators we found in the order we found them
    for my $prec (sort keys %$found) {
        my $ops = $found->{$prec};
        local $found->{$prec};
        delete $found->{$prec};

        ### split the array on the current operators for this level
        my @ops;
        my @exprs;
        for (my $i = 1; $i <= $#$tree; $i += 2) {
            next if ! $ops->{ $tree->[$i] };
            push @ops, $tree->[$i];
            push @exprs, [splice @$tree, 0, $i, ()];
            shift @$tree;
            $i = -1;
        }
        next if ! @exprs; # this iteration didn't have the current operator
        push @exprs, $tree if scalar @$tree; # add on any remaining items

        ### simplify sub expressions
        for my $node (@exprs) {
            if (@$node == 1) {
                $node = $node->[0]; # single item - its not a tree
            } elsif (@$node == 3) {
                $node = [[undef, $node->[1], $node->[0], $node->[2]], 0]; # single operator - put it straight on
            } else {
                $node = $self->apply_precedence($node, $found, $str_ref); # more complicated - recurse
            }
        }

        ### assemble this current level

        ### some rules:
        # 1) items at the same precedence level must all be either right or left or ternary associative
        # 2) ternary items cannot share precedence with anybody else.
        # 3) there really shouldn't be another operator at the same level as a postfix
        my $type = $OP->{$ops[0]}->[0];

        if ($type eq 'ternary') {
            my $op = $OP->{$ops[0]}->[2]->[0]; # use the first op as what we are using

            ### return simple ternary
            if (@exprs == 3) {
                $self->throw('parse', "Ternary operator mismatch", undef, pos($$str_ref)) if $ops[0] ne $op;
                $self->throw('parse', "Ternary operator mismatch", undef, pos($$str_ref)) if ! $ops[1] || $ops[1] eq $op;
                return [[undef, $op, @exprs], 0];
            }


            ### reorder complex ternary - rare case
            while ($#ops >= 1) {
                ### if we look starting from the back - the first lead ternary op will always be next to its matching op
                for (my $i = $#ops; $i >= 0; $i --) {
                    next if $OP->{$ops[$i]}->[2]->[1] eq $ops[$i];
                    my ($op, $op2) = splice @ops, $i, 2, (); # remove the pair of operators
                    my $node = [[undef, $op, @exprs[$i .. $i + 2]], 0];
                    splice @exprs, $i, 3, $node;
                }
            }
            return $exprs[0]; # at this point the ternary has been reduced to a single operator

        } elsif ($type eq 'right' || $type eq 'assign') {
            my $val = $exprs[-1];
            for (reverse (0 .. $#exprs - 1)) {
                if ($type eq 'assign' && $ops[$_ - 1] =~ /(.+)=$/) {
                    $val = [[undef, '=', $exprs[$_], [[undef, $1, $exprs[$_], $val], 0]], 0];
                } else {
                    $val = [[undef, $ops[$_ - 1], $exprs[$_], $val], 0];
                }
            }
            return $val;

        } else {
            my $val = $exprs[0];
            $val = [[undef, $ops[$_ - 1], $val, $exprs[$_]], 0] for (1 .. $#exprs);
            return $val;

        }
    }

    $self->throw('parse', "Couldn't apply precedence", undef, pos($$str_ref));
}

### look for arguments - both positional and named
sub parse_args {
    my $self    = shift;
    my $str_ref = shift;
    my $ARGS    = shift || {};

    my @args;
    my @named;
    my $name;
    my $end = $self->{'_end_tag'} || '(?!)';
    while (1) {
        my $mark = pos $$str_ref;

        ### look to see if the next thing is a directive or a closing tag
        if (! $ARGS->{'is_parened'}
            && ! $ARGS->{'require_arg'}
            && $$str_ref =~ m{ \G \s* $QR_COMMENTS $QR_DIRECTIVE (?: \s+ | (?: \s* $QR_COMMENTS (?: ;|[+=~-]?$end))) }gcxo
            && ((pos($$str_ref) = $mark) || 1)                  # always revert
            && $DIRECTIVES->{$self->{'ANYCASE'} ? uc($1) : $1}  # looks like a directive - we are done
            ) {
            last;
        }
        if ($$str_ref =~ m{ \G [+=~-]? $end }gcx) {
            pos($$str_ref) = $mark;
            last;
        }

        ### find the initial arg
        my $name;
        if ($ARGS->{'allow_bare_filenames'}) {
            $name = $self->parse_expr($str_ref, {auto_quote => "
              ($QR_FILENAME               # file name
              | $QR_BLOCK                 # or block
                (?= [+=~-]? $end          # an end tag
                  | \\s*[+,;]             # followed by explicit + , or ;
                  | \\s+ (?! [\\s=])      # or space not before an =
                )  \\s* $QR_COMMENTS"});
            # filenames can be separated with a "+" - why a "+" ?
            if ($$str_ref =~ m{ \G \+ (?! \s* $QR_COMMENTS [+=~-]? $end) }gcxo) {
                push @args, $name;
                $ARGS->{'require_arg'} = 1;
                next;
            }
        }
        if (! defined $name) {
            $name = $self->parse_expr($str_ref);
            if (! defined $name) {
                if ($ARGS->{'require_arg'} && ! @args && ! $ARGS->{'positional_only'} && ! @named) {
                    $self->throw('parse', 'Argument required', undef, pos($$str_ref));
                } else {
                    last;
                }
            }
        }

        $$str_ref =~ m{ \G \s* $QR_COMMENTS }gcxo;

        ### see if it is named or positional
        if ($$str_ref =~ m{ \G \s* $QR_COMMENTS = >? }gcxo) {
            $self->throw('parse', 'Named arguments not allowed', undef, $mark) if $ARGS->{'positional_only'};
            my $val = $self->parse_expr($str_ref);
            $name = $name->[0] if ref($name) && @$name == 2 && ! $name->[1]; # strip a level of indirection on named arguments
            push @named, $name, $val;
        } else {
            push @args, $name;
        }

        ### look for trailing comma
        $ARGS->{'require_arg'} = ($$str_ref =~ m{ \G \s* $QR_COMMENTS , }gcxo) || 0;
    }

    ### allow for named arguments to be added at the front (if asked)
    if ($ARGS->{'named_at_front'}) {
        unshift @args, [[undef, '{}', @named], 0];
    } elsif (scalar @named) { # only add at end - if there are some
        push @args,    [[undef, '{}', @named], 0]
    }

    return \@args;
}

###----------------------------------------------------------------###

sub parse_BLOCK {
    my ($self, $str_ref, $node) = @_;

    my $end = $self->{'_end_tag'} || '(?!)';
    my $block_name = $self->parse_expr($str_ref, {auto_quote => "
              ($QR_FILENAME               # file name
              | $QR_BLOCK                 # or block
                (?= [+=~-]? $end          # an end tag
                  | \\s*[+,;]             # followed by explicit + , or ;
                  | \\s+ (?! [\\s=])      # or space not before an =
                )  \\s* $QR_COMMENTS"});

    return '' if ! defined $block_name;

    my $prepend = join "/", map {$_->[3]} grep {ref($_) && $_->[0] eq 'BLOCK'} @{ $self->{'_state'} || {} };
    return $prepend ? "$prepend/$block_name" : $block_name;
}

sub parse_CALL { $DIRECTIVES->{'GET'}->[0]->(@_) }

sub parse_CASE {
    my ($self, $str_ref) = @_;
    return if $$str_ref =~ m{ \G DEFAULT \s* }gcx;
    return $self->parse_expr($str_ref);
}

sub parse_CATCH {
    my ($self, $str_ref) = @_;
    return $self->parse_expr($str_ref, {auto_quote => "(\\w+\\b (?: \\.\\w+\\b)*) $QR_AQ_SPACE \\s* $QR_COMMENTS"});
}

sub parse_CONFIG {
    my ($self, $str_ref) = @_;

    my %ctime = map {$_ => 1} @Template::Alloy::CONFIG_COMPILETIME;
    my %rtime = map {$_ => 1} @Template::Alloy::CONFIG_RUNTIME;

    my $mark   = pos($$str_ref);
    my $config = $self->parse_args($str_ref, {named_at_front => 1, is_parened => 1});
    my $ref = $config->[0]->[0];
    for (my $i = 2; $i < @$ref; $i += 2) {
        my $key = $ref->[$i] = uc $ref->[$i];
        my $val = $ref->[$i + 1];
        if ($ctime{$key}) {
            $self->{$key} = $self->play_expr($val);
            if ($key eq 'INTERPOLATE') {
                $self->{'_start_tag'} = (! $self->{'INTERPOLATE'}) ? $self->{'START_TAG'} : qr{(?: $self->{'START_TAG'} | (\$))}sx;
            }
        } elsif (! $rtime{$key}) {
            $self->throw('parse', "Unknown CONFIG option \"$key\"", undef, pos($$str_ref));
        }
    }
    for (my $i = 1; $i < @$config; $i++) {
        my $key = $config->[$i] = uc $config->[$i]->[0];
        if ($ctime{$key}) {
            $config->[$i] = "CONFIG $key = ".(defined($self->{$key}) ? $self->{$key} : 'undef');
        } elsif (! $rtime{$key}) {
            $self->throw('parse', "Unknown CONFIG option \"$key\"", undef, pos($$str_ref));
        }
    }
    return $config;
}

sub parse_DEBUG {
    my ($self, $str_ref) = @_;
    $$str_ref =~ m{ \G ([Oo][Nn] | [Oo][Ff][Ff] | [Ff][Oo][Rr][Mm][Aa][Tt]) \s* }gcx
        || $self->throw('parse', "Unknown DEBUG option", undef, pos($$str_ref));
    my $ret = [lc($1)];
    if ($ret->[0] eq 'format') {
        $$str_ref =~ m{ \G ([\"\']) (|.*?[^\\]) \1 \s* }gcxs
            || $self->throw('parse', "Missing format string", undef, pos($$str_ref));
        $ret->[1] = $2;
    }
    return $ret;
}

sub parse_DEFAULT { $DIRECTIVES->{'SET'}->[0]->(@_) }

sub parse_DUMP {
    my ($self, $str_ref) = @_;
    return $self->parse_args($str_ref, {named_at_front => 1});
}

sub parse_EVAL {
    my ($self, $str_ref) = @_;
    return $self->parse_args($str_ref, {named_at_front => 1});
}

sub parse_FILTER {
    my ($self, $str_ref) = @_;
    my $name = '';
    if ($$str_ref =~ m{ \G ([^\W\d]\w*) \s* = \s* }gcx) {
        $name = $1;
    }

    my $filter = $self->parse_expr($str_ref);
    $filter = '' if ! defined $filter;

    return [$name, $filter];
}

sub parse_FOR {
    my ($self, $str_ref) = @_;
    my $items = $self->parse_expr($str_ref);
    my $var;
    if ($$str_ref =~ m{ \G \s* $QR_COMMENTS (= | [Ii][Nn]\b) \s* }gcxo) {
        $var = [@$items];
        $items = $self->parse_expr($str_ref);
    }
    return [$var, $items];
}

sub parse_GET {
    my ($self, $str_ref) = @_;
    my $ref = $self->parse_expr($str_ref);
    $self->throw('parse', "Missing variable name", undef, pos($$str_ref)) if ! defined $ref;
    if ($self->{'AUTO_FILTER'}) {
        $ref = [[undef, '~', $ref], 0] if ! ref $ref;
        push @$ref, '|', $self->{'AUTO_FILTER'}, 0 if @$ref < 3 || $ref->[-3] ne '|';
    }
    return $ref;
}

sub parse_IF {
    my ($self, $str_ref) = @_;
    return $self->parse_expr($str_ref);
}

sub parse_INCLUDE { $DIRECTIVES->{'PROCESS'}->[0]->(@_) }

sub parse_INSERT { $DIRECTIVES->{'PROCESS'}->[0]->(@_) }

sub parse_LOOP {
    my ($self, $str_ref, $node) = @_;
    return $self->parse_expr($str_ref)
        || $self->throw('parse', 'Missing variable on LOOP directive', undef, pos($$str_ref));
}

sub parse_MACRO {
    my ($self, $str_ref, $node) = @_;

    my $name = $self->parse_expr($str_ref, {auto_quote => "(\\w+\\b) (?! \\.)"});
    $self->throw('parse', "Missing macro name", undef, pos($$str_ref)) if ! defined $name;
    if (! ref $name) {
        $name = [ $name, 0 ];
    }

    my $args;
    if ($$str_ref =~ m{ \G \( \s* }gcx) {
        $args = $self->parse_args($str_ref, {positional_only => 1});
        $$str_ref =~ m{ \G \) \s* }gcx || $self->throw('parse.missing', "Missing close ')'", undef, pos($$str_ref));
    } elsif ($self->{'V1DOLLAR'}) { # allow for Velocity style macro args (no parens - but dollars are fine)
        while ($$str_ref =~ m{ \G (\s+ \$) }gcx) {
            my $lead = $1;
            my $arg  = $self->parse_expr($str_ref);
            if (! defined $arg) {
                pos($$str_ref) -= length($lead);
                last;
            }
            push @$args, $arg;
        }
    }

    $node->[6] = 1;           # set a flag to keep parsing
    return [$name, $args];
}

sub parse_META {
    my ($self, $str_ref) = @_;
    my $args = $self->parse_args($str_ref, {named_at_front => 1});
    my $hash;
    return $hash if ($hash = $self->play_expr($args->[0])) && UNIVERSAL::isa($hash, 'HASH');
    return undef;
}

sub parse_PROCESS {
    my ($self, $str_ref) = @_;

    return $self->parse_args($str_ref, {
        named_at_front       => 1,
        allow_bare_filenames => 1,
        require_arg          => 1,
    });
}

sub parse_RETURN {
    my ($self, $str_ref) = @_;
    my $ref = $self->parse_expr($str_ref); # optional return value
    return $ref;
}

sub parse_SET {
    my ($self, $str_ref, $node, $initial_op, $initial_var) = @_;
    my @SET;
    my $func;

    if ($initial_op) {
        if ($initial_op eq '='
            && $$str_ref =~ m{ \G \s* $QR_COMMENTS $QR_DIRECTIVE }gcx # find a word
            && ((pos($$str_ref) -= length($1)) || 1)             # always revert
            && $DIRECTIVES->{$self->{'ANYCASE'} ? uc $1 : $1}) { # make sure its a directive - if so set up capturing
            $node->[6] = 1;                                      # set a flag to keep parsing
            my $val = $node->[4] ||= [];                         # setup storage
            return [[$initial_op, $initial_var, $val]];
        } else { # get a normal variable
            my $val = $self->parse_expr($str_ref);
            if ($initial_op =~ /(.+)=$/) {
                $initial_op = '=';
                $val = [[undef, $1, $initial_var, $val], 0];
            }
            return [[$initial_op, $initial_var, $val]];
        }
    }

    while (1) {
        my $set = $self->parse_expr($str_ref);
        last if ! defined $set;

        if ($$str_ref =~ m{ \G \s* $QR_COMMENTS ($QR_OP_ASSIGN) >? }gcx) {
            my $op = $1;
            if ($op eq '='
                && $$str_ref =~ m{ \G \s* $QR_COMMENTS $QR_DIRECTIVE }gcx # find a word
                && ((pos($$str_ref) -= length($1)) || 1)             # always revert
                && $DIRECTIVES->{$self->{'ANYCASE'} ? uc $1 : $1}) { # make sure its a directive - if so set up capturing
                $node->[6] = 1;                                      # set a flag to keep parsing
                my $val = $node->[4] ||= [];                         # setup storage
                if ($op =~ /(.+)=$/) {
                    $op = '=';
                    $val = [[undef, $1, $set, $val], 0];
                }
                push @SET, [$op, $set, $val];
                last;
            } else { # get a normal variable
                push @SET, [$op, $set, $self->parse_expr($str_ref)];
            }
        } else {
            push @SET, ['=', $set, undef];
        }
    }

    return \@SET;
}

sub parse_SWITCH { $DIRECTIVES->{'GET'}->[0]->(@_) }

sub parse_TAGS {
    my ($self, $str_ref, $node) = @_;

    my ($start, $end);
    if ($$str_ref =~ m{ \G (\w+) }gcxs) {
        my $ref = $TAGS->{lc $1} || $self->throw('parse', "Invalid TAGS name \"$1\"", undef, pos($$str_ref));
        ($start, $end) = @$ref;

    } else {
        local $self->{'_operator_precedence'} = 1; # prevent operator matching
        $start = $$str_ref =~ m{ \G (?= \s* $QR_COMMENTS [\'\"\/]) }gcx
            ? $self->parse_expr($str_ref)
            : $self->parse_expr($str_ref, {auto_quote => "(\\S+) \\s+ $QR_COMMENTS"})
            || $self->throw('parse', "Invalid opening tag in TAGS", undef, pos($$str_ref));
        $end   = $$str_ref =~ m{ \G (?= \s* $QR_COMMENTS [\'\"\/]) }gcx
            ? $self->parse_expr($str_ref)
            : $self->parse_expr($str_ref, {auto_quote => "(\\S+) \\s* $QR_COMMENTS"})
            || $self->throw('parse', "Invalid closing tag in TAGS", undef, pos($$str_ref));
        for my $tag ($start, $end) {
            $tag = $self->play_expr($tag);
            $tag = quotemeta($tag) if ! ref $tag;
        }
    }
    return [$start, $end];
}

sub parse_THROW {
    my ($self, $str_ref, $node) = @_;
    my $name = $self->parse_expr($str_ref, {auto_quote => "(\\w+\\b (?: \\.\\w+\\b)*) $QR_AQ_SPACE \\s* $QR_COMMENTS"});
    $self->throw('parse.missing', "Missing name in THROW", $node, pos($$str_ref)) if ! $name;
    my $args = $self->parse_args($str_ref, {named_at_front => 1});
    return [$name, $args];
}

sub parse_UNLESS {
    my $ref = $DIRECTIVES->{'IF'}->[0]->(@_);
    return [[undef, '!', $ref], 0];
}

sub parse_USE {
    my ($self, $str_ref) = @_;

    my $var;
    my $mark = pos $$str_ref;
    if (defined(my $_var = $self->parse_expr($str_ref, {auto_quote => "(\\w+\\b) (?! \\.) \\s* $QR_COMMENTS"}))
        && ($$str_ref =~ m{ \G = >? \s* $QR_COMMENTS }gcxo # make sure there is assignment
            || ((pos($$str_ref) = $mark) && 0))               # otherwise we need to rollback
        ) {
        $var = $_var;
    }

    my $module = $self->parse_expr($str_ref, {auto_quote => "(\\w+\\b (?: (?:\\.|::) \\w+\\b)*) (?! \\.) \\s* $QR_COMMENTS"});
    $self->throw('parse', "Missing plugin name while parsing $$str_ref", undef, pos($$str_ref)) if ! defined $module;
    $module =~ s/\./::/g;

    my $args;
    my $open = $$str_ref =~ m{ \G \( \s* $QR_COMMENTS }gcxo;
    $args = $self->parse_args($str_ref, {is_parened => $open, named_at_front => 1});

    if ($open) {
        $$str_ref =~ m{ \G \) \s* $QR_COMMENTS }gcxo || $self->throw('parse.missing', "Missing close ')'", undef, pos($$str_ref));
    }

    return [$var, $module, $args];
}

sub parse_VIEW {
    my ($self, $str_ref) = @_;

    my $ref = $self->parse_args($str_ref, {
        named_at_front       => 1,
        require_arg          => 1,
    });

    return $ref;
}

sub parse_WHILE { $DIRECTIVES->{'IF'}->[0]->(@_) }

sub parse_WRAPPER { $DIRECTIVES->{'PROCESS'}->[0]->(@_) }

###----------------------------------------------------------------###

sub dump_parse_tree {
    my $self = shift;
    $self = $self->new if ! ref $self;
    my $str = shift;
    my $ref = ref($str) ? $str : \$str;
    my $sub;
    my $nest;
    $sub = sub {
        my ($tree, $indent) = @_;
        my $out = "[\n";
        foreach my $node (@$tree) {
            if (! ref($node) || (! $node->[4] && ! $node->[5])) {
                $out .= "$indent    ".$self->ast_string($node).",\n";
                next;
            }
            $out .= "$indent    " . $nest->($node, "$indent    ");
        }
        $out .= "$indent]";
    };
    $nest = sub {
        my ($node, $indent) = @_;
        my $out = $self->ast_string([@{$node}[0..3]]);
        chop $out;
        if ($node->[4]) {
            $out .= ", ";
            $out .= $sub->($node->[4], "$indent");
        }
        if ($node->[5]) {
            $out .= ", ". $nest->($node->[5], "$indent") . $indent;
        } elsif (@$node >= 6) {
            $out .= ", ". $self->ast_string($node->[5]);
        }
        if (@$node >= 7) { $out.= ", ". $self->ast_string($node->[6]) };
        $out .= "],\n";
        return $out;
    };

    return $sub->($self->parse_tree($ref), '') ."\n";
}

sub dump_parse_expr {
    my $self = shift;
    $self = $self->new if ! ref $self;
    my $str = shift;
    my $ref = ref($str) ? $str : \$str;
    return $self->ast_string($self->parse_expr($ref));
}

###----------------------------------------------------------------###

1;

__END__

=head1 DESCRIPTION

The Template::Alloy::Parse role is reponsible for storing the majority
of directive parsing code, as well as for delegating to the TT, HTE,
Tmpl, and Velocity roles for finding variables and directives.

=head1 ROLE METHODS

=over 4

=item parse_tree

Used by load_tree.  This is the main grammar engine of the program.  It
delegates to the syntax found in $self->{'SYNTAX'} (defaults to 'alloy')
and calls the function found in the $SYNTAX hashref.  The majority
of these syntaxes use methods found in the $DIRECTIVES hashref
to parse different DIRECTIVE types for each particular syntax.

A template that looked like the following:

    Foo
    [%- GET foo -%]
    [%- GET bar -%]
    Bar

would parse to the following AST:

    [
        'Foo',
        ['GET', 6, 15, ['foo', 0]],
        ['GET', 22, 31, ['bar', 0]],
        'Bar',
    ]

The "GET" words represent the directive used.  The 6, 15 represent the
beginning and ending characters of the directive in the document.  The
remaining items are the variables necessary for running the particular
directive.

=item parse_expr

Used to parse a variable, an expression, a literal string, or a
number.  It returns a parsed variable tree.  Samples of parsed
variables can be found in the VARIABLE PARSE TREE section.

    my $str = "1 + 2 * 3";
    my $ast = $self->parse_expr(\$str);
    # $ast looks like [[undef, '+', 1, [[undef, '*', 2, 3], 0]], 0]

=item C<parse_args>

Allow for the multitudinous ways that TT parses arguments.  This
allows for positional as well as named arguments.  Named arguments can
be separated with a "=" or "=>", and positional arguments should be
separated by " " or ",".  This only returns an array of parsed
variables.  To get the actual values, you must call play_expr on each
value.

=item C<dump_parse_tree>

This method allows for returning a string of perl code representing
the AST of the parsed tree.

It is mainly used for testing.

=item C<dump_parse_expr>

This method allows for returning a Data::Dumper dump of a parsed
variable.  It is mainly used for testing.

=item C<parse_*>

Methods by these names are used by parse_tree to parse the template.
These are the grammar.  They are used by all of the various template
syntaxes Unless otherwise mentioned, these methods are not exposed via
the role.

=back

=head1 VARIABLE PARSE TREE

Template::Alloy parses templates into an tree of operations (an AST
or abstract syntax tree).  Even variable access is parsed into a tree.
This is done in a manner somewhat similar to the way that TT operates
except that nested variables such as foo.bar|baz contain the '.' or
'|' in between each name level.  Operators are parsed and stored as
part of the variable (it may be more appropriate to say we are parsing
a term or an expression).

The following table shows a variable or expression and the corresponding parsed tree
(this is what the parse_expr method would return).

    one                [ 'one',  0 ]
    one()              [ 'one',  [] ]
    one.two            [ 'one',  0, '.', 'two',  0 ]
    one|two            [ 'one',  0, '|', 'two',  0 ]
    one.$two           [ 'one',  0, '.', ['two', 0 ], 0 ]
    one(two)           [ 'one',  [ ['two', 0] ] ]
    one.${two().three} [ 'one',  0, '.', ['two', [], '.', 'three', 0], 0]
    2.34               2.34
    "one"              "one"
    1 + 2              [ [ undef, '+', 1, 2 ], 0]
    a + b              [ [ undef, '+', ['a', 0], ['b', 0] ], 0 ]
    "one"|length       [ [ undef, '~', "one" ], 0, '|', 'length', 0 ]
    "one $a two"       [ [ undef, '~', 'one ', ['a', 0], ' two' ], 0 ]
    [0, 1, 2]          [ [ undef, '[]', 0, 1, 2 ], 0 ]
    [0, 1, 2].size     [ [ undef, '[]', 0, 1, 2 ], 0, '.', 'size', 0 ]
    ['a', a, $a ]      [ [ undef, '[]', 'a', ['a', 0], [['a', 0], 0] ], 0]
    {a  => 'b'}        [ [ undef, '{}', 'a', 'b' ], 0 ]
    {a  => 'b'}.size   [ [ undef, '{}', 'a', 'b' ], 0, '.', 'size', 0 ]
    {$a => b}          [ [ undef, '{}', ['a', 0], ['b', 0] ], 0 ]
    a * (b + c)        [ [ undef, '*', ['a', 0], [ [undef, '+', ['b', 0], ['c', 0]], 0 ]], 0 ]
    (a + b)            [ [ undef, '+', ['a', 0], ['b', 0] ]], 0 ]
    (a + b) * c        [ [ undef, '*', [ [undef, '+', ['a', 0], ['b', 0] ], 0 ], ['c', 0] ], 0 ]
    a ? b : c          [ [ undef, '?', ['a', 0], ['b', 0], ['c', 0] ], 0 ]
    a || b || c        [ [ undef, '||', ['a', 0], [ [undef, '||', ['b', 0], ['c', 0] ], 0 ] ], 0 ]
    ! a                [ [ undef, '!', ['a', 0] ], 0 ]

Some notes on the parsing.

    Operators are parsed as part of the variable and become part of the variable tree.

    Operators are stored in the variable tree using an operator identity array which
    contains undef as the first value, the operator, and the operator arguments.  This
    allows for quickly descending the parsed variable tree and determining that the next
    node is an operator.

    Parenthesis () can be used at any point in an expression to disambiguate precedence.

    "Variables" that appear to be literal strings or literal numbers
    are returned as the literal (no operator tree).

The following perl can be typed at the command line to view the parsed variable tree:

    perl -e 'use Template::Alloy; print Template::Alloy->dump_parse_expr("foo.bar + 2")."\n"'

Also the following can be included in a template to view the output in a template:

    [% USE cet = Template::Alloy %]
    [%~ cet.dump_parse_expr('foo.bar + 2').replace('\s+', ' ') %]

=head1 AUTHOR

Paul Seamons <paul at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
