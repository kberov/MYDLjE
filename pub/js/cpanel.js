function enhance_form() {
  $('form input,form select').each(function() {
    $(this).addClass('ui-state-default')
  });
  $('.help_icon').click(function() {
    $('.help').toggle(200)
  });

  $('form input[type="text"]').addClass('ui-corner-all');

  $('form .buttons button[type="reset"]').button({
    icons: {
      primary: 'ui-icon-close'
    }
  });
  submit_buton = $('form .buttons button[type="submit"]');
  submit_buton.button({
    icons: {
      primary: 'ui-icon-check'
    }
  });
}