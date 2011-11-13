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
  first_name        => 'First Name',
  last_name         => 'Last Name',
  list_pages        => 'List of pages',
  list_questions    => 'List of questions',
  list_answers      => 'List of answers',
  list_articles     => 'List of articles',
  list_notes        => 'List of notes',
  list_books        => 'List of books',
  list_list         => 'List of any content',
  page              => 'Page',
  book              => 'Book',
  article           => 'Article',
  chapter           => 'Chapter',
  question          => 'Question',
  answer            => 'Answer',
  note              => 'Note',
  brick             => 'Brick',
  list_bricks       => 'Bricks',

  #MYDLjE::M::Content fields
  title       => 'Title/Name',
  tags        => 'Tags',
  featured    => 'Featured',
  sorting     => 'Sorting',
  data_type   => 'Semantic Type',
  data_format => 'Data Format',
  data_format_help =>

    'MYDLjE content is stored in different text formats '
    . '(markup languages): *html*, *text*, *textile*, *markdown*, *pod*, *template*. '
    . 'The format designates how the content will be processed before '
    . 'being displayed to the site users. ' . "\n\n"
    . 'bq. HTML: Will be converted to valid XHTML and displayed.' . "\n\n"
    . 'bq. TEXT: Will be formatted minimally. Every new line designates a new paragraph.'
    . "\n\n"
    . 'bq. TEXTILE: Will be processed by the *textile* processor '
    . '("Text::Textile":http://search.cpan.org/dist/Text-Textile/). '
    . 'See "examples on Wikipedia":http://en.wikipedia.org/wiki/Textile_%28markup_language%29 '
    . 'and "This reference":http://redcloth.org/hobix.com/textile/.' . "\n\n"
    . 'bq. MARKDOWN: This is another popular text markup, similar to the one above. '
    . 'It will be processed by the *markdown* processor '
    . '("Text::MultiMarkdown":http://search.cpan.org/dist/Text-MultiMarkdown/). '
    . 'See "examples on Wikipedia":http://en.wikipedia.org/wiki/Markdown '
    . ' and "the original syntax":http://daringfireball.net/projects/markdown/syntax/.'
    . "\n\n"
    . 'bq. POD(Plain Old Documentation): Format, '
    . 'for writing documentation for Perl programs. '
    . 'It can be used safely for any type of structured text. '
    . 'See "perlpod":http://perldoc.perl.org/perlpod.html and'
    . ' "the specification":http://perldoc.perl.org/perlpodspec.html.' . "\n\n"
    . 'bq. TEMPLATE(Template::Toolkit): This is a mini-language, '
    . 'used by MYDLjE for its templates. '
    . 'Use this format to write mini-programs directly in the pages. '
    . 'MYDLjE uses the implementation '
    . '"Template::Alloy::TT":http://search.cpan.org/dist/Template-Alloy/lib/Template/Alloy/TT.pm.'
    . ' See also "the original syntax page"'
    . ':http://template-toolkit.org/docs/manual/Syntax.html. '
    . ' To use maximally template features you need to know how MYDLjE works.' . "\n\n",

  time_created => 'Created on',
  tstamp       => 'Changed on',
  body         => 'Content (body)',
  invisible    => 'Invisible',
  language     => 'Language',
  group_id     => 'Group',
  protected    => 'Protected',
  bad          => 'Bad Content',
  pid          => 'Parent',

  #TODO: use I18N::LangTags::List better
  bg => I18N::LangTags::List::name('bg'),
  en => I18N::LangTags::List::name('en'),
  ru => I18N::LangTags::List::name('ru'),

  domain_help => 'You can manage several domains with just one instance of MYDLjE.'
    . ' Every domain has its own pages. This way you can run several sites using just one Hosting account.',
  default   => 'Domain index-page',
  regular   => 'Regular',
  folder    => 'Folder',
  page_type => 'Page Type',
  order_by  => 'Order by',
  order     => 'Order',

  ASC          => 'Ascending',
  DESC         => 'Descending',
  page_id      => 'Page',
  page_id_help => 'Parent page for this record.',

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
  box_help =>
    'Each page in MYDLjE consists of "Boxes". Start typing the name of the box in which you want this element to appear. By default all content elements will be put in the "MAIN_AREA" box.'
    . ' Boxes are defined in "layouts/${DOMAIN.id}/pre_process.tt".',
  in_box => 'in box "[_1]"',
  user_description_help =>
    'Several words about the user from him self. up to 255 symbols.',
  created_by => 'Created by',
  created_by_help =>
    'Who created this user? If this is "guest", the this user registered via the site.',
  changed_by      => 'Changed By',
  changed_by_help => 'Who changed this record for the last time?',
  tstamp          => 'Last change on',
  reg_tstamp      => 'Registered on',
  disabled        => 'Locked',
);

1;
