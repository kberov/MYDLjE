package Template::Alloy;

###----------------------------------------------------------------###
#  See the perldoc in Template/Alloy.pod
#  Copyright 2007 - 2011 - Paul Seamons                              #
#  Distributed under the Perl Artistic License without warranty      #
###----------------------------------------------------------------###

use strict;
use warnings;
use 5.006;
use Template::Alloy::Exception;
use Template::Alloy::Operator qw(play_operator define_operator);
use Template::Alloy::VMethod  qw(define_vmethod $SCALAR_OPS $ITEM_OPS $ITEM_METHODS $FILTER_OPS $LIST_OPS $HASH_OPS $VOBJS);

use vars qw($VERSION);
BEGIN {
    $VERSION            = '1.016';
};
our $QR_PRIVATE         = qr/^[_.]/;
our $WHILE_MAX          = 1000;
our $MAX_EVAL_RECURSE   = 50;
our $MAX_MACRO_RECURSE  = 50;
our $STAT_TTL           = 1;
our $QR_INDEX           = '(?:\d*\.\d+ | \d+)';
our @CONFIG_COMPILETIME = qw(SYNTAX CACHE_STR_REFS ANYCASE INTERPOLATE PRE_CHOMP POST_CHOMP ENCODING
                             SEMICOLONS V1DOLLAR V2PIPE V2EQUALS AUTO_EVAL SHOW_UNDEFINED_INTERP AUTO_FILTER);
our @CONFIG_RUNTIME     = qw(ADD_LOCAL_PATH CALL_CONTEXT DUMP VMETHOD_FUNCTIONS STRICT);
our $EVAL_CONFIG        = {map {$_ => 1} @CONFIG_COMPILETIME, @CONFIG_RUNTIME};
our $EXTRA_COMPILE_EXT  = '.sto';
our $PERL_COMPILE_EXT   = '.pl';
our $GLOBAL_CACHE       = {};

###----------------------------------------------------------------###

our $AUTOROLE = {
    Compile  => [qw(compile_template compile_tree compile_expr)],
    HTE      => [qw(parse_tree_hte param output register_function clear_param query new_file new_scalar_ref new_array_ref new_filehandle)],
    Parse    => [qw(parse_tree parse_expr apply_precedence parse_args dump_parse_tree dump_parse_expr define_directive define_syntax)],
    Play     => [qw(play_tree _macro_sub)],
    Stream   => [qw(stream_tree)],
    TT       => [qw(parse_tree_tt3 process)],
    Tmpl     => [qw(parse_tree_tmpl set_delimiters set_strip set_value set_values parse_string set_dir parse_file loop_iteration fetch_loop_iteration)],
    Velocity => [qw(parse_tree_velocity merge)],
};
my $ROLEMAP = { map { my $type = $_; map { ($_ => $type) } @{ $AUTOROLE->{$type} } } keys %$AUTOROLE };
my %STANDIN = ('Template' => 'TT', 'Template::Toolkit' => 'TT', 'HTML::Template' => 'HTE', 'HTML::Template::Expr' => 'HTE', 'Text::Tmpl' => 'Tmpl');

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $meth = ($AUTOLOAD && $AUTOLOAD =~ /::(\w+)$/) ? $1 : $self->throw('autoload', "Invalid method $AUTOLOAD");
    if (! $self->can($meth)) {
        require Carp;
        Carp::croak("Can't locate object method \"$meth\" via package ".ref($self));
    }
    return $self->$meth(@_);
}

sub can {
    my ($self, $meth) = @_;
    __PACKAGE__->import($ROLEMAP->{$meth}) if $ROLEMAP->{$meth};
    return $self->SUPER::can($meth);
}

sub DESTROY {}

sub import {
    my $class = shift;
    foreach my $item (@_) {
        next if $item =~ /^(load|1)$/i;
        return $class->import(keys %$AUTOROLE) if lc $item eq 'all';

        my $type;
        if ($type = $STANDIN{$item}) {
            (my $file = "$item.pm") =~ s|::|/|g;
            if (! $INC{$file} || ! $item->isa(__PACKAGE__)) {
                if ($INC{$file}) { require Carp; Carp::croak("Class $item is already loaded - can't override") }
                eval "{package $item; our \@ISA = qw(".__PACKAGE__.");}";
                $INC{$file} = __FILE__;
                next if ! $AUTOROLE->{$type}; # already imported
            }
        }
        $type ||= $AUTOROLE->{$item} ? $item : $ROLEMAP->{$item} || do { require Carp; Carp::croak("Invalid import option \"$item\"") };

        my $pkg   = __PACKAGE__."::$type";
        (my $file = "$pkg.pm") =~ s|::|/|g;
        require $file;

        no strict 'refs';
        *{__PACKAGE__."::$_"} = \&{"$pkg\::$_"} for @{ $AUTOROLE->{$type} };
        $AUTOROLE->{$type} = [];
    }
    return 1;
}

###----------------------------------------------------------------###

sub new {
  my $class = shift;
  my $args  = ref($_[0]) ? { %{ shift() } } : {@_};

  ### allow for lowercase args
  if (my @keys = grep {/^[a-z][a-z_]+$/} keys %$args) {
      @{ $args }{ map { uc $_ } @keys } = delete @{ $args }{ @keys };
  }

  return bless $args, $class;
}

