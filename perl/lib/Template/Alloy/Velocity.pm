package Template::Alloy::Velocity;

=head1 NAME

Template::Alloy::Velocity - Velocity (VTL) role

=cut

use strict;
use warnings;
use Template::Alloy;

our $VERSION = $Template::Alloy::VERSION;

sub new { die "This class is a role for use by packages such as Template::Alloy" }

###----------------------------------------------------------------###

sub parse_tree_velocity {
    my $self    = shift;
    my $str_ref = shift;
    if (! $str_ref || ! defined $$str_ref) {
        $self->throw('parse.no_string', "No string or undefined during parse", undef, 1);
    }

    local $self->{'V2EQUALS'}    = $self->{'V2EQUALS'} || 0;
    local $self->{'INTERPOLATE'} = defined($self->{'INTERPOLATE'}) ? $self->{'INTERPOLATE'} : 1;
    local $self->{'V1DOLLAR'}    = defined($self->{'V1DOLLAR'})    ? $self->{'V1DOLLAR'}    : 1;
    local $self->{'ANYCASE'}     = defined($self->{'ANYCASE'})     ? $self->{'ANYCASE'}     : 1;
    local $self->{'AUTO_EVAL'}   = defined($self->{'AUTO_EVAL'})   ? $self->{'AUTO_EVAL'}   : 1;
    local $self->{'SHOW_UNDEFINED_INTERP'} = defined($self->{'SHOW_UNDEFINED_INTERP'}) ? $self->{'SHOW_UNDEFINED_INTERP'} : 1;

    local $self->{'START_TAG'}  = qr{\#};
    local $self->{'_start_tag'} = (! $self->{'INTERPOLATE'}) ? $self->{'START_TAG'} : qr{(?: $self->{'START_TAG'} | (\$))}sx;
    local $self->{'_end_tag'}; # changes over time

    local @{ $Template::Alloy::Parse::ALIASES }{qw(PARSE   INCLUDE _INCLUDE ELSEIF)}
                                                = qw(PROCESS INSERT  INCLUDE  ELSIF);
    my $dirs    = $Template::Alloy::Parse::DIRECTIVES;
    my $aliases = $Template::Alloy::Parse::ALIASES;
    local @{ $dirs }{ keys %$aliases } = values %$aliases; # temporarily add to the table
    local @{ $self }{@Template::Alloy::CONFIG_COMPILETIME} = @{ $self }{@Template::Alloy::CONFIG_COMPILETIME};

    my @tree;             # the parsed tree
    my $pointer = \@tree; # pointer to current tree to handle nested blocks
    my @state;            # maintain block levels
    local $self->{'_state'} = \@state; # allow for items to introspect (usually BLOCKS)
    local $self->{'_no_interp'} = 0;   # no interpolation in perl
    my @in_view;          # let us know if we are in a view
    my @blocks;           # storage for defined blocks
    my @meta;             # place to store any found meta information (to go into META)
    my $post_chomp = 0;   # previous post_chomp setting
    my $continue   = 0;   # flag for multiple directives in the same tag
    my $post_op    = 0;   # found a post-operative DIRECTIVE
    my $capture;          # flag to start capture
    my $func;
    my $pre_chomp;
    my $node;
    my $macro_block;
    pos($$str_ref) = 0;

    while (1) {
        ### allow for #set(foo = PROCESS foo)
        if ($capture) {
            if ($macro_block) {
                $macro_block = 0;
                push @state, $capture;
                $pointer = $capture->[4] ||= [];
                undef $capture;
                next;
            } elsif ($$str_ref =~ m{ \G \s* (\w+)\b }gcx) {
                $func = $self->{'ANYCASE'} ? uc($1) : $1;
                $func = $aliases->{$func} if $aliases->{$func};
                $self->throw('parse', "Found unknown DIRECTIVE ($func)", undef, pos($$str_ref) - length($func))
                    if ! $dirs->{$func};
                $node = [$func, pos($$str_ref) - length($func), undef];
            } else {
                $self->throw('parse', "Error looking for block in capture DIRECTIVE", undef, pos($$str_ref));
            }

            push @{ $capture->[4] }, $node;
            undef $capture;

        ### handle all other
        } else {
            ### find the next opening tag
            $$str_ref =~ m{ \G (.*?) $self->{'_start_tag'} }gcxs
                || last;
            my ($text, $dollar) = ($1, $2);

            ### found a text portion - chomp it and store it
            if (length $text) {
                if (! $post_chomp) { }
                elsif ($post_chomp == 1) { $text =~ s{ ^ [^\S\n]* \n }{}x  }
                elsif ($post_chomp == 2) { $text =~ s{ ^ \s+         }{ }x }
                elsif ($post_chomp == 3) { $text =~ s{ ^ \s+         }{}x  }
                push @$pointer, $text if length $text;
            }

            ### handle variable interpolation ($2 eq $)
            if ($dollar) {
                ### inspect previous text chunk for escape slashes
                my $n = ($text =~ m{ (\\+) $ }x) ? length($1) : 0;
                if ($n && ! $self->{'_no_interp'}) {
                    my $chop = int(($n + 1) / 2); # were there odd escapes
                    substr($pointer->[-1], -$chop, $chop, '') if defined($pointer->[-1]) && ! ref($pointer->[-1]);
                }
                if ($self->{'_no_interp'} || $n % 2) {
                    push @$pointer, $dollar;
                    next;
                }

                my $not  = $$str_ref =~ m{ \G ! }gcx;
                my $mark = pos($$str_ref);
                my $ref;
                if ($$str_ref =~ m{ \G \{ }gcx) {
                    local $self->{'_operator_precedence'} = 0; # allow operators
                    local $self->{'_end_tag'} = qr{\}};
                    $ref = $self->parse_expr($str_ref);
                    $$str_ref =~ m{ \G \s* $Template::Alloy::Parse::QR_COMMENTS \} }gcxo
                        || $self->throw('parse', 'Missing close }', undef, pos($$str_ref));
                } else {
                    local $self->{'_operator_precedence'} = 1; # no operators
                    local $Template::Alloy::Parse::QR_COMMENTS = qr{};
                    $ref = $self->parse_expr($str_ref);
                }
                $self->throw('parse', "Error while parsing for interpolated string", undef, pos($$str_ref))
                    if ! defined $ref;
                if (! $not && $self->{'SHOW_UNDEFINED_INTERP'}) {
                    $ref = [[undef, '//', $ref, '$'.substr($$str_ref, $mark, pos($$str_ref)-$mark)], 0];
                }
                push @$pointer, ['GET', $mark, pos($$str_ref), $ref];
                $post_chomp = 0; # no chomping after dollar vars
                next;
            }

            ### allow for escaped #
            my $n = ($text =~ m{ (\\+) $ }x) ? length($1) : 0;
            if ($n) {
                my $chop = int(($n + 1) / 2); # were there odd escapes
                substr($pointer->[-1], -$chop, $chop, '') if defined($pointer->[-1]) && ! ref($pointer->[-1]);
                if ($n % 2) {
                    push @$pointer, '#';
                    next;
                }
            }
            if ($$str_ref =~ m{ \G \# .*\n? }gcx          # single line comment
                || $$str_ref =~ m{ \G \* .*? \*\# }gcxs) { # multi-line comment
                next;
            }

            $$str_ref =~ m{ \G (\w+) }gcx
                || $$str_ref =~ m{ \G \{ (\w+) (\}) }gcx
                || $self->throw('parse', 'Missing directive name', undef, pos($$str_ref));
            $func = $self->{'ANYCASE'} ? uc($1) : $1;

            ### make sure we know this directive - if we don't then allow fallback to macros (velocity allows them as directives)
            $func = $aliases->{$func} if $aliases->{$func};
            if (! $dirs->{$func}) {
                my $name = $1;
                my $mark = pos($$str_ref) - length($func) - ($2 ? 2 : 0);
                my $args = 0;
                if ($$str_ref =~ m{ \G \( }gcx) {
                    local $self->{'_operator_precedence'} = 0; # reset precedence
                    $args = $self->parse_args($str_ref, {is_parened => 1});
                    $$str_ref =~ m{ \G \s* $Template::Alloy::Parse::QR_COMMENTS \) }gcxo
                        || $self->throw('parse.missing.paren', "Missing close \) in directive args", undef, pos($$str_ref));
                }
                $node = ['GET', $mark, pos($$str_ref), [$name, $args]];
                push @$pointer, $node;
                next;
                #$self->throw('parse', "Found unknow DIRECTIVE ($func)", undef, pos($$str_ref) - length($func));
            }
            $node = [$func, pos($$str_ref), undef];

            if ($$str_ref =~ m{ \G \( ([+=~-]?) }gcx) {
                $self->{'_end_tag'} = qr{\s*([+=~-]?)\)};
                $pre_chomp = $1;
            } else {
                $self->{'_end_tag'} = '';
                $pre_chomp = '';
            }

            ### take care of chomping (this is an extention to velocity
            $pre_chomp ||= $self->{'PRE_CHOMP'};
            $pre_chomp  =~ y/-=~+/1230/ if $pre_chomp;
            if ($pre_chomp && $pointer->[-1] && ! ref $pointer->[-1]) {
                if    ($pre_chomp == 1) { $pointer->[-1] =~ s{ (?:\n|^) [^\S\n]* \z }{}x  }
                elsif ($pre_chomp == 2) { $pointer->[-1] =~ s{             (\s+) \z }{ }x }
                elsif ($pre_chomp == 3) { $pointer->[-1] =~ s{             (\s+) \z }{}x  }
                splice(@$pointer, -1, 1, ()) if ! length $pointer->[-1]; # remove the node if it is zero length
            }

            push @$pointer, $node;
        }

        $$str_ref =~ m{ \G \s+ }gcx;

        ### parse remaining tag details
        if ($func ne 'END') {
            $node->[3] = eval { $dirs->{$func}->[0]->($self, $str_ref, $node) };
            if (my $err = $@) {
                $err->node($node) if UNIVERSAL::can($err, 'node') && ! $err->node;
                die $err;
            }
            $node->[2] = pos $$str_ref;
        }

        ### handle ending tags - or continuation blocks
        if ($func eq 'END' || $dirs->{$func}->[4]) {
            if (! @state) {
                print Data::Dumper::Dumper(\@tree);
                $self->throw('parse', "Found an $func tag while not in a block", $node, pos($$str_ref));
            }
            my $parent_node = pop @state;

            ### handle continuation blocks such as elsif, else, catch etc
            if ($dirs->{$func}->[4]) {
                pop @$pointer; # we will store the node in the parent instead
                $parent_node->[5] = $node;
                my $parent_type = $parent_node->[0];
                if (! $dirs->{$func}->[4]->{$parent_type}) {
                    $self->throw('parse', "Found unmatched nested block", $node, pos($$str_ref));
                }
            }

            ### restore the pointer up one level (because we hit the end of a block)
            $pointer = (! @state) ? \@tree : $state[-1]->[4];

            ### normal end block
            if (! $dirs->{$func}->[4]) {
                if ($parent_node->[0] eq 'BLOCK') { # move BLOCKS to front
                    if (defined($parent_node->[3]) && @in_view) {
                        push @{ $in_view[-1] }, $parent_node;
                    } else {
                        push @blocks, $parent_node;
                    }
                    if ($pointer->[-1] && ! $pointer->[-1]->[6]) { # capturing doesn't remove the var
                        splice(@$pointer, -1, 1, ());
                    }
                } elsif ($parent_node->[0] eq 'VIEW') {
                    my $ref = { map {($_->[3] => $_->[4])} @{ pop @in_view }};
                    unshift @{ $parent_node->[3] }, $ref;
                } elsif ($dirs->{$parent_node->[0]}->[5]) { # allow no_interp to turn on and off
                    $self->{'_no_interp'}--;
                }


            ### continuation block - such as an elsif
            } else {
                push @state, $node;
                $pointer = $node->[4] ||= [];
            }
            $node->[2] = pos $$str_ref;

        ### handle block directives
        } elsif ($dirs->{$func}->[2]) {
            push @state, $node;
            $pointer = $node->[4] ||= []; # allow future parsed nodes before END tag to end up in current node
            push @in_view, [] if $func eq 'VIEW';
            $self->{'_no_interp'}++ if $dirs->{$node->[0]}->[5] # allow no_interp to turn on and off

        } elsif ($func eq 'META') {
            unshift @meta, %{ $node->[3] }; # first defined win
            $node->[3] = undef;             # only let these be defined once - at the front of the tree
        }


        ### look for the closing tag
        if ($$str_ref =~ m{ \G $self->{'_end_tag'} }gcxs) {
            $post_chomp = $1 || $self->{'POST_CHOMP'};
            $post_chomp =~ y/-=~+/1230/ if $post_chomp;
            $continue = 0;
            $post_op  = 0;

            if ($node->[6] && $node->[0] eq 'MACRO') { # allow for MACRO's without a BLOCK
                $capture = $node;
                $macro_block = 1;
            }
            next;

        ### setup capturing
        } elsif ($node->[6]) {
            $capture = $node;
            next;

        ### no closing tag
        } else {
            $self->throw('parse', "Not sure how to handle tag", $node, pos($$str_ref));
        }
    }

    ### cleanup the tree
    unshift(@tree, @blocks) if @blocks;
    unshift(@tree, ['META', 1, 1, {@meta}]) if @meta;
    $self->throw('parse', "Missing end tag", $state[-1], pos($$str_ref)) if @state > 0;

    ### pull off the last text portion - if any
    if (pos($$str_ref) != length($$str_ref)) {
        my $text  = substr $$str_ref, pos($$str_ref);
        if (! $post_chomp) { }
        elsif ($post_chomp == 1) { $text =~ s{ ^ [^\S\n]* \n }{}x  }
        elsif ($post_chomp == 2) { $text =~ s{ ^ \s+         }{ }x }
        elsif ($post_chomp == 3) { $text =~ s{ ^ \s+         }{}x  }
        push @$pointer, $text if length $text;
    }

    return \@tree;
}

sub merge {
    my ($self, $in, $swap, $out) = @_;
    local $self->{'SYNTAX'} = $self->{'SYNTAX'} || 'velocity';
    return $self->process_simple($in, $swap, $out);
}

###----------------------------------------------------------------###

1;

__END__

=head1 DESCRIPTION

The Template::Alloy::Velocity role provides the syntax and the
interface for the Velocity Templating Language (VTL).  It also brings
many of the features from the various templating systems.

See the Template::Alloy documentation for configuration and other parameters.

The following documents have more information about the velocity language.

    http://velocity.apache.org/engine/devel/vtl-reference-guide.html
    http://www.javaworld.com/javaworld/jw-12-2001/jw-1228-velocity.html?page=4

=head1 TODO

Add language usage and samples.

=head1 ROLE METHODS

=over 4

=item C<parse_tree_velocity>

Used bh the parse_tree method when SYNTAX is set to 'velocity'.

=item C<merge>

Similar to process_simple, but with syntax set to velocity.

=back

=head1 UNSUPPORTED VELOCITY SPEC

=over 4

=item

The magic Java Velocity property lookups don't exist.  You must use
the actual method name, Alloy will not try to guess it for you.  Java
Velocity allows you to type $object.Attribute and Java Velocity will
look for the Attribute, getAttribute, getattribute, isAttribute
methods.  In Perl Alloy, you can call $object.can('Attribute') to
introspect the object.

=item

Escaping of variables is consistent.  The Java Velocity spec is not.
The velocity spec says that "\\$email" will return "\\$email" if email
is not defined and it will return "\foo" if email is equal to "foo".
The slash behavior magically changes according to the spec.  In Alloy
the "\\$email" would be "\$email" if email is not defined.

=item

You can set items to null (undefined) in Alloy.  According to the Java
Velocity reference-guide you have to configure Velocity to do this.
To get the other behavior, you would need to do
"#if($questionable)#set($foo=$questionable)#end".  The default
Velocity spec way provides no way for checking null return values.

=item

There currently isn't a "literal" directive.  The VTL reference-guide
doesn't mention #literal, but the user-guide does.  In Alloy you can
use the following:

    #get('#foreach($a in [1..3]) $a #end')

We will probably add the literal support - but it will still have to parse the
document, so unless you are using compile_perl, you will parse literal sections
multiple times.

=item

There is no "$velocityCount" .  Use "$loop.count" .

=item

In Alloy, excess whitespace outside of the directive matters.  In the
VTL user-guide it mentions that all excess whitespace is gobbled up.
Alloy supports the TT chomp operators.  These operators are placed
just inside the open and close parenthesis of directives as in the
following:

     #set(~ $a = 1 ~)

=item

In Alloy, division using "/" is always floating point.  If you want integer
division, use "div".  In Java Velocity, "/" division is integer only if
both numbers are integers.

=item

Perl doesn't support negative ranges.  However, arrays do have the reverse method.

     #foreach( $bar in [-2 .. 2].reverse ) $bar #end

=item

In Alloy arguments to macros are passed by value, not by name.  This
is easy to achieve with alloy - simply encase your arguments in single
quotes and then eval the argument inside the macro.  The velocity
people claim this feature as a jealously guarded feature.  My first
template system "WrapEx" had the same feature.  It happened as an
accident.  It represents lazy software architecture and is difficult to
optimize.

=back

=head1 AUTHOR

Paul Seamons <paul at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
