#!/usr/bin/env perl;
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec;
use Cwd;
use Data::Dumper;

BEGIN {
    $ENV{MOJO_MODE}            = 'development';
    $ENV{MOJO_HOME}            = Cwd::realpath(File::Spec->rel2abs(dirname(__FILE__) . '/../..'));
    $ENV{MOJO_APP}             = 'MYDLjE::ControlPanel';
    @MYDLjE::ControlPanel::ISA = ('MYDLjE');
    $ENV{MOJO_LOG_LEVEL} = 'warn';    #set to 'debug' to see what is going on
}

use Test::More qw(no_plan);
use MYDLjE::Config;
use MYDLjE::Plugin::DBIx;
use MYDLjE::M::Content;
isa_ok('MYDLjE::M::Content', 'MYDLjE::M');

can_ok('MYDLjE::M::Content', 'TABLE', 'COLUMNS', 'data', 'sql', 'make_field_attrs');
my $config = MYDLjE::Config->new(files => ["$ENV{MOJO_HOME}/conf/mydlje.$ENV{MOJO_MODE}.yaml"]);

#print Dumper();
my $dbix = MYDLjE::Plugin::DBIx::dbix($config->stash('plugins')->{'MYDLjE::Plugin::DBIx'});

my $alias = 'test-' . time . '-test';
my $data  = {
    user_id     => 1,
    data_type   => 'note',
    data_format => 'html',
    alias       => $alias,
    accepted    => 1
};
my $content = MYDLjE::M::Content->new(%{$data});
$content->body('<p>Hello</p>');
is($content->user_id, 1, 'user_id is ' . $content->user_id);
$content->user_id(2);
is($content->user_id, 2, 'user_id is ' . $content->user_id);

is($content->data_format, 'html',         'data_format is ' . $content->data_format);
is($content->data_type,   'note',         'data_type is ' . $content->data_type);
is($content->body,        '<p>Hello</p>', 'body is ' . $content->body);
is($content->alias,       $alias,         'alias is ' . $alias);

$data->{body}    = $content->body;
$data->{user_id} = $content->user_id;
is_deeply($content->data, $data, 'data is: ' . Dumper($content->data));
is($content->save, 1, '$content->save ok ');

my $id = $content->dbix->last_insert_id(undef, undef, $content->TABLE, 'id');
ok($id, 'new id is:' . $id);

require MYDLjE::M::Content::Note;
my $note = MYDLjE::M::Content::Note->select(id => $id);

is($note->user_id,  $content->user_id, '$note->user_id is ' . $note->user_id);
is($note->alias,    $content->alias,   '$note->alias is ' . $note->alias);
is($note->accepted, undef,             '$note->accepted is undef');

require MYDLjE::M::Content::Question;
my $question = MYDLjE::M::Content::Question->select(id => $id);
is($question->alias, undef, '$question->alias undef ');
is($question->id,    undef, '$question->id undef ');


use_ok('MYDLjE::M::Content::Book');
use_ok('MYDLjE::M::Content::Article');
use_ok('MYDLjE::M::Content::Chapter');
use_ok('MYDLjE::M::Content::Answer');