###----------------------------------------------------------------###

sub run { shift->process_simple(@_) }

sub process_simple {
    my $self = shift;
    my $in   = shift || die "Missing input";
    my $swap = shift || die "Missing variable hash";
    my $out  = shift || ($self->{'STREAM'} ? \ "" : die "Missing output string ref");
    delete $self->{'error'};

    eval {
        delete $self->{'_debug_off'};
        delete $self->{'_debug_format'};
        local $self->{'_start_top_level'} = 1;
        $self->_process($in, $swap, $out);
    };
    if (my $err = $@) {
        if ($err->type !~ /stop|return|next|last|break/) {
            $self->{'error'} = $err;
            die $err if $self->{'RAISE_ERROR'};
            return;
        } elsif ($err->type eq 'return' && UNIVERSAL::isa($err->info, 'HASH')) {
            return $err->info->{'return_val'};
        }
    }
    return 1;
}

sub _process {
    my $self = shift;
    my $file = shift;
    local $self->{'_vars'} = shift || {};
    my $out_ref = shift || $self->throw('undef', "Missing output ref");
    local $self->{'_top_level'} = delete $self->{'_start_top_level'};
    my $i = length $$out_ref;

    ### parse and execute
    my $doc;
    eval {
        $doc = (ref($file) eq 'HASH') ? $file : $self->load_template($file);

        ### prevent recursion
        $self->throw('file', "recursion into '$doc->{name}'")
            if ! $self->{'RECURSION'} && $self->{'_in'}->{$doc->{'name'}} && $doc->{'name'} ne 'input text';

        local $self->{'_in'}->{$doc->{'name'}} = 1;
        local $self->{'_component'} = $doc;
        local $self->{'_template'}  = $self->{'_top_level'} ? $doc : $self->{'_template'};
        local @{ $self }{@CONFIG_RUNTIME} = @{ $self }{@CONFIG_RUNTIME};

        ### run the document however we can
        if ($self->{'STREAM'}) {
            $self->throw('process', 'No _tree found') if ! $doc->{'_tree'};
            $self->stream_tree($doc->{'_tree'});
        } elsif ($doc->{'_perl'}) {
            $doc->{'_perl'}->{'code'}->($self, $out_ref);
        } elsif (! $doc->{'_tree'}) {
            $self->throw('process', 'No _perl and no _tree found');
        } else {
            $self->play_tree($doc->{'_tree'}, $out_ref);
        }

        ### trim whitespace from the beginning and the end of a block or template
        if ($self->{'TRIM'}) {
            substr($$out_ref, $i, length($$out_ref) - $i) =~ s{ \s+ $ }{}x; # tail first
            substr($$out_ref, $i, length($$out_ref) - $i) =~ s{ ^ \s+ }{}x;
        }
    };

    ### handle exceptions
    if (my $err = $@) {
        $err = $self->exception('undef', $err) if ! UNIVERSAL::can($err, 'type');
        $err->doc($doc) if $doc && $err->can('doc') && ! $err->doc;
        die $err if ! $self->{'_top_level'};
        die $err if $err->type ne 'stop' && ($err->type ne 'return' || $err->info);
    }

    return 1;
}

###----------------------------------------------------------------###

