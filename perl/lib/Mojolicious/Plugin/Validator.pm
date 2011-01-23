package Mojolicious::Plugin::Validator;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::ByteStream;
use Mojo::Loader;
use MojoX::Validator;

require Carp;

sub register {
    my ($self, $app, $conf) = @_;

    $conf ||= {};

    $app->helper(
        create_validator => sub {
            my $self       = shift;
            my $class_name = shift;

            $class_name ||= 'MojoX::Validator';

            unless ($class_name =~ m/[A-Z]/) {
                my $namespace = ref($self->app) . '::';
                $namespace = '' if $namespace =~ m/^Mojolicious::Lite/;

                $class_name = join '' => $namespace,
                  Mojo::ByteStream->new($class_name)->camelize;
            }

            my $e = Mojo::Loader->new->load($class_name);

            Carp::croak qq/Can't load validator '$class_name': / . $e->message
              if ref $e;

            Carp::croak qq/Can't find validator '$class_name'/ if $e;

            Carp::croak qq/Wrong validator '$class_name' isa/
              unless $class_name->isa('MojoX::Validator');

            return $class_name->new(%$conf, @_);
        }
    );

    $app->helper(
        validate => sub {
            my $self      = shift;
            my $validator = shift;
            my $params    = shift;

            $params ||= $self->req->params->to_hash;

            return 1 if $validator->validate($params);

            $self->stash(validator_errors => $validator->errors);
            $self->stash(validator_has_unknown_params =>
                  $validator->has_unknown_params);

            return;
        }
    );

    $app->helper(validator_has_unknown_params =>
          sub { shift->stash('validator_has_unknown_params') });

    $app->helper(
        validator_has_errors => sub {
            my $self = shift;

            my $errors = $self->stash('validator_errors');

            return 0 if !$errors || !keys %$errors;

            return 1;
        }
    );

    $app->helper(
        validator_error => sub {
            my $self = shift;
            my $name = shift;

            return unless my $errors = $self->stash('validator_errors');

            return unless my $message = $errors->{$name};

            return $self->tag('div' => class => 'error' => sub {$message});
        }
    );
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Validator - Plugin for MojoX::Validator

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('validator');

    # Mojolicious::Lite
    plugin 'validator' => {
        messages => {
            REQUIRED                 => 'This field is required',
            LENGTH_CONSTRAINT_FAILED => 'Too big'
        }
    };

    sub action {
        my $self = shift;

        my $validator = $self->create_validator;
        $validator->field('username')->required(1)->length(3, 20);

        return unless $self->validate($validator);

        # Create a user for example
        ...
    }

    1;
    __DATA__

    @@ user.html.ep
    %= if (validator_has_errors) {
        <div class="error">Please, correct the errors below.</div>
    % }
    %= form_for 'user' => begin
        <label for="username">Username</label><br />
        <%= input_tag 'username' %><br />
        <%= validator_error 'username' %><br />

        <%= submit_button %>
    % end

=head1 DESCRIPTION

L<Mojolicious::Plugin::Validator> is a plugin for L<MojoX::Validator> that
simplifies parameters validation.

=head2 Options

=over

=item messages

    # Mojolicious::Lite
    plugin 'validator' => {
        messages => {
            REQUIRED                 => 'This field is required',
            LENGTH_CONSTRAINT_FAILED => 'Too big'
        }
    };

Replace default errors.

=back

=head2 Helpers

=over

=item create_validator

    my $validator = $self->create_validator;
    $validator->field('username')->required(1)->length(3, 20);

Create L<MojoX::Validator>.

    $self->create_validator('will-be_decamelized');
    $self->create_validator('Custom::Class');

Create a validator from a class derived from L<MojoX::Validator>. This way
preconfigured validators can be used.

=back

=over

=item validate

    $self->validate($validator);

Validate parameters with provided validator and automatically set errors.

=back

=over

=item validator_has_errors

    %= if (validator_has_errors) {
        <div class="error">Please, correct the errors below.</div>
    % }

Check if there are any errors.

=back

=over

=item validator_error

    <%= validator_error 'username' %>

Render the appropriate error.

=back

=over

=item validator_has_unknown_params

    %= if (validator_has_unknown_params) {
        <div class="error">Unspecified parameters were detected.</div>
    % }

Returns true if unspecified parameters were passed

=back

=head1 METHODS

L<Mojolicious::Plugin::Validator> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register helpers in L<Mojolicious> application.

=head1 SEE ALSO

L<MojoX::Validator>, L<Mojolicious>.

=cut
