package MYDLjE::I18N::de;
use base 'MYDLjE::I18N';
use strict;
use warnings;
use utf8;
use I18N::LangTags::List;
our %Lexicon = (    ##no critic qw(Variables::ProhibitPackageVars)
  _AUTO          => 1,
  login_name     => 'Benutzer',
  login_password => 'Passwort',
  login_name_help =>
    'Bitte den Benutzernamen für MYDLjE::ControlPanel eingeben.',
  login_password_help =>
    'Bitte das Passwort eingeben. Es wird NICHT im Klartext übertragen, selbst ohne Nutzung des HTTPS Protokolles.',
  login_field_error => 'Bitte einen gültigen Wert für das Feld "[_1]" eingeben!',
  session_id_error  => 'Invalid session. Please try again!',
  first_name        => 'Vorname',
  last_name         => 'Nachname',
  list_pages        => 'Liste der Seiten',
  list_questions    => 'Liste der Fragen',
  list_answers      => 'Liste der Antworten',
  list_articles     => 'Liste der Artikel',
  list_notes        => 'Liste der Anmerkungen',
  list_books        => 'Liste der Bücher',
  list_list         => 'Liste beliebiger Inhalt',
  page              => 'Seite',
  book              => 'Buch',
  article           => 'Artikel',
  chapter           => 'Kapitel',
  question          => 'Frage',
  answer            => 'Antwort',
  note              => 'Anmerkung',
  brick             => 'Baustein',
  list_bricks       => 'Bausteine',

  #MYDLjE::M::Content fields
  title       => 'Titel/Name',
  tags        => 'Schlagwörter',
  featured    => 'Featured',
  sorting     => 'Sortierung',
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

  time_created => 'Erstellt',
  tstamp       => 'Geändert',
  body         => 'Content (body)',
  invisible    => 'Unsichtbar',
  language     => 'Sprache',
  group_id     => 'Gruppe',
  protected    => 'Geschützt',
  bad          => 'Bad Content',
  pid          => 'Eltern',
  
  'All types'  => 'Alle Arten',
  'All languages' => 'Alle Sprachen',
  'Notes' => 'Anmerkungen',
  'Domains' => 'Domänen',
  'Pages' => 'Seiten',
  'Content' => 'Inhalt',
  'Accounts' => 'Konten',
  'Another Plugin' => 'Noch ein Plugin',
  'Articles' => 'Artikel',
  'Questions' => 'Fragen',
  'Books' => 'Bücher',
  'Bricks' => 'Bausteine',
  'Users' => 'Benutzer',
  'Groups' => 'Gruppen',
  'Settings' => 'Einstellungen',
  'File' => 'Dateien',
  
  'Domain' => 'Domäne',
  'Description' => 'Beschreibung',
  'Permissions' => 'Zugriff',
  'Record Type' => 'Record Art',
  'Read' => 'Lesen',
  'Write' => 'Schreiben',
  'Execute' => 'Ausführen',
  'Owner' => 'Eigner',
  'Group' => 'Gruppe',
  'Others' => 'Andere',
  'Published' => 'Veröffentlicht',
  'Save' => 'Speichern',
  'Save and close' => 'Speichern und schliessen',
  'Reset' => 'Zurücksetzen',
  'Close' => 'Schliessen',
  
  'not published' => 'nicht veröffentlicht',
  'for review' => 'für Review',
  'published' => 'veröffentlicht',
  
  'Container' => 'Behälter',
  'Link' => 'Link',
  'Regular Record' => 'normaler Eintrag',
  
  

  #TODO: use I18N::LangTags::List better
  bg => I18N::LangTags::List::name('bg'),
  en => I18N::LangTags::List::name('en'),
  ru => I18N::LangTags::List::name('ru'),
  de => I18N::LangTags::List::name('de'),

  domain_help => 'You can manage several domains with just one instance of MYDLjE.'
    . ' Every domain has its own pages. This way you can run several sites using just one Hosting account.',
  default   => 'Domain index-page',
  regular   => 'Regular',
  folder    => 'Ordner',
  page_type => 'Seiten-Typ',
  order_by  => 'Sortiert nach',
  order     => 'Sortiert',

  ASC          => 'Aufsteigend',
  DESC         => 'Absteigend',
  page_id      => 'Seite',
  page_id_help => 'Parent Seite für diesen Eintrag.',

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
  changed_by      => 'Geändert von',
  changed_by_help => 'Who changed this record for the last time?',
  tstamp          => 'Zuletzt geändert um',
  reg_tstamp      => 'Registered on',
  disabled        => 'Gesperrt',
);

1;