sub load_template {
    my ($self, $file) = @_;
    $self->throw('undef', 'Undefined file passed to load_template') if ! defined $file;

    my $docs = $self->{'GLOBAL_CACHE'} || ($self->{'_documents'} ||= {});
    $docs = $GLOBAL_CACHE if ! ref $docs;

    ### looks like a scalar ref
    my $doc;
    if (ref $file) {
        return $file if ref $file eq 'HASH';

        if (! defined($self->{'CACHE_STR_REFS'}) || $self->{'CACHE_STR_REFS'}) {
            my $_file = $self->string_id($file);
            if ($docs->{$_file}) { # no-ttl necessary
                $doc = $docs->{$_file};
                $doc->{'_perl'} = $self->load_perl($doc) if ! $doc->{'_perl'} && $self->{'COMPILE_PERL'}; # second hit
                return $doc;
            }
            $doc->{'_filename'} = $_file;
        } else {
            $doc->{'_no_perl'} = $self->{'FORCE_STR_REF_PERL'} ? 0 : 1;
        }
        $doc->{'_is_str_ref'} = 1;
        $doc->{'_content'}    = $file;
        $doc->{'name'}        = 'input text';
        $doc->{'modtime'}     = time;

    ### looks like a previously cached document
    } elsif ($docs->{$file}) {
        $doc = $docs->{$file};
        if (time - $doc->{'cache_time'} < ($self->{'STAT_TTL'} || $STAT_TTL) # don't stat more than once a second
            || $doc->{'modtime'} == (stat $doc->{'_filename'})[9]) {         # otherwise see if the file was modified
            $doc->{'_perl'} = $self->load_perl($doc) if ! $doc->{'_perl'} && $self->{'COMPILE_PERL'}; # second hit
            return $doc;
        }

    ### looks like a previously cached not-found
    } elsif ($self->{'_not_found'}->{$file}) {
        $doc = $self->{'_not_found'}->{$file};
        if (time - $doc->{'cache_time'} < ($self->{'NEGATIVE_STAT_TTL'} || $self->{'STAT_TTL'} || $STAT_TTL)) { # negative cache for a second
            die $doc->{'exception'};
        }
        delete $self->{'_not_found'}->{$file}; # clear cache on failure

    ### looks like a block passed in at runtime
    } elsif ($self->{'BLOCKS'}->{$file}) {
        my $block = $self->{'BLOCKS'}->{$file};
        $block = $block->() if UNIVERSAL::isa($block, 'CODE');
        if (! UNIVERSAL::isa($block, 'HASH')) {
            $self->throw('block', "Unsupported BLOCK type \"$block\"") if ref $block;
            $block = eval { $self->load_template(\$block) } || $self->throw('block', 'Parse error on predefined block');
        }
        $doc->{'name'} = $file;
        if ($block->{'_perl'}) {
            $doc->{'_perl'} = $block->{'_perl'};
        } elsif ($block->{'_tree'}) {
            $doc->{'_tree'} = $block->{'_tree'};
        } else {
            $self->throw('block', "Invalid block definition (missing tree)");
        }
        return $doc;
    }

    ### lookup the filename
    if (! $doc->{'_filename'} && ! ref $file) {
        $doc->{'name'} = $file;
        $doc->{'_filename'} = eval { $self->include_filename($file) };
        if (my $err = $@) {
            ### allow for blocks in other files
            if ($self->{'EXPOSE_BLOCKS'} && ! $self->{'_looking_in_block_file'}) {
                local $self->{'_looking_in_block_file'} = 1;
                my $block_name = '';
                OUTER: while ($file =~ s|/([^/.]+)$||) {
                    $block_name = length($block_name) ? "$1/$block_name" : $1;
                    my $ref = eval { $self->load_template($file) } || next;
                    my $_tree = $ref->{'_tree'};
                    foreach my $node (@$_tree) {
                        last if ! ref $node;
                        next if $node->[0] eq 'META';
                        last if $node->[0] ne 'BLOCK';
                        next if $block_name ne $node->[3];
                        $doc->{'_tree'} = $node->[4];
                        @{$doc}{qw(modtime _content)} = @{$ref}{qw(modtime _content)};
                        $doc->{'_perl'} = {
                            meta   => {},
                            blocks => {},
                            code   => $ref->{'_perl'}->{'blocks'}->{$block_name}->{'_perl'}->{'code'},
                        } if $ref->{'_perl'} && $ref->{'_perl'}->{'blocks'} && $ref->{'_perl'}->{'blocks'}->{$block_name};
                        return $doc;
                    }
              }
            } elsif ($self->{'DEFAULT'}) {
                $err = '' if ($doc->{'_filename'} = eval { $self->include_filename($self->{'DEFAULT'}) });
            }
            if ($err) {
                ### cache the negative error
                if (! defined($self->{'NEGATIVE_STAT_TTL'}) || $self->{'NEGATIVE_STAT_TTL'}) {
                    $err = $self->exception('undef', $err) if ! UNIVERSAL::can($err, 'type');
                    $self->{'_not_found'}->{$file} = {
                        cache_time => time,
                        exception  => $self->exception($err->type, $err->info." (cached)"),
                    };
                }
                die $err;
            }
        }
    }

    ### return perl - if they want perl - otherwise - the ast
    if (! $doc->{'_no_perl'} && $self->{'COMPILE_PERL'} && ($self->{'COMPILE_PERL'} ne '2' || $self->{'_tree'})) {
        $doc->{'_perl'} = $self->load_perl($doc);
    } else {
        $doc->{'_tree'} = $self->load_tree($doc);
    }

    ### cache parsed_tree in memory unless asked not to do so
    if (! defined($self->{'CACHE_SIZE'}) || $self->{'CACHE_SIZE'}) {
        $doc->{'cache_time'} = time;
        if (ref $file) {
            $docs->{$doc->{'_filename'}} = $doc if $doc->{'_filename'};
        } else {
            $docs->{$file} ||= $doc;
        }

        ### allow for config option to keep the cache size down
        if ($self->{'CACHE_SIZE'}) {
            if (scalar(keys %$docs) > $self->{'CACHE_SIZE'}) {
                my $n = 0;
                foreach my $file (sort {$docs->{$b}->{'cache_time'} <=> $docs->{$a}->{'cache_time'}} keys %$docs) {
                    delete($docs->{$file}) if ++$n > $self->{'CACHE_SIZE'};
                }
            }
        }
    }

    return $doc;
}

sub string_id {
    my ($self, $ref) = @_;
    require Digest::MD5;
    my $sum   = Digest::MD5::md5_hex($$ref);
    return 'Alloy_str_ref_cache/'.substr($sum,0,3).'/'.$sum;
}

