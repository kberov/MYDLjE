package MYDLjE::Plugin::Helpers;
use MYDLjE::Base 'Mojolicious::Plugin';


sub register {
  my ($self, $app, $config) = @_;

  # Config
  $config ||= {};
  if ($config->{textile}) {    #Text::Textile
    require Text::Textile;
    my $textile_config =
      (ref($config->{textile}) && ref($config->{textile}) eq 'HASH')
      ? $config->{textile}
      : {};
    my $textile;
    if (keys %$textile_config) {

      # OOP usage
      $textile = Text::Textile->new(%$textile_config);
    }
    else {
      $textile = Text::Textile->new(
        flavor                  => 'xhtml1',
        css                     => {},
        charset                 => 'utf-8',
        trim_spaces             => 1,
        disable_encode_entities => 1,
      );
    }
    $app->helper(
      'textile',
      sub {
        my ($c, $text) = @_;
        $textile->docroot($c->stash('base_path'));
        return $textile->process($text);
      }
    );
    $app->helper(debug => sub { shift->app->log->debug(@_) });

  }

  return;
}    #end register

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::Plugin::Helpers - Default Helpers

=head1 SYNOPSIS

=head1 HELPERS


=head2 textile


