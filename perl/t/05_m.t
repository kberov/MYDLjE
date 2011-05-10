#!/usr/bin/env perl;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use utf8;
use Cwd;

BEGIN {
  $ENV{MOJO_MODE} ||= 'development';

  #$ENV{MOJO_MODE}='production';
  $ENV{MOJO_HOME} = Cwd::abs_path(dirname(__FILE__) . '/../..');

  $ENV{MOJO_APP} = 'MYDLjE::ControlPanel';
  @MYDLjE::ControlPanel::ISA = ('MYDLjE');
  $ENV{MOJO_LOG_LEVEL} = 'warn';    #set to 'debug' to see what is going on
}

use lib ("$ENV{MOJO_HOME}/perl/lib", "$ENV{MOJO_HOME}/perl/site/lib");

use Test::More;
use MYDLjE::Config;
use MYDLjE::Plugin::DBIx;
use MYDLjE::M::Content;

my $config = MYDLjE::Config->new(
  files => [
    "$ENV{MOJO_HOME}/conf/mydlje.$ENV{MOJO_MODE}.yaml",
    "$ENV{MOJO_HOME}/conf/local.mydlje.$ENV{MOJO_MODE}.yaml"
  ]
);
if (not $config->stash('installed')) {
  plan skip_all => 'System is not installed. Will not test MYDLjE::M.';
}
else {
  plan tests => 81;
}
isa_ok('MYDLjE::M::Content', 'MYDLjE::M');

can_ok(
  'MYDLjE::M::Content', 'TABLE',
  'COLUMNS',            'data',
  'sql',                'make_field_attrs'
);

#print Dumper();
my $dbix = MYDLjE::Plugin::DBIx::dbix(
  $config->stash('plugins')->{'MYDLjE::Plugin::DBIx'});
my $time  = time;
my $alias = 'test-' . $time . '-test';
my $data  = {
  user_id     => 1,
  data_type   => 'note',
  data_format => 'html',
  alias       => $alias
};
my $content = MYDLjE::M::Content->new(%{$data});
isa_ok($content->dbix, 'DBIx::Simple');
is($content->{data}{data_type},
  'note', 'content has correct data_type because it is explicitely defined');
$content->body('<p>Hello</p>');
is($content->user_id, 1, 'user_id is ' . $content->user_id);
$content->user_id(2);
is($content->user_id, 2, 'user_id is ' . $content->user_id);

is($content->data_format, 'html', 'data_format is ' . $content->data_format);
is($content->data_type,   'note', 'data_type is ' . $content->data_type);
is($content->body,  '<p>Hello</p>', 'body is ' . $content->body);
is($content->alias, $alias,         'alias is ' . $alias);
$data->{body}    = $content->body;
$data->{user_id} = $content->user_id;
is_deeply($content->data, $data, 'data is: ' . Dumper($content->data));
ok(
  $content->time_created("sdjsdh$time-sdjfhj") <= time,
  'time_created is ' . localtime($content->time_created)
);
ok($content->time_created <= time,
  'time_created is ' . localtime($content->time_created));
is($content->featured,                  0,     'featured 0');
is($content->featured('yes')->featured, 1,     'featured 1');
is($content->start,                     0,     'start 0');
is($content->start($time)->start,       $time, 'start ' . $time);
is($content->stop,                      0,     'stop 0');
is($content->stop($time)->stop,         $time, 'stop ' . $time);
is($content->bad,                       0,     'bad 0');
is($content->bad('very')->bad,          1,     'bad 1');
is($content->bad('very')->bad,          2,     'bad 2');
is(
  $content->keywords('YEAH,adsads,&sds*?another')->keywords,
  'yeah, adsads, sds, another',
  'keywords ok'
);
ok($content->save >= $content->id, '$content->save ok ' . $content->id);

my $id = $content->dbix->last_insert_id(undef, undef, $content->TABLE, 'id');
ok($id, 'new id is:' . $id);

require MYDLjE::M::Content::Note;
my $note = MYDLjE::M::Content::Note->select(id => $id);

is($note->user_id, $content->user_id, '$note->user_id is ' . $note->user_id);
is($note->alias,   $content->alias,   '$note->alias is ' . $note->alias);

require MYDLjE::M::Content::Question;
my $question = MYDLjE::M::Content::Question->select(id => $id);
is($question->id, undef, '$question->id undef ');
is(
  $question->title('What <br>can I doooo?')->title,
  'What brcan I doooo?',
  'seting title'
);
$question->body('A longer description of the question');
is($question->alias, 'what-brcan-i-doooo', 'alias is "what-can-i-doooo"');
is($question->data_type, 'question', '$question->data_type is "question"');
is($question->user_id($note->user_id)->user_id,
  $note->user_id, 'question has owner');