sub load_tree {
    my ($self, $doc) = @_;

    ### first look for a compiled optree
    if ($doc->{'_filename'}) {
        $doc->{'modtime'} ||= (stat $doc->{'_filename'})[9];
        if ($self->{'COMPILE_DIR'} || $self->{'COMPILE_EXT'}) {
            my $file = $doc->{'_filename'};
            if ($self->{'COMPILE_DIR'}) {
                $file =~ y|:|/| if $^O eq 'MSWin32';
                $file = $self->{'COMPILE_DIR'} .'/'. $file;
            } elsif ($doc->{'_is_str_ref'}) {
                $file = ($self->include_paths->[0] || '.') .'/'. $file;
            }
            $file .= $self->{'COMPILE_EXT'} if defined($self->{'COMPILE_EXT'});
            $file .= $EXTRA_COMPILE_EXT     if defined $EXTRA_COMPILE_EXT;

            if (-e $file && ($doc->{'_is_str_ref'} || (stat $file)[9] == $doc->{'modtime'})) {
                require Storable;
                return Storable::retrieve($file);
            }
            $doc->{'_storable_filename'} = $file;
        }
    }

    ### no cached tree - we will need to load our own
    $doc->{'_content'} ||= $self->slurp($doc->{'_filename'});

    if ($self->{'CONSTANTS'}) {
        my $key = $self->{'CONSTANT_NAMESPACE'} || 'constants';
        $self->{'NAMESPACE'}->{$key} ||= $self->{'CONSTANTS'};
    }

    local $self->{'_component'} = $doc;
    my $tree = eval { $self->parse_tree($doc->{'_content'}) }
        || do { my $e = $@; $e->doc($doc) if UNIVERSAL::can($e, 'doc') && ! $e->doc; die $e }; # errors die

    ### save a cache on the fileside as asked
    if ($doc->{'_storable_filename'}) {
        my $dir = $doc->{'_storable_filename'};
        $dir =~ s|/[^/]+$||;
        if (! -d $dir) {
            require File::Path;
            File::Path::mkpath($dir);
        }
        require Storable;
        Storable::store($tree, $doc->{'_storable_filename'});
        utime $doc->{'modtime'}, $doc->{'modtime'}, $doc->{'_storable_filename'};
    }

    return $tree;
}

sub load_perl {
    my ($self, $doc) = @_;

    ### first look for a compiled perl document
    my $perl;
    if ($doc->{'_filename'}) {
        $doc->{'modtime'} ||= (stat $doc->{'_filename'})[9];
        if ($self->{'COMPILE_DIR'} || $self->{'COMPILE_EXT'}) {
            my $file = $doc->{'_filename'};
            if ($self->{'COMPILE_DIR'}) {
                $file =~ y|:|/| if $^O eq 'MSWin32';
                $file = $self->{'COMPILE_DIR'} .'/'. $file;
            } elsif ($doc->{'_is_str_ref'}) {
                $file = ($self->include_paths->[0] || '.') .'/'. $file;
            }
            $file .= $self->{'COMPILE_EXT'} if defined($self->{'COMPILE_EXT'});
            $file .= $PERL_COMPILE_EXT      if defined $PERL_COMPILE_EXT;

            if (-e $file && ($doc->{'_is_str_ref'} || (stat $file)[9] == $doc->{'modtime'})) {
                $perl = $self->slurp($file);
            } else {
                $doc->{'_compile_filename'} = $file;
            }
        }
    }

    $perl ||= $self->compile_template($doc);

    ### save a cache on the fileside as asked
    if ($doc->{'_compile_filename'}) {
        my $dir = $doc->{'_compile_filename'};
        $dir =~ s|/[^/]+$||;
        if (! -d $dir) {
            require File::Path;
            File::Path::mkpath($dir);
        }
        open(my $fh, ">", $doc->{'_compile_filename'}) || $self->throw('compile', "Could not open file \"$doc->{'_compile_filename'}\" for writing: $!");
        ### todo - think about locking
        if ($self->{'ENCODING'} && eval { require Encode } && defined &Encode::encode) {
            print {$fh} Encode::encode($self->{'ENCODING'}, $$perl);
        } else {
            print {$fh} $$perl;
        }
        close $fh;
        utime $doc->{'modtime'}, $doc->{'modtime'}, $doc->{'_compile_filename'};
    }

    $perl = eval $$perl;
    $self->throw('compile', "Trouble loading compiled perl: $@") if ! $perl && $@;

    return $perl;
}

###----------------------------------------------------------------###

