/**
 * This script is used in index.xhtml to:
 * - check if the system is operational;
 * - check for readable/writable directories;
 * - enhance the setup form and POST it to mydlje/system_setup
 * - display perl info
 *
 */
i18n_messages = {
  //TODO
};
var errors = 0;
var alert_icon = '<span class="ui-icon ui-icon-alert" style="float: left; margin-right:.3em;"></span>';
var ok_icon = '<span class="ui-icon ui-icon-check" style="float: left; margin-right:.3em;"></span>';

form_fields = ['site_name', 'secret', 'db_driver', 'db_host', 'db_name', 'db_user', 'db_password', 'admin_user', 'admin_email', 'admin_password'];


/**
 * Checks if scripts are executable by making GET requests.
 * In case there are some errors displays the errors in
 * '#system_check_div div.executable_noks ul.noks'
 * and tries to give an advice  in '#system_check_div ul.wrench'
 * on what to do to correct the error.
 * @return void
 */

function scripts_are_executable() {
  scripts = {mydlje: '/hi', cpanel: '/hi', site: '/hi'};
  for (i in scripts) {
    $.ajax({
      url: i + scripts[i],
      success: function(data, succsess_code, jqXHR) {
        $('#system_check_div div.executable_oks').show('slow').delay(100);
        $('#system_check_div div.executable_oks ul.oks').append('<li>' + ok_icon + i + scripts[i] + ': ok, ' + data + '</li>');
        successes++;
      },
      error: function(jqXHR, textStatus, errorThrown) {
        $('#system_check_div div.executable_noks').show('slow').delay(100);
        $('#system_check_div div.executable_noks ul.noks').append('<li>' + alert_icon + i + scripts[i] + ' : ' + textStatus + ', ' + errorThrown + '</li>');
        $('#system_check_div div.wrench').show('slow');
        if (typeof(errorThrown) != 'object' && errorThrown.match('Internal')) {
          $('#system_check_div ul.wrench').append('<li>Change "' + i + '" permissions to 0755( rwxr-xr-x )' + ' and refresh this page to see the result.</li>');
        } else if (typeof(errorThrown) == 'object' && errorThrown.toString().match(/101/) && errors == 0) {
          $('#system_check_div ul.wrench').append('<li>' + location + ' is accesed locally.<br/>' + 'You need first to move/upload the system in a directory served by an Apache server.</li>');
        }
        errors++;
      }
    });
  } //end for (i in scripts)
  if (errors == 0) {
    check_rw();
  } else {
    $('#system_check_div ul.wrench').append('<li>Change "conf" directory permissions so it is readable and writable by Apache.</li>');
  }

} //end function scripts_are_executable()

/**
 * Checks for readable/writable directories.
 * In case there aer some errors marks the errors with red color and
 * tries to give an advice on what to do in
 * '#system_check_div div.check_rw_wrench'.
 */

function check_rw() {
  var urls = ['check_readables', 'check_writables'];
  var app = 'mydlje';
  for (action in urls) {
    $.ajax({
      url: app + '/' + urls[action],
      success: function(data, succsess_code, jqXHR) {
        $('#system_check_div div.' + urls[action]).show('slow');
        for (dir in data) {
          var ok = data[dir]['ok'];

          $('#system_check_div div.' + urls[action] + ' ul.oks').append('<li ' + (ok == 0 ? ' style="color:red;"' : '') + '>' + (ok == 0 ? alert_icon : ok_icon) + dir + ': ' + (ok == 0 ? data[dir]['message'] : 'ok') + '</li>');

          if (ok == 0) {
            $('#system_check_div div.check_rw_wrench').show();
            $('#system_check_div div.check_rw_wrench ol.wrench').append('<li>Change "' + dir + '" permissions so it is ' + (action == 0 ? '<b>readable</b>' : '<b>writable</b>') + ' by the server and refresh this page to see the result.</li>');
          }
        }
      },
      error: function(jqXHR, textStatus, errorThrown) {
        $('#system_check_div div.check_rw').show('slow');
        $('#system_check_div ul.noks').append('<li>' + app + '/' + urls[action] + ' : ' + textStatus + ', ' + errorThrown + '</li>');
      }
    });
  }
} // end function check_rw()

/**
 * Checks for mandatory modules.
 * In case some are missing, invites the user to install them.
 */

function check_modules() {
  $('#check_modules div.check_modules ul.oks').html('')
  $.ajax({
    url: 'mydlje/check_modules',
    success: function(data, succsess_code, jqXHR) {
      $('#check_modules div.check_modules').show('slow');
      for (module in data) {
        var ok = data[module]['ok'];
        $('#check_modules div.check_modules ul.oks').append('<li ' + (ok == 0 ? ' style="color:red;"' : '') + '>' + (ok == 0 ? alert_icon : ok_icon) + module + ': ' + (ok == 0 ? data[module]['message'] : 'ok') + '</li>');
      }
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(textStatus + ': ' + errorThrown.toString())
    }
  });
} //end function check_modules

/**
 * Displays %INC,@INC and %ENV.
 */

