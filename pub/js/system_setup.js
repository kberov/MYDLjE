/**
 * This script is used in index.xhtml to check if the system is operational
 *
 */
var errors = 0;
var alert_icon = '<span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span>';
var ok_icon = '<span class="ui-icon ui-icon-check" style="float: left; margin-right: .3em;"></span>';
function scripts_are_executable() {
  scripts = ['mydlje', 'cpanel', 'site'];
  for (i in scripts) {

    $.ajax({
      url: scripts[i] + '/hi.html',
      success: function (data, succsess_code, jqXHR) {
        $('#system_check_div div.oks').show('slow').delay(100);
        $('#system_check_div div.oks ul.oks').append('<li>' + scripts[i] + '/hi.html : ' + succsess_code + ', ' + data + '</li>');
        successes++;
        },
      error: function (jqXHR, textStatus, errorThrown) {
        $('#system_check_div div.noks').show('slow').delay(100);
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
    $('#system_check_h2').prepend(ok_icon);
  } else {
    $('#system_check_h2').prepend(alert_icon);
  }

  if(errors ==0){
    check_rw();
  }
} //end function scripts_are_executable()

function check_rw() {
  var  urls = ['check_readables','check_writables'];
  var app = 'mydlje';
  for(action in urls) {
    $.ajax({
      url: app + '/'+ urls[action],
      success: function (data, succsess_code, jqXHR) {
        $('#system_check_div div.' + urls[action]).show('slow');
        for(dir in data){
        var ok = data[dir]['ok'];
          $('#system_check_div div.' + urls[action] + ' ul.oks').append(
            '<li ' +(ok == 0 ? ' style="color:red;"' : '') + '>'
            + (ok == 0 ? alert_icon : ok_icon)  
            + urls[action] + ': ' + dir + (ok==0 ? data[dir]['message'] : ' - ok') + '</li>');
        }
      },
      error: function (jqXHR, textStatus, errorThrown) {
        $('#system_check_div div.check_rw' ).show('slow');
        $('#system_check_div ul.noks').append('<li>' + app + '/'+ urls[action] + ' : ' + textStatus + ', ' + errorThrown + '</li>');

      }
    });
  }
}// end function check_rw()
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
  window.setTimeout(scripts_are_executable,2000);

});