### allow for resolving full expression ASTs
sub play_expr {
    return $_[1] if ! ref $_[1]; # allow for the parse tree to store literals

    my $self = shift;
    my $var  = shift;
    my $ARGS = shift || {};
    my $i    = 0;

    ### determine the top level of this particular variable access
    my $ref;
    my $name = $var->[$i++];
    my $args = $var->[$i++];
    if (ref $name) {
        if (! defined $name->[0]) { # operator
            return $self->play_operator($name) if wantarray && $name->[1] eq '..';
            $ref = ($name->[1] eq '-temp-') ? $name->[2] : $self->play_operator($name);
        } else { # a named variable access (ie via $name.foo)
            $name = $self->play_expr($name);
            if (defined $name) {
                return if $QR_PRIVATE && $name =~ $QR_PRIVATE; # don't allow vars that begin with _
                return \$self->{'_vars'}->{$name} if $i >= $#$var && $ARGS->{'return_ref'} && ! ref $self->{'_vars'}->{$name};
                $ref = $self->{'_vars'}->{$name};
            }
        }
    } elsif (defined $name) {
        return if $QR_PRIVATE && $name =~ $QR_PRIVATE; # don't allow vars that begin with _
        return \$self->{'_vars'}->{$name} if $i >= $#$var && $ARGS->{'return_ref'} && ! ref $self->{'_vars'}->{$name};
        $ref = $self->{'_vars'}->{$name};
        if (! defined $ref) {
            $ref = ($name eq 'template' || $name eq 'component') ? $self->{"_$name"} : $VOBJS->{$name};
            $ref = $ITEM_METHODS->{$name} || $ITEM_OPS->{$name} if ! $ref && (! defined($self->{'VMETHOD_FUNCTIONS'}) || $self->{'VMETHOD_FUNCTIONS'});
            $ref = $self->{'_vars'}->{lc $name} if ! defined $ref && $self->{'LOWER_CASE_VAR_FALLBACK'};
        }
    }

    my %seen_filters;
    while (defined $ref) {

        ### check at each point if the returned thing was a code
        if (UNIVERSAL::isa($ref, 'CODE')) {
            return $ref if $i >= $#$var && $ARGS->{'return_ref'};
            my @args = $args ? map { $self->play_expr($_) } @$args : ();
            my $type = lc($self->{'CALL_CONTEXT'} || '');
            if ($type eq 'item') {
                $ref = $ref->(@args);
            } else {
                my @results = $ref->(@args);
                if ($type eq 'list') {
                    $ref = \@results;
                } elsif (defined $results[0]) {
                    $ref = ($#results > 0) ? \@results : $results[0];
                } elsif (defined $results[1]) {
                    die $results[1]; # TT behavior - why not just throw ?
                } else {
                    $ref = undef;
                    last;
                }
            }
        }

        ### descend one chained level
        last if $i >= $#$var;
        my $was_dot_call = $ARGS->{'no_dots'} ? 1 : $var->[$i++] eq '.';
        $name            = $var->[$i++];
        $args            = $var->[$i++];

        ### allow for named portions of a variable name (foo.$name.bar)
        if (ref $name) {
            if (ref($name) eq 'ARRAY') {
                $name = $self->play_expr($name);
                if (! defined($name) || ($QR_PRIVATE && $name =~ $QR_PRIVATE) || $name =~ /^\./) {
                    $ref = undef;
                    last;
                }
            } else {
                die "Shouldn't get a ". ref($name) ." during a vivify on chain";
            }
        }
        if (! defined $name || ($QR_PRIVATE && $name =~ $QR_PRIVATE)) { # don't allow vars that begin with _
            $ref = undef;
            last;
        }

        ### allow for scalar and filter access (this happens for every non virtual method call)
        if (! ref $ref) {
            if ($ITEM_METHODS->{$name}) {                      # normal scalar op
                $ref = $ITEM_METHODS->{$name}->($self, $ref, $args ? map { $self->play_expr($_) } @$args : ());

            } elsif ($ITEM_OPS->{$name}) {                     # normal scalar op
                $ref = $ITEM_OPS->{$name}->($ref, $args ? map { $self->play_expr($_) } @$args : ());

            } elsif ($LIST_OPS->{$name}) {                     # auto-promote to list and use list op
                $ref = $LIST_OPS->{$name}->([$ref], $args ? map { $self->play_expr($_) } @$args : ());

            } elsif (my $filter = $self->{'FILTERS'}->{$name}    # filter configured in Template args
                     || $FILTER_OPS->{$name}                     # predefined filters in Alloy
                     || (UNIVERSAL::isa($name, 'CODE') && $name) # looks like a filter sub passed in the stash
                     || $self->list_filters->{$name}) {          # filter defined in Template::Filters

                if (UNIVERSAL::isa($filter, 'CODE')) {
                    $ref = eval { $filter->($ref) }; # non-dynamic filter - no args
                    if (my $err = $@) {
                        $self->throw('filter', $err) if ! UNIVERSAL::can($err, 'type');
                        die $err;
                    }
                } elsif (! UNIVERSAL::isa($filter, 'ARRAY')) {
                    $self->throw('filter', "invalid FILTER entry for '$name' (not a CODE ref)");

                } elsif (@$filter == 2 && UNIVERSAL::isa($filter->[0], 'CODE')) { # these are the TT style filters
                    eval {
                        my $sub = $filter->[0];
                        if ($filter->[1]) { # it is a "dynamic filter" that will return a sub
                            ($sub, my $err) = $sub->($self->context, $args ? map { $self->play_expr($_) } @$args : ());
                            if (! $sub && $err) {
                                $self->throw('filter', $err) if ! UNIVERSAL::can($err, 'type');
                                die $err;
                            } elsif (! UNIVERSAL::isa($sub, 'CODE')) {
                                $self->throw('filter', "invalid FILTER for '$name' (not a CODE ref)")
                                    if ! UNIVERSAL::can($sub, 'type');
                                die $sub;
                            }
                        }
                        $ref = $sub->($ref);
                    };
                    if (my $err = $@) {
                        $self->throw('filter', $err) if ! UNIVERSAL::can($err, 'type');
                        die $err;
                    }
                } else { # this looks like our vmethods turned into "filters" (a filter stored under a name)
                    $self->throw('filter', 'Recursive filter alias \"$name\"') if $seen_filters{$name} ++;
                    $var = [$name, 0, '|', @$filter, @{$var}[$i..$#$var]]; # splice the filter into our current tree
                    $i = 2;
                }
                if (scalar keys %seen_filters
                    && $seen_filters{$var->[$i - 5] || ''}) {
                    $self->throw('filter', "invalid FILTER entry for '".$var->[$i - 5]."' (not a CODE ref)");
                }
            } else {
                $ref = undef;
            }

        } else {

            ### method calls on objects
            if ($was_dot_call && UNIVERSAL::can($ref, 'can')) {
                return $ref if $i >= $#$var && $ARGS->{'return_ref'};
                my $type = lc($self->{'CALL_CONTEXT'} || '');
                my @args = $args ? map { $self->play_expr($_) } @$args : ();
                if ($type eq 'item') {
                    $ref = $ref->$name(@args);
                    next;
                }
                my @results = eval { $ref->$name(@args) };
                if ($@) {
                    my $class = ref $ref;
                    die $@ if ref $@ || $@ !~ /Can\'t locate object method "\Q$name\E" via package "\Q$class\E"/ || $type eq 'list';
                } elsif ($type eq 'list') {
                    $ref = \@results;
                    next;
                } elsif (defined $results[0]) {
                    $ref = ($#results > 0) ? \@results : $results[0];
                    next;
                } elsif (defined $results[1]) {
                    die $results[1]; # TT behavior - why not just throw ?
                } else {
                    $ref = undef;
                    last;
                }
                # didn't find a method by that name - so fail down to hash and array access
            }

            if (UNIVERSAL::isa($ref, 'HASH')) {
                if ($was_dot_call && exists($ref->{$name}) ) {
                    return \ $ref->{$name} if $i >= $#$var && $ARGS->{'return_ref'} && ! ref $ref->{$name};
                    $ref = $ref->{$name};
                } elsif ($HASH_OPS->{$name}) {
                    $ref = $HASH_OPS->{$name}->($ref, $args ? map { $self->play_expr($_) } @$args : ());
                } elsif ($ARGS->{'is_namespace_during_compile'}) {
                    return $var; # abort - can't fold namespace variable
                } else {
                    return \ $ref->{$name} if $i >= $#$var && $ARGS->{'return_ref'};
                    $ref = undef;
                }

            } elsif (UNIVERSAL::isa($ref, 'ARRAY')) {
                if ($name =~ m{ ^ -? $QR_INDEX $ }ox) {
                    return \ $ref->[$name] if $i >= $#$var && $ARGS->{'return_ref'} && ! ref $ref->[$name];
                    $ref = $ref->[$name];
                } elsif ($LIST_OPS->{$name}) {
                    $ref = $LIST_OPS->{$name}->($ref, $args ? map { $self->play_expr($_) } @$args : ());
                } else {
                    $ref = undef;
                }
            }
        }

    } # end of while

    if (! defined $ref) {
        $self->strict_throw($var) if $self->{'STRICT'}; # will die
        die $self->tt_var_string($var)." is undefined\n" if $self->{'_debug_undef'};
        $ref = $self->undefined_any($var);
    }

    return $ref;
}

sub set_variable {
    my ($self, $var, $val, $ARGS) = @_;
    $ARGS ||= {};
    my $i = 0;

    ### allow for the parse tree to store literals - the literal is used as a name (like [% 'a' = 'A' %])
    $var = [$var, 0] if ! ref $var;

    ### determine the top level of this particular variable access
    my $ref  = $var->[$i++];
    my $args = $var->[$i++];
    if (ref $ref) {
        ### non-named types can't be set
        return if ref($ref) ne 'ARRAY';
        if (! defined $ref->[0]) {
            return if ! $ref->[1] || $ref->[1] !~ /^[\$\@]\(\)$/; # do allow @( )
            $ref = $self->play_operator($ref);
        } else {
            # named access (ie via $name.foo)
            $ref = $self->play_expr($ref);
            if (defined $ref && (! $QR_PRIVATE || $ref !~ $QR_PRIVATE)) { # don't allow vars that begin with _
                if ($#$var <= $i) {
                    return $self->{'_vars'}->{$ref} = $val;
                } else {
                    $ref = $self->{'_vars'}->{$ref} ||= {};
                }
            } else {
                return;
            }
        }
    } elsif (defined $ref) {
        return if $QR_PRIVATE && $ref =~ $QR_PRIVATE; # don't allow vars that begin with _
        if ($#$var <= $i) {
            return $self->{'_vars'}->{$ref} = $val;
        } else {
            $ref = $self->{'_vars'}->{$ref} ||= {};
        }
    }

    while (defined $ref) {

        ### check at each point if the returned thing was a code
        if (UNIVERSAL::isa($ref, 'CODE')) {
            my $type = lc($self->{'CALL_CONTEXT'} || '');
            my @args = $args ? map { $self->play_expr($_) } @$args : ();
            if ($type eq 'item') {
                $ref = $ref->(@args);
            } else {
                my @results = $ref->(@args);
                if ($type eq 'list') {
                    $ref = \@results;
                } elsif (defined $results[0]) {
                    $ref = ($#results > 0) ? \@results : $results[0];
                } elsif (defined $results[1]) {
                    die $results[1]; # TT behavior - why not just throw ?
                } else {
                    return;
                }
            }
        }

        ### descend one chained level
        last if $i >= $#$var;
        my $was_dot_call = $ARGS->{'no_dots'} ? 1 : $var->[$i++] eq '.';
        my $name         = $var->[$i++];
        my $args         = $var->[$i++];

        ### allow for named portions of a variable name (foo.$name.bar)
        if (ref $name) {
            if (ref($name) eq 'ARRAY') {
                $name = $self->play_expr($name);
                if (! defined($name) || $name =~ /^[_.]/) {
                    return;
                }
            } else {
                die "Shouldn't get a ".ref($name)." during a vivify on chain";
            }
        }
        if ($QR_PRIVATE && $name =~ $QR_PRIVATE) { # don't allow vars that begin with _
            return;
        }

        ### scalar access
        if (! ref $ref) {
            return;

        ### method calls on objects
        } elsif (UNIVERSAL::can($ref, 'can')) {
            my $lvalueish;
            my $type = lc($self->{'CALL_CONTEXT'} || '');
            my @args = $args ? map { $self->play_expr($_) } @$args : ();
            if ($i >= $#$var) {
                $lvalueish = 1;
                push @args, $val;
            }
            if ($type eq 'item') {
                $ref = $ref->$name(@args);
                return if $lvalueish;
                next;
            }
            my @results = eval { $ref->$name(@args) };
            if (! $@) {
                if ($type eq 'list') {
                    $ref = \@results;
                } elsif (defined $results[0]) {
                    $ref = ($#results > 0) ? \@results : $results[0];
                } elsif (defined $results[1]) {
                    die $results[1]; # TT behavior - why not just throw ?
                } else {
                    return;
                }
                return if $lvalueish;
                next;
            }
            my $class = ref $ref;
            die $@ if ref $@ || $@ !~ /Can\'t locate object method "\Q$name\E" via package "\Q$class\E"/;
            # fall on down to "normal" accessors
        }

        if (UNIVERSAL::isa($ref, 'HASH')) {
            if ($#$var <= $i) {
                return $ref->{$name} = $val;
            } else {
                $ref = $ref->{$name} ||= {};
                next;
            }

        } elsif (UNIVERSAL::isa($ref, 'ARRAY')) {
            if ($name =~ m{ ^ -? $QR_INDEX $ }ox) {
                if ($#$var <= $i) {
                    return $ref->[$name] = $val;
                } else {
                    $ref = $ref->[$name] ||= {};
                    next;
                }
            } else {
                return;
            }

        }

    }

    return;
}

###----------------------------------------------------------------###

sub _vars {
    my $self = shift;
    $self->{'_vars'} = shift if @_ == 1;
    return $self->{'_vars'} ||= {};
}

sub include_filename {
    my ($self, $file) = @_;
    if ($file =~ m|^/|) {
        $self->throw('file', "$file absolute paths are not allowed (set ABSOLUTE option)") if ! $self->{'ABSOLUTE'};
        return $file if -e $file;
    } elsif ($file =~ m{(^|/)\.\./}) {
        $self->throw('file', "$file relative paths are not allowed (set RELATIVE option)") if ! $self->{'RELATIVE'};
        return $file if -e $file;
    }

    my @paths = @{ $self->include_paths };
    if ($self->{'ADD_LOCAL_PATH'}
        && $self->{'_component'}
        && $self->{'_component'}->{'_filename'}
        && $self->{'_component'}->{'_filename'} =~ m|^(.+)/[^/]+$|) {
        ($self->{'ADD_LOCAL_PATH'} < 0) ? push(@paths, $1) : unshift(@paths, $1);
    }

    foreach my $path (@paths) {
        return "$path/$file" if -e "$path/$file";
    }

    $self->throw('file', "$file: not found");
}

sub include_paths {
    my $self = shift;
    return $self->{'INCLUDE_PATHS'} ||= do {
        # TT does this everytime a file is looked up - we are going to do it just in time - the first time
        my $paths = $self->{'INCLUDE_PATH'} || ['.'];
        $paths = $paths->()                 if UNIVERSAL::isa($paths, 'CODE');
        $paths = $self->split_paths($paths) if ! UNIVERSAL::isa($paths, 'ARRAY');
        $paths; # return of the do
    };
}

sub split_paths {
    my ($self, $path) = @_;
    return $path if UNIVERSAL::isa($path, 'ARRAY');
    my $delim = $self->{'DELIMITER'} || ':';
    $delim = ($delim eq ':' && $^O eq 'MSWin32') ? qr|:(?!/)| : qr|\Q$delim\E|;
    return [split $delim, "$path"]; # allow objects to stringify as necessary
}

sub slurp {
    my ($self, $file) = @_;
    open(my $fh, '<', $file) || $self->throw('file', "$file couldn't be opened: $!");
    read $fh, my $txt, -s $file;

    if ($self->{'ENCODING'}) { # thanks to Carl Franks for this addition
        eval { require Encode };
        if ($@ || ! defined &Encode::decode) {
            warn "Encode module not found, 'ENCODING' config only available on perl >= 5.7.3\n$@";
        } else {
            $txt = Encode::decode($self->{'ENCODING'}, $txt);
        }
    }

    return \$txt;
}

sub error { shift->{'error'} }

sub exception {
    my $self_or_class = shift;
    my $type = shift;
    my $info = shift;
    return $type if UNIVERSAL::can($type, 'type');
    if (ref($info) eq 'ARRAY') {
        my $hash = ref($info->[-1]) eq 'HASH' ? pop(@$info) : {};
        if (@$info >= 2 || scalar keys %$hash) {
            my $i = 0;
            $hash->{$_} = $info->[$_] for 0 .. $#$info;
            $hash->{'args'} = $info;
            $info = $hash;
        } elsif (@$info == 1) {
            $info = $info->[0];
        } else {
            $info = $type;
            $type = 'undef';
        }
    }
    return Template::Alloy::Exception->new($type, $info, @_);
}

sub throw { die shift->exception(@_) }

sub context {
    my $self = shift;
    require Template::Alloy::Context;
    return Template::Alloy::Context->new({_template => $self});
}

sub iterator {
    my $self = shift;
    require Template::Alloy::Iterator;
    Template::Alloy::Iterator->new(@_);
}

sub undefined_get {
    my ($self, $ident, $node) = @_;
    return $self->{'UNDEFINED_GET'}->($self, $ident, $node) if $self->{'UNDEFINED_GET'};
    return '';
}

sub undefined_any {
    my ($self, $ident) = @_;
    return $self->{'UNDEFINED_ANY'}->($self, $ident) if $self->{'UNDEFINED_ANY'};
    return;
}

sub strict_throw {
    my ($self, $ident) = @_;
    my $v = $self->tt_var_string($ident);
    my $temp = $self->{'_template'}->{'name'};
    my $comp = $self->{'_component'}->{'name'};
    my $msg  = "undefined variable: $v in $comp".($comp ne $temp ? " while processing $temp" : '');
    return $self->{'STRICT_THROW'}->($self, 'var.undef', $msg, {name => $v, component => $comp, template => $temp, ident => $ident}) if $self->{'STRICT_THROW'};
    $self->throw('var.undef', $msg);
}

sub list_filters { shift->{'_filters'} ||= eval { require Template::Filters; $Template::Filters::FILTERS } || {} }

sub debug_node {
    my ($self, $node) = @_;
    my $info = $self->node_info($node);
    my $format = $self->{'_debug_format'} || $self->{'DEBUG_FORMAT'} || "\n## \$file line \$line : [% \$text %] ##\n";
    $format =~ s{\$(file|line|text)}{$info->{$1}}g;
    return $format;
}

sub node_info {
    my ($self, $node) = @_;
    my $doc = $self->{'_component'};
    my $i = $node->[1];
    my $j = $node->[2] || return ''; # META can be 0
    $doc->{'_content'} ||= $self->slurp($doc->{'_filename'});
    my $s = substr(${ $doc->{'_content'} }, $i, $j - $i);
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    return {
        file => $doc->{'name'},
        line => $self->get_line_number_by_index($doc, $i),
        text => $s,
    };
}

sub get_line_number_by_index {
    my ($self, $doc, $index, $include_char) = @_;
    if (! $index || $index <= 0) {
        return $include_char ? (1, 1) : 1;
    }

    my $lines = $doc->{'_line_offsets'} ||= do {
        $doc->{'_content'} ||= $self->slurp($doc->{'_filename'});
        my $i = 0;
        my @lines = (0);
        while (1) {
            $i = index(${ $doc->{'_content'} }, "\n", $i) + 1;
            last if $i == 0;
            push @lines, $i;
        }
        \@lines;
    };

    ### binary search them (this is fast even on big docs)
    my ($i, $j) = (0, $#$lines);
    if ($index > $lines->[-1]) {
        $i = $j;
    } else {
        while (1) {
            last if abs($i - $j) <= 1;
            my $k = int(($i + $j) / 2);
            $j = $k if $lines->[$k] >= $index;
            $i = $k if $lines->[$k] <= $index;
        }
    }
    return $include_char ? ($i + 1, $index - $lines->[$i]) : $i + 1;
}

sub ast_string {
    my ($self, $var) = @_;

    return 'undef' if ! defined $var;
    return '['.join(', ', map { $self->ast_string($_) } @$var).']' if ref $var;
    return $var if $var =~ /^(-?[1-9]\d{0,13}|0)$/;

    $var =~ s/([\'\\])/\\$1/g;
    return "'$var'";
}

sub tt_var_string {
    my ($self, $ident) = @_;
    if (! ref $ident) {
        return $ident if $ident eq '0' || $ident =~ /^[1-9]\d{0,12}$/;
        $ident =~ s/\'/\\\'/g;
        return "'$ident'";
    }
    my $v = '';
    for (my $i = 0; $i < @$ident; ) {
        $v .= $ident->[$i++];
        $v .= '('.join(',',map{$self->tt_var_string($_)} @{$ident->[$i-1]}).')' if $ident->[$i++];
        $v .= $ident->[$i++] if $i < @$ident;
    }
    return $v;
}

1;

### See the perldoc in Template/Alloy.pod