function perl_info() {

  $.ajax({
    url: 'mydlje/perl_info',
    success: function(data, succsess_code, jqXHR) {
      info_keys = ['Home', 'MYDLjE', 'Mojolicious', 'Perl', 'PID', 'Name', 'Executable', 'Time'];
      //clean
      $('#perl_info_table tbody').html('<!--cleaned -->');
      for (key in info_keys) {
        $('#perl_info_table tbody').append('<tr><th style="text-align:left">' + info_keys[key] + ': </th><td>' + data[info_keys[key]] + '</td></tr>');
      }
      INCArray = data['@INC'];
      INCHash = data['%INC'];
      INCHashKeys = [];
      INCHashPrinted = {};
      for (module in INCHash) {
        INCHashKeys.push(module);
      }
      INCHashKeys = INCHashKeys.sort();
      //clean
      $('#perl_inc_hash tbody').html('<!--cleaned -->');
      for (path in INCArray) {
        $('#perl_inc_hash tbody').append('<tr><th>&#160;</th></tr>' + '<tr><th>' + INCArray[path] + '</th></tr>')

        for (key in INCHashKeys) {
          if (INCHash[INCHashKeys[key]].match(INCArray[path]) && !INCHashPrinted[INCHashKeys[key]]) {
            $('#perl_inc_hash tbody').append('<tr><td>' + INCHashKeys[key] + '</td></tr>');
            INCHashPrinted[INCHashKeys[key]] = true;
          }
        }
      }
      //clean
      $('#perl_env_hash tbody').html('<!--cleaned -->');
      for (key in data['%ENV']) {
        $('#perl_env_hash tbody').append('<tr><th>' + key + '</th><th>' + data['%ENV'][key] + '</th></tr>');
      }
    },
    error: function(jqXHR, textStatus, errorThrown) {
      //what else could I do?  
      alert(textStatus + ': ' + errorThrown.toString())
    }
  });

}


/**
 * Does a POST request to 'mydlje/system_config' 
 * and fills in error messages under each field.
 */

function post_form() {
  form = $('#system_setup');
  $('body').animate({
    scrollTop: form.offset().top + 'px'
  }, 800);
  fields = $(':input,select option:selected', form);
  $.ajax({
    url: form.attr('action'),
    type: 'POST',
    data: fields.serialize(),
    dataType: 'json',
    //beforeSend: function(jqXHR, settings){$('fieldset').fadeTo('slow', 0.5);},
    success: function(data, succsess_code, jqXHR) {
      //clean up previous errors
      $(form_fields).each(function() {
        $('[name=' + this + ']').removeClass('ui-state-highlight').addClass('ui-state-default');
        $('#' + this + '_error').remove();
      });
      var v_errors = (data['validator_errors']||[]);
      var db_connect = v_errors['db_connect']; //only if all db_* are valid
      $('#db_connect_error').remove();
      if (db_connect != null) {
        $('<div id="db_connect_error" class="ui-state-error ui-corner-all" style="margin:0 1ex 1ex 1ex">' + alert_icon + db_connect + '</div>').appendTo($('#db_connect'));
        delete v_errors['db_connect'];
      }
      for (e in v_errors) {
        $('[name="' + e + '"]').addClass('ui-state-highlight');
        label = $('#' + e + '_label').text();
        label = '"' + label + '"';
        $('<div class="column span-2" style="width:100%;"><div id="' + e + '_error" class="ui-state-error ui-corner-all" style="margin:0 1ex 1ex 1ex">' + alert_icon + v_errors[e].replace(e, label) + '</div></div>').insertAfter($('[name="' + e + '"]').parent().parent());
      }
      if(v_errors.length == 0){
        $('#system_setup').hide('slow');
        $('.system_setup_oks').show('slow');
      }
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(textStatus + ': ' + errorThrown.toString())
    }
  });
  return false;
}

/**
 * Enhances the form with jQuery UI.
 */

function enhance_form() {
  $(form_fields).each(function() {
    $('[name=' + this + ']').addClass('ui-state-default')
  });
  help_icon = $('<span id="get_system_setup' + '_help" class="get_help"><span class="ui-icon ui-icon-help"></span></span>').addClass("ui-corner-all ui-state-active").css({
    display: 'inline-block',
    cursor: 'pointer'
  }).appendTo('#system_setup legend');
  help_icon.click(function() {
    $('.help').toggle(200)
  });

  $('form input[type="text"]').addClass('ui-corner-all');

  $('#system_setup .buttons button[type="reset"]').button({
    icons: {
      primary: 'ui-icon-close'
    }
  });
  submit_buton = $('#system_setup .buttons button[type="submit"]');
  submit_buton.click(post_form);
  submit_buton.button({
    icons: {
      primary: 'ui-icon-check'
    }
  });
}

/**
 * Actions ran onclick on some accordeon headers.
 */

function run_actions(event, ui) {
  //ui.newHeader // jQuery object, activated header
  //ui.oldHeader // jQuery object, previous header
  //ui.newContent // jQuery object, activated content
  //ui.oldContent // jQuery object, previous content
  if (ui.newHeader.attr('id') == 'check_modules_h2') {
    check_modules()
  } else if (ui.newHeader.attr('id') == 'system_check_h2') {
    scripts_are_executable();
  } else if (ui.newHeader.attr('id') == 'perl_info_h2') {
    perl_info()
  }
} // end function run_actions(event, ui)
/**
 * Onload!
 */
$(window).load(function() {
  $.ajaxSetup({
    async: false,
    cache: false,
    context: $('#setup').get()
  });
  // Accordion
  $('#setup').accordion({
    header: 'h2',
    autoHeight: false,
    animated: 'bounceslide',
    collapsible: true,
    active: false
  });
  $('#setup').bind('accordionchange', run_actions);
  //window.setTimeout( scripts_are_executable, 200 );
  enhance_form();
});
