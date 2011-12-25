package MYDLjE::Plugin::TemplateAlloy;
use Mojo::Base 'Mojolicious::Plugin';
use Template::Alloy;

sub register {
  my ($self, $app, $config) = @_;
  $config ||= {};

  $app->helper(alloy => sub { Template::Alloy->new($config->{template_options}) })
    ;    #for direct usage

  #$syntax is also used as extension
  my $syntax = lc(delete $config->{syntax} || 'tt');

  #only TT supported for now
  if ($syntax =~ /tt/ix) {
    $app->renderer->add_handler($syntax => \&tt3);
    $app->renderer->default_handler($syntax);
  }
  else {
    Carp::confess('Only TT syntax is supported for now');
  }
  return;
}

sub tt3 {
  my ($r, $c, $output, $options) = @_;

  $r->default_template_class('MYDLjE::Plugin::TemplateAlloy::Templates');
  my $alloy = $c->alloy;

  # One time use inline template
  my $inline = $options->{inline};
  if ($inline) {
    $alloy->process(\$inline, {%{$c->stash}, c => $c}, $output)
      || ($$output = $c->tag(html => "Template Error: " . $alloy->error));
    return $output;
  }

  # Generate relative template path
  my $name = $r->template_name($options);

  # Try to find appropriate template in DATA section- TODO
  #my $template_content = $r->get_data_template($options, $name);

  # Generate absolute template path(NO NEED, Alloy handles relative paths)
  #my $path = $r->template_path($options);

  # This part is up to you and your template system :)
  #...
#  $c->debug(
#    #'$path:' . $path,
#    '$template_content:' . $template_content,
#    '$name:' . $name
#  );


  # Pass the rendered result back to the renderer
  unless (
    $alloy->process($name, {%{$c->stash}, c => $c}, $output, {binmode => ':utf8'}))
  {

    #TODO: make an exception template
    $$output = $c->tag(html => "Template Error: " . $alloy->error);
    return $output;
  }
  return $output;
}


1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Plugin::TemplateAlloy - 
Template::Alloy Renderer for MYDLjE

=head1 SEE ALSO

L<Mojolicious::Guides::Rendering>,
L<MYDLjE::Guides>, L<MYDLjE::Site::C>, L<MYDLjE::Site>, L<MYDLjE>

=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

