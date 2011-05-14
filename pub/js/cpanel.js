/**
 * Adds jQ UI help icon and functionality to display .help elements
 * for each form separately.
 * Adds jQ UI styling to input and select fields.
 * Adds jQ UI styling to buttons.
 */
function enhance_form() {
  $('form input, form select').each(function() {
    $(this).addClass('ui-state-default')
  });
  $('form').each(function() {
    var form_object = this;
    help_icon = $('<span id="'+ form_object.id+
      '_help" class="legend_icon ui-corner-all"><span class="ui-icon '+
      'ui-icon-help"></span></span>')
        .addClass("ui-state-active")
        .appendTo('#' + form_object.id + ' legend');
    help_icon.click(function() {
      $('.help',form_object).toggle(200)
    });  
  });
  

  $('form input[type="text"]').addClass('ui-corner-all');
  $('form input[type="password"]').addClass('ui-corner-all');

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
} // end function enhance_form()

function enhance_list_items() {
  var list_item = 'ul.items li';
  $(list_item).hover(
    function () {                                
      $(this).removeClass("ui-state-default");
      $(this).addClass("ui-state-hover");
    },
    function () {
      $(this).removeClass("ui-state-hover");
      $(this).addClass("ui-state-default");
    }
  );
}



/**
  * Onload!
  * Functionality which will be executed on each page when loaded.
  */
$(window).load(function() {
  enhance_form();
  enhance_list_items();
});
