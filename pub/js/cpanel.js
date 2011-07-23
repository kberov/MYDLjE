/**
 * Adds jQ UI help icon and functionality to display elements with class "help"
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
  
  $('.label').each(function() {
    var unit = $(this).parent();
    $('label', this).click(function() {
      $('.help', unit ).slideToggle();
      return false;
    });
  });
  $('.label label').css({cursor: 'help'});
  $('.help').addClass('ui-corner-all').prepend('<span class="column ui-icon ui-icon-help"></span>');
  $('form input[type="text"]').addClass('ui-corner-all');
  $('form input[type="password"]').addClass('ui-corner-all');

  $('form .buttons button[type="reset"], form .buttons button.button_close').button({
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
 * Displays a confirmation dialog box when user clicked on a "delete" button.
 * If user clicks "Ok" calls the corresponding delete action with '?confirmed=1' 
 * added to the query string.
 * If user clicks "Cancel" just closes the box.
 * @param String delete_button_class The class of the delete buttons on the page.
 * @return Boolean false Allways cancels the default a href behavior.
 */
function enhance_delete_buttons(delete_button_class){
  $('.' + delete_button_class).click(function(){
    $current_button = $(this);
    $dialog = $('<div id="dialog-modal" title=""></div>');
    $dialog.dialog({
      autoOpen: false,
      height: 200,
      width: 350,
      modal: true,
      buttons: [
        { 
          text: "Ok", click: function() { 
            $dialog.dialog("close");
            location.assign($current_button.attr('href')+'?confirmed=1');
          }
        }, 
        { text: "Cancel", click: function() { $(this).dialog("close"); }} 
      ]
    });
    $dialog.dialog( "option", "title", $(this).attr('title') );
    $dialog.html($('div.modal_message',this).html());
    $dialog.dialog('open');
    return false;
  });
}

/**
  * Onload!
  * Functionality which will be executed on each page when loaded.
  */
$(window).load(function() {
  enhance_form();
  enhance_list_items();
});
