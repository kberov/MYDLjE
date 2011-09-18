package Template::Alloy::Context;

=head1 NAME

Template::Alloy::Context - Provide a TT style context

=cut

use strict;
use warnings;
use Template::Alloy;

our $VERSION = $Template::Alloy::VERSION;
use vars qw($AUTOLOAD);

###----------------------------------------------------------------###

sub new {
    my $class = shift;
    my $self  = shift || {};
    die "Missing _template" if ! $self->{'_template'};
    return bless $self, $class;
}

sub _template { shift->{'_template'} || die "Missing _template" }

sub template {
    my ($self, $name) = @_;
    return $self->_template->{'BLOCKS'}->{$name} || $self->_template->load_template($name);
}

sub config { shift->_template }

sub stash {
    my $self = shift;
    return $self->{'stash'} ||= bless {_template => $self->_template}, 'Template::Alloy::_ContextStash';
}

sub insert {
    my ($self, $file) = @_;;
    my $t = $self->_template;
    my $ref = $t->slurp($t->include_filename($file));
    return $$ref;
}

sub eval_perl { shift->_template->{'EVAL_PERL'} }

sub process {
    my $self = shift;
    my $ref  = shift;
    my $args = shift || {};

    $self->_template->set_variable($_, $args->{$_}) for keys %$args;

    my $out  = '';
    $self->_template->_process($ref, $self->_template->_vars, \$out);
    return $out;
}

sub include {
    my $self = shift;
    my $ref  = shift;
    my $args = shift || {};

    my $t = $self->_template;

    my $swap = $t->{'_vars'};
    local $t->{'_vars'} = {%$swap};

    $t->set_variable($_, $args->{$_}) for keys %$args;

    my $out = ''; # have temp item to allow clear to correctly clear
    eval { $t->_process($ref, $t->_vars, \$out) };
    if (my $err = $@) {
        die $err if ! UNIVERSAL::can($err, 'type') || $err->type !~ /return/;
    }

    return $out;
}

sub define_filter {
    my ($self, $name, $filter, $is_dynamic) = @_;
    $filter = [ $filter, 1 ] if $is_dynamic;
    $self->define_vmethod('filter', $name, $filter);
}

sub filter {
    my ($self, $name, $args, $alias) = @_;
    my $t = $self->_template;

    my $filter;
    if (! ref $name) {
        $filter = $t->{'FILTERS'}->{$name} || $Template::Alloy::FILTER_OPS->{$name} || $Template::Alloy::SCALAR_OPS->{$name};
        $t->throw('filter', $name) if ! $filter;
    } elsif (UNIVERSAL::isa($name, 'CODE') || UNIVERSAL::isa($name, 'ARRAY')) {
        $filter = $name;
    } elsif (UNIVERSAL::can($name, 'factory')) {
        $filter = $name->factory || $t->throw($name->error);
    } else {
        $t->throw('undef', "$name: filter not found");
    }

    if (UNIVERSAL::isa($filter, 'ARRAY')) {
        $filter = ($filter->[1]) ? $filter->[0]->($t->context, @$args) : $filter->[0];
    } elsif ($args && @$args) {
        my $sub = $filter;
        $filter = sub { $sub->(shift, @$args) };
    }

    $t->{'FILTERS'}->{$alias} = $filter if $alias;

    return $filter;
}

sub define_vmethod { shift->_template->define_vmethod(@_) }

sub throw {
    my ($self, $type, $info) = @_;

    if (UNIVERSAL::can($type, 'type')) {
	die $type;
    } elsif (defined $info) {
	$self->_template->throw($type, $info);
    } else {
	$self->_template->throw('undef', $type);
    }
}

sub AUTOLOAD { shift->_template->throw('not_implemented', "The method $AUTOLOAD has not been implemented") }

sub DESTROY {}

###----------------------------------------------------------------###

package Template::Alloy::_ContextStash;

use vars qw($AUTOLOAD);

sub _template { shift->{'_template'} || die "Missing _template" }

sub get {
    my ($self, $var) = @_;
    if (! ref $var) {
        if ($var =~ /^\w+$/) {  $var = [$var, 0] }
        else {                  $var = $self->_template->parse_expr(\$var, {no_dots => 1}) }
    }
    return $self->_template->play_expr($var, {no_dots => 1});
}

sub set {
    my ($self, $var, $val) = @_;
    if (! ref $var) {
        if ($var =~ /^\w+$/) {  $var = [$var, 0] }
        else {                  $var = $self->_template->parse_expr(\$var, {no_dots => 1}) }
    }
    $self->_template->set_variable($var, $val, {no_dots => 1});
    return $val;
}

sub AUTOLOAD { shift->_template->throw('not_implemented', "The method $AUTOLOAD has not been implemented") }

sub DESTROY {}

###----------------------------------------------------------------###

1;

__END__

=head1 DESCRIPTION

Template::Alloy::Context provides compatibility with Template::Context
and filters that require Template::Context.

=head1 TODO

Document all of the methods.

=head1 AUTHOR

Paul Seamons <paul at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
