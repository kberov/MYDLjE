package Mojolicious::Plugin::GroupedParams;

use warnings;
use strict;

use base 'Mojolicious::Plugin';

our $VERSION = '0.02';

sub register {
    my ( $self, $app ) = @_;

    $app->helper(
        grouped_params => sub {
            my ( $self, $group ) = @_;
            my $groups = {};

            unless ( $self->stash('grouped_params') ) {

                my $params = $self->req->params->to_hash;

                for my $key ( keys %$params ) {
                   my ($group, $name) = $key =~ /^([^.]+)\.(.+)$/;
                   $groups->{$group} ||= {};
                   $groups->{$group}{$name} = $params->{$key};            
                }

            } 
            else { 
                $groups = $self->stash('grouped_params');
            }

            $group ? $groups->{$group} || {} : $groups;
        }
    );
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::GroupedParams - grouped params from query.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Mojolicious::Lite;

    plugin 'grouped_params';

    post '/save_article' => sub {
        my ( $self ) = @_;

        my $new_article = $self->grouped_params('article');

        $self->db->resultset('Article')->create($new_article);
        
    };

    # In template
    <input name="article.name" value="<%= grouped_params('article')->{name} %>" />
    <textarea name="article.text"><%= grouped_params('article')->{text} %></textarea>
    

=head1 FUNCTIONS 

=head2 register

Register plugin

=head2 grouped_params

This helper groups params with name like <group>.<name> 
and put grouped params into stash variable "grouped_params".

=head1 AUTHOR

Ivan Sokolov, C<< <ivsokolov at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-groupedparams at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-GroupedParams>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ivan Sokolov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
