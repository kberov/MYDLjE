package MYDLjE::I18N::bg;
use base 'MYDLjE::I18N';
use strict;
use warnings;
use utf8;

our %Lexicon = (
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
  title        => 'Заглавие/Име',
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
  group_id     => 'Група',
  protected    => 'Защитено',
  bad          => 'Лошо съдържание',

  #TODO: use I18N::LangTags::List better
  bg => 'Български',
  en => 'Английски',

  Site                   => 'Сайт',
  Domains                => 'Домейни',
  Domain                 => 'Домейн',
  Templates              => 'Шаблони',
  Accounts               => 'Сметки',
  Users                  => 'Потребители',
  Groups                 => 'Групи',
  Abilities              => 'Умения',
  System                 => 'Система',
  Settings               => 'Настройки',
  Cache                  => 'Кеш',
  Plugins                => 'Добавки',
  Log                    => 'Отчет',
  'File Management'      => 'Файлове',
  'Personal Preferences' => 'Лични предпочитания',

);

1;