require MYDLjE::M::Content::Answer;
my $answer = MYDLjE::M::Content::Answer->new(pid => $question->save);
is($answer->{data}{data_type},
  'answer', 'answer has correctly guessed data_type');
is($answer->pid, $question->id, '$answer->pid is $question->id');
$answer->body('You can not do anything');
ok($answer->alias, $answer->alias);
is($answer->data_type, 'answer', '$answer->data_type is "answer"');
is($answer->user_id($note->user_id)->user_id,
  $note->user_id, 'answer has owner');

$answer->save();

require MYDLjE::M::Content::Page;
my $page_content = MYDLjE::M::Content::Page->new();
is($page_content->title('Христос възкръсна!')->alias,
  'xristos-vazkrasna', 'alias is unidecoded ok');
is($page_content->language('bg')->language, 'bg', 'language bg ok');

#Use Custom data_type
my $my_custom = MYDLjE::M::Content->new(alias => $alias, user_id => 2);
delete $my_custom->FIELDS_VALIDATION->{data_type}{constraints};
$my_custom->data_type('alabala');
$my_custom->body('alabala body');
is($my_custom->data_type,                'alabala', 'custom data_type');
is($my_custom->language,                 '',        'language ok');
is($my_custom->language('bg')->language, 'bg',      'language ok');
is(
  $my_custom->tags('perl,| Content-Management,   javaScript||jAvA')->tags,
  'perl, content-management, javascript, java',
  'tags ok'
);
ok($my_custom->save, 'saving custom data_type is ok');

#Retreive Custom data_type
$my_custom = MYDLjE::M::Content->new;
is($my_custom->data_type, 'content',
  'default data_type is ' . $my_custom->data_type);
delete $my_custom->FIELDS_VALIDATION->{data_type}{constraints};
is($my_custom->data_type('alabala')->data_type, 'alabala',
  'custom data_type');
is($my_custom->select(alias => $alias)->data_type,
  'alabala', 'custom data_type retrieved ok');
is($my_custom->alias,    $alias, 'custom alias is unique for this data type');
is($my_custom->language, 'bg',   'language ok');
is($my_custom->language('bgsds')->language, '', 'language ok');

is($my_custom->body, 'alabala body', 'custom retrieved ok');

#=pod

#cleanup
$content->dbix->delete($content->TABLE,
  {alias => {-like => ['test%', 'what-brcan-i-doooo']}});
$answer->dbix->delete($answer->TABLE, {id => $answer->id});
$question->dbix->delete($question->TABLE, id => $question->id);

#=cut

# test MYDLjE::M::Session
require MYDLjE::M::Session;
my $session_id = Mojo::Util::md5_sum(1234567890);
my $sstorage = MYDLjE::M::Session->select(id => $session_id);
is($sstorage->id, undef, "No such session id: $session_id");
ok($sstorage->guest, '$sstorage->guest - yes');

#$sstorage->user_id is always the same as $sstorage->user->id
is($sstorage->user_id, 2,
  "\$sstorage->user_id is guest user_id: " . $sstorage->user->id);
$sstorage->sessiondata->{something} = 'Някакъв текст';
ok($session_id = $sstorage->save, 'session stored');
is(
  $sstorage->sessiondata->{user_data}->{login_name},
  $sstorage->user->login_name,
  'sessiondata is freesed and thawed'
);
my $login_name = $sstorage->user->login_name;

#retrieve a saved session
undef($sstorage);
$sstorage = MYDLjE::M::Session->select(id => $session_id);
is($session_id, $sstorage->id, 'session restored');
is(
  $sstorage->sessiondata->{something},
  'Някакъв текст',
  'sessiondata is usable really'
);
is($sstorage->user->login_name,
  $login_name, '$login_name is the same in the restored session');
undef($sstorage);
ok($sstorage = MYDLjE::M::Session->new, 'empty session initialised');
$sstorage->user(MYDLjE::M::User->select(login_name => 'admin'));
is($sstorage->user->id, $sstorage->user_id,
  '$sstorage->user->id  is always the same as $sstorage->user_id');
is($sstorage->new_id, $sstorage->save,
  '$sstorage->new_id is returned by $sstorage->save');

#Switched user(Login)
$sstorage = MYDLjE::M::Session->select(id => $sstorage->new_id);
is($sstorage->user->login_name,
  'admin', 'session restored again with newly logged in user');
ok(!$sstorage->guest, '$sstorage->guest - no');

#test WHERE
my $user = MYDLjE::M::User->new();

$user->WHERE({disabled => 0});

