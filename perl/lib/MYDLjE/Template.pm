package MYDLjE::Template;
use MYDLjE::Base -base;
use utf8;
our $VERSION = '0.03';
require Mojo::Util;

has context => sub { shift->{_CONTEXT} };
has stash   => sub { shift->context->stash };
sub get { return shift->stash->get(@_); }
## no critic qw(NamingConventions::ProhibitAmbiguousNames)
sub set { return shift->stash->set(@_); }
has c    => sub { shift->get('c'); };
has app  => sub { shift->c->app; };
has dbix => sub { shift->c->dbix; };
sub msession { shift->get('c')->msession(@_); }
has user => sub { shift->msession->user; };
sub process { return shift->{_CONTEXT}->process(@_); }
sub include { return shift->{_CONTEXT}->include(@_); }
sub insert  { return shift->{_CONTEXT}->insert(@_); }


sub load {    # called as MYDLjE::Template->load($context)
  my ($class, $context) = @_;
  return $class;
}

# called as MYDLjE::Template::PageTree->new($context)
#When you write
#  USE tree = PageTree(
#   pid=>0,
#   domain=> c.url_for.host,
#   language=>LANGUAGE ||=c.languages()
#  );
sub new {
  my ($class, $context, @params) = @_;
  return $class->SUPER::new(_CONTEXT => $context, @params);
}

#Copy => Paste => Modify acording PBP from Template::Base
sub error {
  my ($self, @params) = @_;
  my $errvar;

  {
    no strict qw( refs );
    $errvar = ref $self ? \$self->{_ERROR} : \${"$self\::ERROR"};
  }
  if (@params) {
    $$errvar = ref($params[0]) ? shift : join('', @params);
    return;
  }
  else {
    return $$errvar;
  }
}

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Template - Write TT/TA plugins for use in MYDLjE

=head1 SYNOPSIS

  #1. write a Template plugin that inherits MYDLjE::Template
  #See MYDLjE::Template::PageTree as example
  
  #2. Use it in your templates
  USE tree = PageTree(
    pid      => 0,
    domain   => c.req.url.host,
    language => LANGUAGE
  );
  tree.render();

=head1 DESCRIPTION

MYDLjE::Template is an implementation of L<Template::Plugin> with some
framework specific atributes and methods added so you do not have to add them in your own  Template plugins. We follow the API and recomendations specified by Andy Wardley.
The idea is to maintain compatibility with Template Toolkit so if someone decide  he can freely switch from Template::Alloy to Template Toolkit.
Finally, sometimes writing MACROS seems too messy or your idea is more complicated and it is best to write it in Perl.

=head1 ATTRIBUTES

=head2 context

The Template context object. It is passed to every plugin to L<load>  and upon instantiation to L<new>. See also L<Template::Plugin/new>.

=head2 stash

The object containing template variables.

=head2 c

The current controller object. Same as $self in a controller.

=head2 app

The application object - same as $self-E<gt>app in a controller.

 $self->c->app->log->debug('my debug message');

=head2 dbix

The L<DBIx::Simple> instance.

 $self->dbix->select('pages', { alias=>{-like =>'news%'} } );

=head2 msession

The L<MYDLjE::M::Session> instance.

=head2 user

The current user (MYDLjE::M::User) instance retreived from L<msession>.

=head1 METHODS

=head2 get

Get a variable from the L<stash>.

=head2 set

Set a variable in the  L<stash>.

=head2 process

Process a template - same as the PROCESS directive.

=head2 include

Include a template - same as the INCLUDE directive.

=head2 insert

Insert a template - same as the INSERT directive.

=head2 load

Implementation of the mandatory C<load> method.


=head2 new

Implementation of the mandatory C<new> method.


=head2 error

Implementation of the mandatory C<error> method.

=head1 SEE ALSO

This module is practically the same as L<Template::Plugin> but uses
MYDLjE::Base == Mojo::Base as base class.
L<http://search.cpan.org/dist/Template-Toolkit/lib/Template/Plugin.pm>

L<MYDLjE::Guides>, L<MYDLjE::ControlPanel>, 
L<MYDLjE::Site>, L<MYDLjE::Config>,L<Hash::Merge::Simple>, L<YAML::Tiny>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.


