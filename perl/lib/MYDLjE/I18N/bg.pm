package MYDLjE::I18N::bg;
use base 'MYDLjE::I18N';
use strict;
use warnings;
use utf8;

our %Lexicon = (

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

);

1;
