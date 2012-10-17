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
  session_id_error  => 'Ungültige Sitzung. Bitte nochmals versuchen!',
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
  data_type   => 'Semantischer Typ',
  data_format => 'Daten-Format',
  data_format_help =>

    'MYDLjE Inhalt wird in verschiedenen Formaten gespeichert '
    . '(markup languages): *html*, *text*, *textile*, *markdown*, *pod*, *template*. '
    . 'Das Format bestimmt, wie der Inhalt verarbeitet wird, bevor '
    . 'dieser angezeigt wird. ' . "\n\n"
    . 'bq. HTML: Wird zu gültigem XHTML konvertiert.' . "\n\n"
    . 'bq. TEXT: Wird minimal verarbeitet. Jede neue Zeile ergibt einen neuen Absatz.'
    . "\n\n"
    . 'bq. TEXTILE: Wird durch *textile* verarbeitet '
    . '("Text::Textile":http://search.cpan.org/dist/Text-Textile/). '
    . 'Siehe "examples on Wikipedia":http://en.wikipedia.org/wiki/Textile_%28markup_language%29 '
    . 'und "This reference":http://redcloth.org/hobix.com/textile/.' . "\n\n"
    . 'bq. MARKDOWN: Das ist eine andere populäre Auszeichnungssprache, ähnlich der obigen. '
    . 'Wird durch *markdown* verarbeitet '
    . '("Text::MultiMarkdown":http://search.cpan.org/dist/Text-MultiMarkdown/). '
    . 'Siehe "examples on Wikipedia":http://en.wikipedia.org/wiki/Markdown '
    . ' und "the original syntax":http://daringfireball.net/projects/markdown/syntax/.'
    . "\n\n"
    . 'bq. POD (Plain Old Documentation): Format '
    . 'für die Dokumentation von Perl-Programmen. '
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
  body         => 'Inhalt (body)',
  invisible    => 'Unsichtbar',
  language     => 'Sprache',
  group_id     => 'Gruppe',
  protected    => 'Geschützt',
  deleted => 'Gelöscht',
  bad          => 'Schlechter Inhalt',
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
  'User' => 'Benutzer',
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
  
  'New [_1]' => '[_1] neu erstellen',
  'New [_1] here' => '[_1] hier neu erstellen',
  'Edit [_1]' => '[_1] bearbeiten',
  'Delete [_1]' => '[_1] löschen',
  'Page' => 'Seite',
  'article' => 'Artikel',
  
  'Help' => 'Hilfe',
  
  'Disable [_1]' => '[_1] sperren',
  
  

  #TODO: use I18N::LangTags::List better
  # bg => I18N::LangTags::List::name('bg'),
  bg => 'Bulgarisch',
  # en => I18N::LangTags::List::name('en'),
  en => 'Englisch',
  # ru => I18N::LangTags::List::name('ru'),
  ru => 'Russisch',
  # de => I18N::LangTags::List::name('de'),
  de => 'Deutsch',

  domain_help => 'Mit einer Instanz von MYDLjE können mehrere Domänen verwaltet werden.'
    . ' Jede Domäne hat ihre eigenen Seiten. This way you can run several sites using just one Hosting account.',
  default   => 'Domäne Verzeichnis-Seite',
  regular   => 'Regulär',
  folder    => 'Ordner',
  page_type => 'Seiten-Typ',
  order_by  => 'Sortiert nach',
  order     => 'Sortiert',

  ASC          => 'Aufsteigend',
  DESC         => 'Absteigend',
  page_id      => 'Seite',
  page_id_help => 'Eltern Seite für diesen Eintrag.',

  #textile
  page_type_help => 'MYDLjE hat unterschiedliche Arten von Seiten. ' . "\n\n"
    . 'bq. *Domain-index (home) page* ist die Einstiegsseite des Auftrittes. Diese wird geladen, wenn die URL keine spezifische Seite angibt.'
    . $/
    . $/
    . 'bq. In the *regular page* you can put any type of content. MYDLjE traverses the content and shows it depending on its type. '
    . "\n\n"
    . 'bq. The *Folder* is used only to store content records or records from other tables.',

  hidden => 'versteckt',
  hidden_help      => 'Eine Seite kann von der Anzeige in Menüs versteckt werden',
  permissions_help => 'Definiert, wer die Seite verändern darf. ' . "\n\n"
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
    'Several words about the user from him self. Bis zu 255 Zeichen.',
  created_by => 'Erstellt von',
  created_by_help =>
    'Wer erstellte diesen Benutzer? If this is "guest", the this user registered via the site.',
  changed_by      => 'Geändert von',
  changed_by_help => 'Wer änderte diesen Eintrag zuletzt?',
  tstamp          => 'Zuletzt geändert',
  reg_tstamp      => 'Registriert am',
  disabled        => 'Gesperrt',
);

1;
