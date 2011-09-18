package Template::Alloy::HTE;

=head1 NAME

Template::Alloy::HTE - HTML::Template and HTML::Template::Expr roles.

=cut

use strict;
use warnings;
use Template::Alloy;

our $VERSION = $Template::Alloy::VERSION;

sub new { die "This class is a role for use by packages such as Template::Alloy" }

###----------------------------------------------------------------###
### support for few HTML::Template and HTML::Template::Expr calling syntax

sub register_function {
    my ($name, $sub) = @_;
    $Template::Alloy::SCALAR_OPS->{$name} = $sub;
}

sub clear_param { shift->{'_vars'} = {} }

sub query { shift->throw('query', "Not implemented in Template::Alloy") }

sub new_file       { my $class = shift; my $in = shift; $class->new(source => $in, type => 'filename',   @_) }
sub new_scalar_ref { my $class = shift; my $in = shift; $class->new(source => $in, type => 'scalarref',  @_) }
sub new_array_ref  { my $class = shift; my $in = shift; $class->new(source => $in, type => 'arrayref',   @_) }
sub new_filehandle { my $class = shift; my $in = shift; $class->new(source => $in, type => 'filehandle', @_) }

###----------------------------------------------------------------###

sub parse_tree_hte {
    my $self    = shift;
    my $str_ref = shift;
    if (! $str_ref || ! defined $$str_ref) {
        $self->throw('parse.no_string', "No string or undefined during parse", undef, 1);
    }

    local $self->{'V2EQUALS'}   = $self->{'V2EQUALS'} || 0;
    local $self->{'NO_TT'}      = $self->{'NO_TT'} || ($self->{'SYNTAX'} eq 'hte' ? 0 : 1);

    local $self->{'START_TAG'}  = qr{<(|!--\s*)(/?)([+=~-]?)[Tt][Mm][Pp][Ll]_(\w+)\b};
    local $self->{'_start_tag'} = (! $self->{'INTERPOLATE'}) ? $self->{'START_TAG'} : qr{(?: $self->{'START_TAG'} | (\$))}sx;
    local $self->{'_end_tag'}; # changes over time

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
    my ($comment, $is_close);
    pos($$str_ref) = 0;
    my $allow_expr = ! defined($self->{'EXPR'}) || $self->{'EXPR'}; # default is on

    while (1) {
        ### allow for TMPL_SET foo = PROCESS foo
        if ($capture) {
            $func = $$str_ref =~ m{ \G \s* (\w+)\b }gcx
                ? uc $1 : $self->throw('parse', "Error looking for block in capture DIRECTIVE", undef, pos($$str_ref));
            $func = $aliases->{$func} if $aliases->{$func};
            if ($func ne 'VAR' && ! $dirs->{$func}) {
                $self->throw('parse', "Found unknown DIRECTIVE ($func)", undef, pos($$str_ref) - length($func));
            }

            $node = [$func, pos($$str_ref) - length($func), undef];

            push @{ $capture->[4] }, $node;
            undef $capture;

        ### handle all other TMPL tags
        } else {
            ### find the next opening tag
            $$str_ref =~ m{ \G (.*?) $self->{'_start_tag'} }gcxs
                || last;
            my ($text, $dollar) = ($1, $6);
            ($comment, $is_close, $pre_chomp, $func) = ($2, $3, $4, uc $5) if ! $dollar;

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

            ### make sure we know this directive
            $func = $aliases->{$func} if $aliases->{$func};
            if ($func ne 'VAR' && ! $dirs->{$func}) {
                $self->throw('parse', "Found unknow DIRECTIVE ($func)", undef, pos($$str_ref) - length($func));
            }
            $node = [$func, pos($$str_ref) - length($func) - length($pre_chomp) - 5, undef];

            ### take care of chomping - yes HT now get CHOMP SUPPORT
            $pre_chomp ||= $self->{'PRE_CHOMP'};
            $pre_chomp  =~ y/-=~+/1230/ if $pre_chomp;
            if ($pre_chomp && $pointer->[-1] && ! ref $pointer->[-1]) {
                if    ($pre_chomp == 1) { $pointer->[-1] =~ s{ (?:\n|^) [^\S\n]* \z }{}x  }
                elsif ($pre_chomp == 2) { $pointer->[-1] =~ s{             (\s+) \z }{ }x }
                elsif ($pre_chomp == 3) { $pointer->[-1] =~ s{             (\s+) \z }{}x  }
                splice(@$pointer, -1, 1, ()) if ! length $pointer->[-1]; # remove the node if it is zero length
            }

            push @$pointer, $node;
            $self->{'_end_tag'} = $comment ? qr{([+=~-]?)-->} : qr{([+=~-]?)>}; # how will this tag end
        }

        $$str_ref =~ m{ \G \s+ }gcx;

        ### parse remaining tag details
        if (! $is_close) {
            ### handle HT style nodes
            if ($func =~ /^(IF|ELSIF|ELSE|UNLESS|LOOP|VAR|INCLUDE)$/) {
                $func = $node->[0] = 'GET' if $func eq 'VAR';

                ### handle EXPR attribute
                if ($func eq 'ELSE') {
                    # do nothing
                } elsif ($$str_ref =~ m{ \G [Ee][Xx][Pp][Rr] \s*=\s* ([\"\']?) \s* }gcx) {
                    if (! $allow_expr) {
                        $self->throw('parse', 'EXPR are not allowed without hte mode', undef, pos($$str_ref));
                    }
                    my $quote = $1;
                    local $self->{'_end_tag'} = $quote ? qr{$quote\s*$self->{'_end_tag'}} : $self->{'_end_tag'};
                    $node->[3] = eval { $self->parse_expr($str_ref) };
                    if (! defined($node->[3])) {
                        my $err = $@ || $self->exception('parse', 'Error while looking for EXPR', undef, pos($$str_ref));
                        $err->info($err->info . " (Could be a missing close quote near expr=$quote)") if $quote && UNIVERSAL::can($err, 'info');
                        $self->throw($err);
                    }
                    if ($quote) {
                        $$str_ref =~ m{ \G $quote }gcx
                            || $self->throw('parse', "Missing close quote ($quote)", undef, pos($$str_ref));
                    }
                    if ($func eq 'INCLUDE') {
                        $node->[0] = 'PROCESS'; # no need to localize the stash
                        $node->[3] = [[[undef, '{}'],0], $node->[3]];
                    } elsif ($func eq 'UNLESS') {
                        $node->[0] = 'IF';
                        $node->[3] = [[undef, '!', $node->[3]], 0];
                    }
                    if ($self->{'AUTO_FILTER'}) {
                        $node->[3] = [[undef, '~', $node->[3]], 0] if ! ref $node->[3];
                        push @{ $node->[3] }, '|', $self->{'AUTO_FILTER'}, 0 if @{ $node->[3] } < 3 || $node->[3]->[-3] ne '|';
                    }

                ### handle "normal" NAME attributes
                } else {

                    my ($name, $escape, $default);
                    while (1) {
                        if ($$str_ref =~ m{ \G (\w+) \s*=\s* }gcx) {
                            my $key = lc $1;
                            my $val = $$str_ref =~ m{ \G ([\"\']) (.*?) (?<!\\) \1 \s* }gcx ? $2
                                    : $$str_ref =~ m{ \G ([\w./+_]+) \s* }gcx               ? $1
                                    : $self->throw('parse', "Error while looking for value of \"$key\" attribute", undef, pos($$str_ref));
                            if ($key eq 'name') {
                                $name ||= $val;
                            } else {
                                $self->throw('parse', uc($key)." not allowed in TMPL_$func tag", undef, pos($$str_ref)) if $func ne 'GET';
                                if    ($key eq 'escape')  { $escape  ||= lc $val }
                                elsif ($key eq 'default') { $default ||= $val    }
                                else  { $self->throw('parse', uc($key)." not allowed in TMPL_$func tag", undef, pos($$str_ref)) }
                            }
                        } elsif ($$str_ref =~ m{ \G ([\w./+_]+) \s* }gcx) {
                            $name ||= $1;
                        } elsif ($$str_ref =~ m{ \G ([\"\']) (.*?) (?<!\\) \1 \s* }gcx) {
                            $name ||= $2;
                        } else {
                            last;
                        }
                    }

                    $self->throw('parse', 'Error while looking for NAME', undef, pos($$str_ref)) if ! defined($name) || ! length($name);
                    if ($func eq 'INCLUDE') {
                        $node->[0] = 'PROCESS'; # no need to localize the stash
                        $node->[3] = [[[undef, '{}'],0], $name];
                    } elsif ($func eq 'UNLESS') {
                        $node->[0] = 'IF';
                        $node->[3] = [[undef, '!', [$name, 0]], 0];
                    } else {
                        $node->[3] = [$name, 0]; # set the variable
                    }
                    $node->[3] = [[undef, '||', $node->[3], $default], 0] if $default;

                    ### dress up node before finishing
                    $escape = lc $self->{'DEFAULT_ESCAPE'} if ! $escape && $self->{'DEFAULT_ESCAPE'};
                    if ($escape) {
                        $self->throw('parse', "ESCAPE not allowed in TMPL_$func tag", undef, pos($$str_ref)) if $func ne 'GET';
                        if ($escape eq 'html' || $escape eq '1') {
                            push @{ $node->[3] }, '|', 'html', 0;
                        } elsif ($escape eq 'url') {
                            push @{ $node->[3] }, '|', 'url', 0;
                        } elsif ($escape eq 'js') {
                            push @{ $node->[3] }, '|', 'js', 0;
                        }
                    } elsif ($self->{'AUTO_FILTER'}) {
                        push @{ $node->[3] }, '|', $self->{'AUTO_FILTER'}, 0;
                    }
                }
                $node->[2] = pos $$str_ref;


            ### handle TT Directive extensions
            } else {
                $self->throw('parse', "Found a TT tag $func with NO_TT enabled", undef, pos($$str_ref)) if $self->{'NO_TT'};
                $node->[3] = eval { $dirs->{$func}->[0]->($self, $str_ref, $node) };
                if (my $err = $@) {
                    $err->node($node) if UNIVERSAL::can($err, 'node') && ! $err->node;
                    die $err;
                }
                $node->[2] = pos $$str_ref;
            }
        }

        ### handle ending tags - or continuation blocks
        if ($is_close || $dirs->{$func}->[4]) {
            if (! @state) {
                $self->throw('parse', "Found an $func tag while not in a block", $node, pos($$str_ref));
            }
            my $parent_node = pop @state;

            ### TODO - check for matching loop close name
            $func = $node->[0] = 'END' if $is_close;

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
        if ($$str_ref =~ m{ \G \s* $self->{'_end_tag'} }gcxs) {
            $post_chomp = $1 || $self->{'POST_CHOMP'};
            $post_chomp =~ y/-=~+/1230/ if $post_chomp;
            $continue = 0;
            $post_op  = 0;
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
    $self->throw('parse', "Missing </TMPL_ close tag", $state[-1], pos($$str_ref)) if @state > 0;

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

###----------------------------------------------------------------###
### a few HTML::Template and HTML::Template::Expr routines

sub param {
    my $self = shift;
    my $args;
    if (@_ == 1) {
        my $key = shift;
        if (ref($key) ne 'HASH') {
            $key = lc $key if ! $self->{'CASE_SENSITIVE'};
            return $self->{'_vars'}->{$key};
        }
        $args = [%$key];
    } else {
        $self->throw('param', "Odd number of parameters") if @_ % 2;
        $args = \@_;
    }
    while (@$args) {
        my $key = shift @$args;
        $key = lc $key if ! $self->{'CASE_SENSITIVE'};
        $self->{'_vars'}->{$key} = shift @$args;
    }
    return;
}

sub output {
    my $self = shift;
    my $args = ref($_[0]) eq 'HASH' ? shift : {@_};
    my $type = $self->{'TYPE'} || '';

    my $content;
    if ($type eq 'filehandle' || $self->{'FILEHANDLE'}) {
        my $in = $self->{'FILEHANDLE'} || $self->{'SOURCE'} || $self->throw('output', 'Missing source for type filehandle');
        local $/ = undef;
        $content = <$in>;
        $content = \$content;
    } elsif ($type eq 'arrayref' || $self->{'ARRAYREF'}) {
        my $in = $self->{'ARRAYREF'} || $self->{'SOURCE'} || $self->throw('output', 'Missing source for type arrayref');
        $content = join "", @$in;
        $content = \$content;
    } elsif ($type eq 'filename' || $self->{'FILENAME'}) {
        $content = $self->{'FILENAME'} || $self->{'SOURCE'} || $self->throw('output', 'Missing source for type filename');
    } elsif ($type eq 'scalarref' || $self->{'SCALARREF'}) {
        $content = $self->{'SCALARREF'} || $self->{'SOURCE'} || $self->throw('output', 'Missing source for type scalarref');
    } else {
        $self->throw('output', "Unknown input type");
    }


    my $param = $self->{'_vars'} || {};
    if (my $ref = $self->{'ASSOCIATE'}) {
        foreach my $obj (ref($ref) eq 'ARRAY' ? $ref : @$ref) {
            foreach my $key ($obj->param) {
                $self->{'_vars'}->{$self->{'CASE_SENSITIVE'} ? $key : lc($key)} = $obj->param($key);
            }
        }
    }


    ### override some TT defaults
    local $self->{'FILE_CACHE'} = $self->{'DOUBLE_FILE_CACHE'} ? 1 : $self->{'FILE_CACHE'};
    my $cache_size  = ($self->{'CACHE'})         ? undef : 0;
    my $compile_dir = (! $self->{'FILE_CACHE'})  ? undef : $self->{'FILE_CACHE_DIR'} || $self->throw('output', 'Missing file_cache_dir');
    my $stat_ttl    = (! $self->{'BLIND_CACHE'}) ? undef : 60; # not sure how high to set the blind cache
    $cache_size = undef if $self->{'DOUBLE_FILE_CACHE'};

    local $self->{'SYNTAX'}         = $self->{'SYNTAX'} || 'hte';
    local $self->{'GLOBAL_CACHE'}   = $self->{'CACHE'};
    local $self->{'ADD_LOCAL_PATH'} = defined($self->{'ADD_LOCAL_PATH'}) ? $self->{'ADD_LOCAL_PATH'} : 1;
    local $self->{'CACHE_SIZE'}     = $cache_size;
    local $self->{'STAT_TTL'}       = $stat_ttl;
    local $self->{'COMPILE_DIR'}    = $compile_dir;
    local $self->{'ABSOLUTE'}       = 1;
    local $self->{'RELATIVE'}       = 1;
    local $self->{'INCLUDE_PATH'}   = $self->{'PATH'};
    local $self->{'LOWER_CASE_VAR_FALLBACK'} = ! $self->{'CASE_SENSITIVE'}; # un-smart HTML::Template default
    local $Template::Alloy::QR_PRIVATE = undef;

    my $out = '';
    $self->process_simple($content, $param, \$out) || die $self->error;

    if ($args->{'print_to'}) {
        print {$args->{'print_to'}} $out;
        return undef;
    } else {
        return $out;
    }
}

###----------------------------------------------------------------###

1;

__END__

=head1 DESCRIPTION

The Template::Alloy::HTE role provides syntax and interface support for
the HTML::Template and HTML::Template::Expr modules.

Provides for extra or extended features that may not be as commonly used.
This module should not normally be used by itself.

See the Template::Alloy documentation for configuration and other parameters.

=head1 HOW IS Template::Alloy DIFFERENT FROM HTML::Template

Alloy can use the same base template syntax and configuration items as HTE
and HT.  The internals of Alloy were written to support TT3, but were
general enough to be extended to support HTML::Template as well.  The result
is HTML::Template::Expr compatible syntax, with Alloy speed and a wide range
of additional features.

The TMPL_VAR, TMPL_IF, TMPL_ELSE, TMPL_UNLESS, TMPL_LOOP, and TMPL_INCLUDE
all work identically to HTML::Template.

=over 4

=item

Added support for other TT3 directives and for TT style "dot notation."

    <TMPL_SET a = "bar">
    <TMPL_SET b = [1 .. 25]>
    <TMPL_SET foo = PROCESS 'filename.tt'>

    <TMPL_GET foo>  # similar to <TMPL_VAR NAME="foo">
    <TMPL_GET b.3>
    <TMPL_GET my.nested.chained.variable.1>
    <TMPL_GET my_var | html>

    <TMPL_USE foo = DBI(db => ...)>
    <TMPL_CALL foo.connect>

Any of the TT directives can be used in HTML::Template documents.

For many die-hard HTML::Template fans, it is probably quite scary to
be providing all of the TT functionality.  All of the extended
TT functionality can be disabled by setting the NO_TT configuration
item.  The NO_TT configuration is automatically set if the SYNTAX is
set to "ht" and the output method is called.

=item

There is an ELSIF!!!

    <TMPL_IF foo>
      FOO
    <TMPL_ELSIF bar>
      BAR
    <TMPL_ELSE>
      Done then
    </TMPL_IF>

=item

Added CHOMP capabilities (PRE_CHOMP and POST_CHOMP)

    Foo
    <~TMPL_VAR EXPR="1+2"~>
    Bar

    Prints Foo3Bar

=item

Added INTERPOLATE capability

    <TMPL_SET foo = 'FOO'>
    <TMPL_CONFIG INTERPOLATE => 1>
    $foo <TMPL_GET foo> ${ 1 + 2 }

    Prints

    FOO FOO 3

=item

Allow for HTML::Template templates to include TT style templates.

    <TMPL_CONFIG SYNTAX => 'tt3'>
    <TMPL_INCLUDE "filename.tt">

=item

Allow for Expr parsing to follow proper precedence rules.

   <TMPL_VAR EXPR="1 + 2 * 3">

   Properly prints 7.

=item

Uses all of the caching and opcode tree optimations provided by
Template::Alloy and Template::Alloy::XS.

=item

Alloy does not provide the query method from HTML::Template.  This
is because parsing of the document is delayed until the output
method is called, and because Alloy supports TT style chained
variables which often are not resolvable until run time.

=back

=head1 UNSUPPORTED HT CONFIGURATION

=over 4

=item die_on_bad_params

Alloy does not resolve variables until the template is output.

=item force_untaint

=item strict

Alloy is strict on parsing HT documents.

=item shared_cache, double_cache

Alloy doesn't have shared caching.  Yet.

=item search_path_on_include

Alloy will check the full path array on each include.

=item debug items

The HTML::Template style options are included here, but you
can use the TT style DEBUG and DUMP directives to do intropection.

=item max_includes

Alloy uses TT's recursion protection.

=item filter

Alloy doesn't offer these.

=back

=head1 ROLE METHODS

=over 4

=item C<register_function>

Defines a new function for later use as text vmethod or top level function.

=item C<clear_param>

Empties the paramter list.

=item C<query>

Not supported.

=item C<new_file>

Creates a new object that will process the passed file.

    $obj = Template::Alloy->new_file("my/file.hte");

=item C<new_scalar_ref>

Creates a new object that will process the passed scalar ref.

    $obj = Template::Alloy->new_scalar_ref(\"some template text");

=item C<new_array_ref>

New object that will process the passed array (each item represents a line).

    $obj = Template::Alloy->new_array_ref(\@array);

=item C<new_filehandle>

    $obj = Template::Alloy->new_filehandle(\*FH);

=item C<parse_tree_hte>

Called by parse_tree when syntax is set to ht or hte.  Parses for tags HTML::Template style.

=item C<param>

See L<Template::Alloy>.

=item C<output>

See L<Template::Alloy>.

=back

=head1 AUTHOR

Paul Seamons <paul at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
