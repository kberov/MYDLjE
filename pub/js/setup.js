/**
 * This script is used in index.xhtml to check if the system is operational
 *
 */

function scripts_are_executable() {
  scripts = ['mydlje', 'cpanel', 'site'];
  var errors = 0; var successes = 0;
  for (i in scripts) {

    $.ajax({
      url: scripts[i] + '/hi.html',
      success: function (data, succsess_code, jqXHR) {
        $('#system_check_div div.oks').show('slow');
        $('#system_check_div ul.oks').append('<li>' + scripts[i] + '/hi.html : ' + succsess_code + ', ' + data + '</li>');
        successes++;
        },
      error: function (jqXHR, textStatus, errorThrown) {
        $('#system_check_div div.noks').show('slow');
        $('#system_check_div ul.noks').append('<li>' + scripts[i] + '/hi.html : ' + textStatus + ', ' + errorThrown + '</li>');
        $('#system_check_div div.wrench').show('slow');
        
        if (typeof(errorThrown) != 'object' && errorThrown.match('Internal')) {
          $('#system_check_div ul.wrench').append(
            '<li>Change "' + scripts[i] + '" permissions to 0755 (rwxr-xr-x)' + ' and refresh this page to see the result.</li>');
        } else
        if (typeof(errorThrown)== 'object' && errorThrown.toString().match(/101/) && errors==0 ) {
          $('#system_check_div ul.wrench').append(
            '<li>'+location+' is accesed locally. <br/>' 
            + 'You need first to move/upload the system in a directory served by an Apache server.</li>');
        }

        errors++;
      }
    });
  } //end for (i in scripts){
  if (errors == 0) {
    $('#system_check_h2').prepend('<span class="ui-icon ui-icon-check" style="float: left; margin-right: .3em;"></span>');
  } else {
    $('#system_check_h2').prepend('<span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span>');
  }
} //end function scripts_are_executable()
$(window).load(function () {
  $.ajaxSetup({
    async: false,
    cache: false,
    context: $('#setup').get(),
  });
  // Accordion
  $('#setup').accordion({
    header: 'h2',
    autoHeight: false
  });
  scripts_are_executable()
});
