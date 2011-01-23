package Template::Alloy::Tmpl;

=head1 NAME

Template::Alloy::Tmpl - Text::Tmpl role

=cut

use strict;
use warnings;
use Template::Alloy;

our $VERSION = $template::Alloy::VERSION;
our $error;

sub new { die "This class is a role for use by packages such as Template::Alloy" }

###----------------------------------------------------------------###

sub parse_tree_tmpl {
    my $self = shift;

    local @{ $Template::Alloy::Parse::ALIASES }{qw(ECHO INCLUDE IFN    ENDCOMMENT ENDIF ENDIFN ENDLOOP)}
                                                = qw(GET  PROCESS UNLESS END        END   END    END);
    local $self->{'V1DOLLAR'}   = defined($self->{'V1DOLLAR'}) ? $self->{'V1DOLLAR'} : 1;
    local $self->{'ANYCASE'}    = defined($self->{'ANYCASE'})  ? $self->{'ANYCASE'}  : 1;
    local $self->{'TAG_STYLE'}  = $self->{'TAG_STYLE'} || 'html';

    return $self->parse_tree_tt3(@_);
}

###----------------------------------------------------------------###
### support for few Text::Tmpl calling syntax

sub set_delimiters {
    my $self = shift;
    $self->{'START_TAG'} = quotemeta(shift || $self->throw('set', 'missing start_tag'));
    $self->{'END_TAG'}   = quotemeta(shift || $self->throw('set', 'missing end_tag'));
}

sub strerror { $Template::Alloy::Tmpl::error }

sub set_strip { my $self = shift; $self->{'POST_CHOMP'} = $_[0] ? '-' : '+'; 1 }

sub set_value { my $self = shift; $self->{'_vars'}->{$_[0]} = $_[1]; 1 }

sub set_values { my ($self, $hash) = @_; @{ $self->{'_vars'} ||= {} }{keys %$hash} = values %$hash; 1 }

sub parse_string { my $self = shift; return $self->parse_file(\$_[0]) }

sub set_dir {
    my $self = shift;
    $self->{'INCLUDE_PATHS'} = [shift, './'];
}

sub parse_file {
    my ($self, $content) = @_;

    my $vars = $self->{'_vars'} || {};

    local $self->{'SYNTAX'} = $self->{'SYNTAX'} || 'tmpl';
    local $Template::Alloy::QR_PRIVATE = undef;
    local $self->{'ABSOLUTE'} = defined($self->{'ABSOLUTE'}) ? $self->{'ABSOLUTE'} : 1;
    local $self->{'RELATIVE'} = defined($self->{'RELATIVE'}) ? $self->{'RELATIVE'} : 1;

    $error = undef;

    my $out = '';
    $self->process_simple($content, $vars, \$out)
        || ($error = $self->error);
    return $out;
}

sub loop_iteration {
    my $self = shift;
    my $name = shift;
    my $ref  = $self->{'_vars'}->{$name} ||= [];
    my $vars;

    $self->throw('loop', "Variable $name is not an arrayref during loop_iteration") if ref($ref) ne 'ARRAY';
    if (defined(my $index = shift)) {
        $vars = $ref->[$index] || $self->throw('loop', "Index $index is not yet defined on loop $name");
    } else {
        $vars = {};
        push @$ref, $vars;
    }

    return ref($self)->new('_vars' => $vars);
}

sub fetch_loop_iteration { shift->loop_iteration(@_) }

###----------------------------------------------------------------###

1;

__END__

=head1 DESCRIPTION

The Template::Alloy::Tmpl role provides the syntax and the interface
for Text::Tmpl.  It also brings many of the features from the various
templating systems.

See the Template::Alloy documentation for configuration and other parameters.

=head1 ROLE_METHODS

=over 4

=item C<parse_tree_tmpl>

Called by parse_tree when syntax is set to tmpl.  Parses for tags Text::Tmpl style.

=item C<set_delimiters>

Sets the START_TAG and END_TAG to use for parsing.

    $obj->set_delimiters('#[', ']#');

=item C<strerror>

Can be used for checking the error when compile fails (or you can use ->error).
May be called as function or method (Text::Tmpl only allows as function).

=item C<set_strip>

Determines if trailing whitespace on same line is removed.  Default is false.

=item C<set_dir>

Sets the path to look for included templates in.

=item C<set_value>

Sets a single value that will be used during processing of the template.

    $obj->set_value(key => $value);

=item C<set_values>

Sets multiple values for use during processing.

    $obj->set_values(\%values);

=item C<parse_string>

Processes the passed string.

    my $out = $obj->process_string("#[echo $foo]#");

=item C<parse_file>

Processes the passed filename.

    my $out = $obj->process_file("my/file.tmpl");

=item C<loop_iteration>

Same as the Text::Tmpl method - used for adding iterations to a loop.

    my $ref = $obj->loop_iteration('loop1'); # creates iteration 0
    $ref->set_values($hash);

=item C<fetch_loop_iteration>

Gets a previously created loop iteration.

    my $ref = $obj->fetch_loop_iteration('loop1', 0);
    $ref->set_values($hash);

=back

=head1 UNSUPPORTED Text::Tmpl METHODS

register_simple, register_pair, alias_simple, alias_pair, remove_simple, remove_pair, set_debug, errno

=head1 AUTHOR

Paul Seamons <paul at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
