package MYDLjE::I18N::en;
use base 'MYDLjE::I18N';
use strict;
use warnings;
use utf8;
use I18N::LangTags::List;
our %Lexicon = (    ##no critic qw(Variables::ProhibitPackageVars)
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
  bg        => I18N::LangTags::List::name('bg'),
  en        => I18N::LangTags::List::name('en'),
  default   => 'Domain index-page',
  regular   => 'Regular',
  folder    => 'Folder',
  page_type => 'Page Type',
  note      => 'Note',

  #textile
  page_type_help => 'MYDLjE has different type of pages. ' . "\n\n"
    . 'bq. *Domain-index (home) page* is the enter point to the domain. It is loaded when the URL does not specify a page to load.'
    . $/
    . $/
    . 'bq. In the *regular page* you can put any type of content. MYDLjE traverses the content and shows it depending on its type. '
    . "\n\n"
    . 'bq. The *Folder* is used only to store content records or records from other tables.',

  hidden_help      => 'A Page can be hidden from menus',
  permissions_help => 'Defines who has the right to edit this record. ' . "\n\n"
    . 'The first symbol defines if the record is parent(pid) for other records in the same table, or is a link to other records in the same table, or is just a regular record. When the record is a link to other record in the site will be shown/executed the body of the record to which this record links using the other record identifier(id).'
    . "\n\n"
    . 'The next three symbols define the permissions for the owner of the record. The second triple defines the group permissions. The third triple defines the permissions for the rest of the users.',
  delete_domain_confirm_message =>
    'Are you sure you want to delete domain "[_1]"? This will delete recursively its pages and content too! All will be lost forever!',
  delete_page_confirm_message =>
    'Are you sure you want to delete page "[_1]"? This will delete recursively child pages and content too! All will be lost forever!',
);

1;