#$user->dbix->{debug}=1;
$user->select(login_name => 'admin');
is($user->id, undef, "WHERE my_user.disabled=0 AND login_name='admin'");
$user = MYDLjE::M::User->new();
$user->WHERE({disabled => 0});
$user->select(login_name => 'guest');
is($user->id, 2, " id WHERE my_user.disabled=0 AND login_name='guest'");
is($user->group_id, 2,
  " group_id WHERE my_user.disabled=0 AND login_name='guest'");


#try with foreign keys
$user = MYDLjE::M::User->new();
$user->TABLE($user->TABLE . ' AS u');

#select a user only if he is from a group with id 2(guest)
$user->WHERE(
  { disabled => 0,
    -and     => [
      \"EXISTS (SELECT g.gid FROM my_users_groups g WHERE g.uid=u.id and g.gid=u.group_id)"
    ],
  }
);

#TODO: leverage $dbh->{Callbacks} for debugging.
#$user->dbix->{debug} =1;
$user->select(login_name => 'guest', group_id => 2);
is($user->id, 2, "custom WHERE with literal SQL");


#Add a new user
#test1 with minimum params
$login_name = 'perko' . $sstorage->cid . 'I';

my $login_password = rand($time) . $login_name;
my $new_user       = MYDLjE::M::User->add(
  login_name     => $login_name,
  login_password => $login_password,
  email          => $login_name . '@localhost.com',
);
my @added_users = ($login_name);
ok($new_user->id,
  'addedd user with id:' . $new_user->id . ' and with minimal params.');
is(
  $new_user->email,
  $dbix->select('my_users', '*', {id => $new_user->id})->hash->{email},
  'user ok in database'
);

$login_name .= $new_user->id;

# more groups
$new_user = MYDLjE::M::User->add(
  login_name     => $login_name,
  login_password => $login_password,
  group_ids      => [3, 4],
  email          => $login_name . '@localhost.com',
);
push @added_users, $login_name;
ok($new_user->id,
  'added user with id:' . $new_user->id . ' and with more group_ids.');

# more namespaces
$login_name .= $new_user->id;
$new_user = MYDLjE::M::User->add(
  login_name     => $login_name,
  login_password => $login_password,
  group_ids      => [3, 4],
  email          => $login_name . '@localhost.com',
  namespaces     => $ENV{MOJO_APP} . ', MYDLjE::Site'
);
push @added_users, $login_name;
ok($new_user->id,
  'added user with id:' . $new_user->id . ' and with more namespaces.');


#Log In strictly a newly created user
#TODO: make this a ready SQL when stable enough
$sstorage->user(
  MYDLjE::M::User->select(
    login_name     => $login_name,
    login_password => Mojo::Util::md5_sum($login_name . $login_password),
    -and           => [
      \qq|disabled=0|,
      \qq|EXISTS (
    SELECT g.id FROM my_groups g WHERE g.namespaces LIKE '%$ENV{MOJO_APP}%' AND
    g.id IN( SELECT ug.gid FROM my_users_groups ug WHERE ug.uid=id)
    )|,
      \qq|((start=0 OR start<$time) AND (stop=0 OR stop>$time))|,
    ],
  )
);

# User is logged in if all conditions below apply:
#1. A user with this login name exists.
#2. Password md5_sum matches,
#3. Is not disabled
#4. Is within allowed period of existence if there is such
#5. Some of his groups namespaces allows this
is($sstorage->user->login_name,
  $login_name, "user $login_name logged in accordingly");

#=pod

$dbix->delete('my_sessions', {id => $sstorage->id});
foreach my $u (@added_users) {
  $dbix->delete('my_users',  {login_name => $u});
  $dbix->delete('my_groups', {name       => $u});
}

#=cut

# test MYDLjE::M::Page
require MYDLjE::M::Page;

my $page = MYDLjE::M::Page->new(
  pid       => 0,
  alias     => 'home' . $time,
  page_type => 'root'
);
is($page->pid, 0, '$page->pid is ' . $page->pid);
is($page->alias, 'home' . $time, '$page->alias is ' . $page->alias);
is($page->page_type, 'root', '$page->page_type is ' . $page->page_type);
is($page->user_id(1)->user_id,   1, '$page->user_id is ' . $page->user_id);
is($page->group_id(1)->group_id, 1, '$page->group_id is ' . $page->group_id);
is($page->permissions('-rwxrw-r-x')->permissions,
  '-rwxrw-r-x', '$page->permissions are ' . $page->permissions);

#reuse some data
$page_content->user_id($page->user_id);
$page_content->group_id($page->group_id);
$page = MYDLjE::M::Page->add(%{$page->data}, page_content => $page_content);
is($page->id, $page_content->page_id, '$page->id is $page_content->page_id');
is($page->permissions, 'drwxrw-r-x',
  '$page->permissions are ' . $page->permissions);

#clean up...

