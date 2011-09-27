package MYDLjE::Plugin::Helpers;
use MYDLjE::Base 'Mojolicious::Plugin';
use List::Util qw(first);

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
  }    #end if ($config->{textile})
  $app->helper(debug => sub { shift->app->log->debug(@_) });
  if ($config->{markdown}) {
    require Text::MultiMarkdown;
    my $markdown_config =
      (ref($config->{markdown}) && ref($config->{markdown}) eq 'HASH')
      ? $config->{markdown}
      : {};
    my $markdown;
    if (keys %$markdown_config) {

      $markdown = Text::MultiMarkdown->new(%$markdown_config);
    }
    else {
      $markdown = Text::MultiMarkdown->new(
        empty_element_suffix => '/>',
        tab_width            => 2,
        use_wikilinks        => 1,
      );
    }
    $app->helper(
      markdown => sub {
        my ($c, $text, $options) = @_;
        return $markdown->markdown(
          $text,
          { base_url => $c->stash('base_url'),
            %{$options || {}}
          }
        );
      }
    );
  }    #end if ($config->{markdown})
  $app->helper(
    set_ui_language => sub {
      my ($c, $ui_language) = @_;
      if ($ui_language) {
        for (@{$app->config('languages')}) {
          if ($ui_language eq $_) {
            $c->languages($ui_language);
            $c->session('ui_language', $ui_language);
            last;
          }
        }
      }
      elsif ($c->session('ui_language')) {
        $c->languages($c->session('ui_language'));
      }
      else {

        #use browser language if supported, default language otherwise.
        my $ua_lang = $c->languages;
        if (my $lang = first { $_ eq $ua_lang } @{$app->config('languages')}) {
          $c->languages($lang);
          $c->session('ui_language', $lang);
        }
        else {
          $c->languages($app->config('plugins')->{I18N}{default});
          $c->session('ui_language', $c->languages);
        }
      }
      return $c->languages;
    }
  );
  require Mojo::JSON;
  $app->helper(json => sub { Mojo::JSON->new; });

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

=head2 markdown

=head2 set_ui_language

Sets the user interface language (labels and messages ) and puts it in session 
if switched.

Params: C<$ui_language>:

    #last overwrites first
    $c->req->param('ui_language')
    #or
    $c->stash('ui_language')
    
=head2 json

Returns a L<Mojo::JSON> instance.


=head1 SEE ALSO

L<MYDLjE::Guides>, L<MYDLjE::Site::C>, L<MYDLjE::Site>, L<MYDLjE>

=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

