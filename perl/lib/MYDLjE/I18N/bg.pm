package MYDLjE::I18N::bg;
use base 'MYDLjE::I18N';
use strict;
use warnings;
use utf8;

our %Lexicon = (    ##no critic qw(Variables::ProhibitPackageVars)
  _AUTO => 1,

  #cpanel/loginscreen.html.tt
  Login          => 'Вписване',
  Logout         => 'Изход',
  Help           => 'Помощ',
  login_name     => 'Потребител',
  login_password => 'Парола',
  login_name_help =>
    'Моля въведете Вашето потребителско име за приложението MYDLjE::ControlPanel!',
  login_password_help =>
    'Моля въведете Вашата парола. Тя е защитена дори ако не ползвате HTTPS протокола!',
  login_field_error =>
    'Моля въведете валидна стойност за полето "[_1]"!',
  session_id_error =>
    'Невалидна сесия. Моля опитайте отново!',

  #Main left menu items
  #main_left_navigation.html.tt
  Content        => 'Съдържание',
  Pages          => 'Страници',
  Books          => 'Книги',
  Articles       => 'Статии',
  Questions      => 'Въпроси',
  Notes          => 'Бележки',
  'I18N&L10N'    => 'I18N&L10N',
  list_pages     => 'Списък със страници',
  list_questions => 'Списък с questions',
  list_answers   => 'Списък с отговори',
  list_articles  => 'Списък със статии',
  list_notes     => 'Списък с бележки',
  list_books     => 'Списък с книги',
  'New [_1]'     => 'Ново съдържание ([_1])',
  'Edit [_1]'    => 'Редакция на съдържание ([_1])',
  page           => 'Страница',
  book           => 'Книга',
  article        => 'Статия',
  chapter        => 'Глава',
  question       => 'Въпрос',
  answer         => 'Отговор',
  note           => 'Бележка',

  #MYDLjE::M::Content fields
  title => 'Заглавие/Име',
  title_help =>
    'Всяко съдържание в MYDLjE има заглавие. То се показва в тага "title". Възможно е да се показва и като заглавие(таг h1) в тялото на страницата. Когато е заглавие на домейн, по подразбиране се показва в заглавната част на всяка страница',
  alias => 'Псевдоним',
  alias_help =>
    'Псевдонимът е уникален идентификатор за съдържание от даден тип. Обикновено се генерира автоматично. Страниците също имат псевдоними, но те са уникални за домейна на страницата.',
  tags         => 'Етикети',
  featured     => 'Препоръчано',
  sorting      => 'Подредба',
  data_type    => 'Семантичен Тип',
  data_format  => 'Формат на Данните',
  time_created => 'Време на създаване',
  tstamp       => 'Време на Промяна',
  body         => 'Съдържание (тяло)',
  invisible    => 'Невидимо',
  language     => 'Език',
  language_help =>
    'Всеки елемент съдържание се пише на даден език. Изберете езика, на който ще бъде текущото съдържание. '
    . "\n\n"
    . 'За страниците това е езика (по подразбиране) за заглавието и тялото. Една страница може да съдържа елементи на различни езици.',
  group_id  => 'Група',
  protected => 'Защитено',
  bad       => 'Лошо съдържание',

  #TODO: use I18N::LangTags::List better
  bg => 'Български',
  en => 'Английски',

  Site    => 'Сайт',
  Domains => 'Домейни',
  Domain  => 'Домейн',
  domain_help =>
    'В MYDLjE могат да се управляват няколко домейна. Всеки домейн има свои страници. По този начин можете да хоствате няколко "сайта" само с една сметка при някой доставчик на хостинг услуги, като ползвате само една инсталация на MYDLjE.',
  Templates   => 'Шаблони',
  Accounts    => 'Сметки',
  Users       => 'Потребители',
  Groups      => 'Групи',
  Abilities   => 'Умения',
  System      => 'Система',
  Settings    => 'Настройки',
  Cache       => 'Кеш',
  Plugins     => 'Добавки',
  Log         => 'Отчет',
  Files       => 'Файлове',
  Preferences => 'Предпочитания',

  #page_types
  page_type => 'Тип Страница',
  page_type_help =>
    'MYDLjE поддържа различни типове страници. ' . "\n\n"
    . 'bq. *Индексната (начална) страница* е входната точка към домейна. Тя се показва, когато в уеб-адреса не е дефинирана друга страница.'
    . $/
    . $/
    . 'bq. В *обикновената страница* може да слагате всякакъв тип съдържание. MYDLjE обхожда съдържанието и го показва в зависимост от неговия тип. '
    . "\n\n"
    . 'bq. *Папката* служи само за съхранение на записи съдържание или записи от други таблици.',
  default     => 'Страница-индекс на домейн',
  regular     => 'Обикновена',
  folder      => 'Папка',
  description => 'Описание',
  description_help =>
    'Използва се в META-тага "description". Интернет-търсачките го четат при индексиране на сайта.',
  permissions => 'Права',
  permissions_help =>
    'Определя кой има право да редактира записа. '
    . "\n\n"
    . 'Първият символ показва дали записът съдържа други записи в себе си, дали е връзка към други записи в същата таблица, или пък е обикновен запис. Когато записът е връзка към друг запис, в сайта ще се покаже/изпълни тялото на записът, чиито идентификатор(id) е посочен в тялото на записа-връзка.'
    . "\n\n"
    . 'Следващите три символа определят правата на собственика на записа. Втората тройка символи определят правата на групата, на която принадлежи записът. Третата група символи определя правата на всички останали.',
  pid => 'Намира се в',
  pid_help =>
    'Всеки елемент съдържание има родителски елемент от същия вид (в същата таблица), в който се поставя. '
    . 'Така се изгражда гъвкава иерархична структура на сайта.',
  sorting      => 'Подредба',
  sorting_help => '-',
  template     => 'шаблон',
  template_help =>
    'TT2-програмен код за показване на страницата. Използва се шаблона по подразбиране ако нищо не е указано.',
  hidden => 'Скрита',
  hidden_help =>
    'Страницата няма да се показва в списъци и менюта, но може да бъде отваряна ако е публикувана.',
  published        => 'Публикувано',
  'not published'  => 'Не е публикувано',
  'waiting review' => 'Очаква одобрение',
  published_help =>
    'Само *публикувани* страници и съдържание се показват в сайта. ',
  cache => 'Да се кешира',
  cache_help =>
    'Когато съдържанието на една страница не се променя често, няма нужда всеки път, когато се показва в браузъра, да я зареждаме от базата данни и сглобяваме наново. Можем да я запазим в готов вид, като само я показваме на посетителите.',
  expiry => 'Изтича след',
  expiry_help =>
    'Времето в секунди, след което кешът на страницата ще изтече, ако страницата се кешира (по подразбиране - 86400 = 24 часа).',
  body_help =>
    'Главно съдържание. В зависимост от стойността на полето "[_1]", съдържанието се интерпретира по съответния начин.',
  'Record Type'    => 'Тип запис',
  'Regular Record' => 'Обикновен запис',
  Link             => 'Връзка към запис',
  Container        => 'Съдържа други записи',
  delete_domain_confirm_message =>
    'Сигурни ли сте, че искате да изтриете домейна "[_1]"? Това ще изтрие всички страници и съдържание в него! Всичко ще бъде загубено завинаги!',
  delete_page_confirm_message =>
    'Сигурни ли сте, че искате да изтриете страницата "[_1]"? Това ще изтрие също всички под-страници и съдържание в тях! Всичко ще бъде загубено завинаги!',

);

1;
