package MYDLjE::I18N::en;
use base 'MYDLjE::I18N';
use strict;
use warnings;
use utf8;
use I18N::LangTags::List;
our %Lexicon = (
  _AUTO          => 1,
  login_name     => 'User',
  login_password => 'Password',
  login_name_help =>
    'Please enter your username for the MYDLjE::ControlPanel application.',
  login_password_help =>
    'Please enter your password. It is NOT transmitted in plain text even if you are not using HTTPS protocol.',
  login_field_error => 'Please enter valid value for the field "[_1]"!',
  session_id_error  => 'Invalid session. Please try again!',
  list_pages        => 'List of pages',
  list_questions    => 'List of questions',
  list_answers      => 'List of answers',
  list_articles     => 'List of articles',
  list_notes        => 'List of notes',
  list_books        => 'List of books',
  page              => 'Page',
  book              => 'Book',
  article           => 'Article',
  chapter           => 'Chapter',
  question          => 'Question',
  answer            => 'Answer',
  note              => 'Note',

  #MYDLjE::M::Content fields
  title        => 'Title/Name',
  tags         => 'Tags',
  featured     => 'Featured',
  sorting      => 'Sorting',
  data_type    => 'Semantic Data Type',
  data_format  => 'Data Format',
  time_created => 'Created on',
  tstamp       => 'Changed on',
  body         => 'Content (body)',
  invisible    => 'Invisible',
  language     => 'Language',
  group_id     => 'Group',
  protected    => 'Protected',
  bad          => 'Bad Content',

  #TODO: use I18N::LangTags::List better
  bg => I18N::LangTags::List::name('bg'),
  en => I18N::LangTags::List::name('en'),
);

1;
