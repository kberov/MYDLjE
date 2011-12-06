package MYDLjE::Plugin::Helpers;
use Mojo::Base 'Mojolicious::Plugin';
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
  $app->helper(validate_and_login => \&_validate_and_login);
  return;
}    #end register

sub _validate_and_login {
  my $c      = shift;
  my $params = $c->req->params->to_hash;
  $c->debug($c->dumper($params));
  if (($params->{session_id} || '') ne $c->msession->id) {
    $c->stash(validator_errors => {session_id_error => $c->l('session_id_error')});
    return 0;
  }
  $params->{login_name} =~ s/[^\p{IsAlnum}]//gx;

  #TODO: Implement authorisation and access lists
  # See http://www.perl.com/pub/2008/02/13/elements-of-access-control.html
  # User is logged in if all conditions below apply:
  #1. A user with this login name exists.
  #2. Password md5_sum matches,
  #3. Is not disabled
  #4. Is within allowed period of existence if there is such
  #5. Some of his groups namespaces allows this
  my $mojo_app = $c->app->env->{MOJO_APP};
  my $time     = time;
  my $and      = <<"AND";
    EXISTS (
        SELECT g.id FROM groups g WHERE g.namespaces LIKE '%$mojo_app%' AND
        g.id IN( SELECT ug.group_id FROM user_group ug WHERE ug.user_id=id)
        )
AND

  my $user = MYDLjE::M::User->select(
    login_name => $params->{login_name},
    -and =>
      [\'disabled=0', \$and, \"((start=0 OR start<$time) AND (stop=0 OR stop>$time))",],
  );

  unless ($user->id) {
    $c->app->log->error('No such user:' . $params->{login_name});
    $c->stash(validator_errors =>
        {login_name_error => $c->l('login_field_error', $c->l('login_name'))});
    return 0;
  }

  my $login_password_md5 =
    Mojo::Util::md5_sum(($params->{session_id} || '') . $user->login_password);
  if ($login_password_md5 ne $params->{login_password_md5}) {
    $c->stash(validator_errors =>
        {login_password_error => $c->l('login_field_error', $c->l('login_password'))});
    return 0;
  }
  else {
    $c->msession->sessiondata({});    #empty
    $c->msession->user($user);        #efficiently log in user
    return 1;
  }
  return 0;
}

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

=head2 validate_and_login

Validates parameters passed via a login form and logs in the user. 
Returns 1 on success, 0 otherwise.

The expected parameters passed to the form are:

  login_name, login_password_md5, session_id

B<login_name>

This value is checked if exists in the table users.
If this user is found we check if the user is from a group that is allowed to access the current application (a per-app. authrization only). The next check is if the user is disabled. 
Last check is if the user has "expired". See comments on fields in table users.

B<session_id>

This is the current C<$c->session('id')> value - a randomly generated md5 sum.

B<login_password_md5>

This is an md5_sum of the following (as made by login_form using JavaScript):

  var temp_login_password = hex_md5(login_name + login_password );
  $('#login_password_md5').val(hex_md5(session_id + temp_login_password));

Passwords are stored in database as md5_sum of the concatenated username and password.

You can create a username pasword on the command line and put it in the database field login_password. 

  perl -MMojo::Util -e'print Mojo::Util::md5_sum("username"."<!1password").$/'

  --then
  UPDATE users SET login_password='20ab28c74122b193ff8e7a497b3d7049'
  WHERE login_name='username'; 

MYDLjE does not check for passwords passed in plain text. 
On every login the checked C<login_password_md5> is salted with different C<session_id>.





=head1 SEE ALSO

L<MYDLjE::Guides>, L<MYDLjE::Site::C>, L<MYDLjE::Site>, L<MYDLjE>

=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров L<k.berov@gmail.com>

This code is licensed under LGPLv3.

