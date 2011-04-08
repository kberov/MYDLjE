#!/usr/bin/env perl;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
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

use Test::More tests => 32;
use MYDLjE::Config;
use MYDLjE::Plugin::DBIx;
use MYDLjE::M::Content;
isa_ok('MYDLjE::M::Content', 'MYDLjE::M');

can_ok(
  'MYDLjE::M::Content', 'TABLE',
  'COLUMNS',            'data',
  'sql',                'make_field_attrs'
);
my $config =
  MYDLjE::Config->new(
  files => ["$ENV{MOJO_HOME}/conf/mydlje.$ENV{MOJO_MODE}.yaml"]);

#print Dumper();
my $dbix = MYDLjE::Plugin::DBIx::dbix(
  $config->stash('plugins')->{'MYDLjE::Plugin::DBIx'});

my $alias = 'test-' . time . '-test';
my $data  = {
  user_id     => 1,
  data_type   => 'note',
  data_format => 'html',
  alias       => $alias
};
my $content = MYDLjE::M::Content->new(%{$data});
isa_ok($content->dbix, 'DBIx::Simple');

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
  $question->title('What can I doooo?')->title,
  'What can I doooo?',
  'seting title'
);
$question->body('A longer description of the question');
is($question->alias, 'what-can-i-doooo', 'alias is "what-can-i-doooo"');
is($question->data_type, 'question', '$question->data_type is "question"');

require MYDLjE::M::Content::Answer;
my $answer = MYDLjE::M::Content::Answer->new(pid => $question->save);
is($answer->pid, $question->id, '$answer->pid is $question->id');
$answer->body('You can not do anything');
ok($answer->alias, $answer->alias);
is($answer->data_type, 'answer', '$answer->data_type is "answer"');
$answer->save();

#cleanup
$content->dbix->delete($content->TABLE, {alias => {-like => 'test-%-test'}});
$answer->dbix->delete($answer->TABLE, {id => $answer->id});
$question->dbix->delete($question->TABLE, id => $question->id);

# test MYDLjE::M::Session
require MYDLjE::M::Session;
my $session_id = Mojo::Util::md5_sum(1234567890);
my $sstorage = MYDLjE::M::Session->select(id => $session_id);
is($sstorage->id, undef, "No such session id: $session_id");

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
