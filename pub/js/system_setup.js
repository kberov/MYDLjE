/**
* This script is used in index.xhtml to check if the system is operational
*
*/
i18n_messages = {
//TODO
};
var errors = 0; 
var alert_icon = '<span class="ui-icon ui-icon-alert" style="float: left; margin-right:.3em;"></span>'; 
var ok_icon = '<span class="ui-icon ui-icon-check" style="float: left; margin-right:.3em;"></span>'; 
function scripts_are_executable( ) { 
  scripts = [ 'mydlje', 'cpanel', 'site' ]; 
  for( i in scripts ) {
    $.ajax( { 
        url : scripts [ i ] + '/hi', 
        success : function( data, succsess_code, jqXHR ) { 
          $( '#system_check_div div.executable_oks' ).show( 'slow' ).delay( 100 ); 
          $( '#system_check_div div.executable_oks ul.oks' ).append( '<li>' 
            + ok_icon + scripts [ i ] + '/hi: ok, ' + data + '</li>' ); 
          successes ++; 
        }, 
        error : function( jqXHR, textStatus, errorThrown ) { 
          $( '#system_check_div div.executable_noks' ).show( 'slow' ).delay( 100 ); 
          $( '#system_check_div div.executable_noks ul.noks' ).append( '<li>'
           + alert_icon + scripts [ i ] + '/hi.html : ' + textStatus + ', ' + errorThrown + '</li>' ); 
          $( '#system_check_div div.wrench' ).show( 'slow' );
          if( typeof( errorThrown ) != 'object' && errorThrown.match( 'Internal' ) ) { 
            $( '#system_check_div ul.wrench' ).append( 
              '<li>Change "' + scripts [ i ] + '" permissions to 0755( rwxr-xr-x )' + ' and refresh this page to see the result.</li>' ); 
          } else
          if( typeof( errorThrown )== 'object' && errorThrown.toString( ).match( /101/ ) && errors == 0 ) { 
            $( '#system_check_div ul.wrench' ).append( 
              '<li>' + location + ' is accesed locally.<br/>' 
              + 'You need first to move/upload the system in a directory served by an Apache server.</li>' ); 
          } 
          errors ++; 
        }
    } ); 
  } //end for (i in scripts)
  if( errors == 0 ) { 
    check_rw( ); 
  } else { 
    $( '#system_check_div ul.wrench' ).append( 
      '<li>Change "conf" directory permissions so it is readable and writable by Apache.</li>' );
  }

} //end function scripts_are_executable()

function check_rw( ) { 
  var  urls = [ 'check_readables', 'check_writables' ]; 
  var app = 'mydlje'; 
  for( action in urls ) { 
    $.ajax( { 
        url : app + '/' + urls [ action ], 
        success : function( data, succsess_code, jqXHR ) { 
          $( '#system_check_div div.' + urls[ action ] ).show( 'slow' ); 
          for( dir in data ) { 
            var ok = data[ dir ][ 'ok' ]; 
            
              $( '#system_check_div div.' + urls[ action ] + ' ul.oks' ).append( 
                '<li ' +( ok == 0 ? ' style="color:red;"' : '' ) + '>'
                + ( ok == 0 ? alert_icon : ok_icon )  
                + dir + ': ' + ( ok == 0 ? data[ dir ][ 'message' ] : 'ok' ) + '</li>' );
            
            if(ok==0) {
              $( '#system_check_div div.check_rw_wrench').show(  ); 
              $( '#system_check_div div.check_rw_wrench ol.wrench' ).append(
                '<li>Change "' + dir + '" permissions so it is '
                + (action==0 ? '<b>readable</b>' : '<b>writable</b>' ) 
                + ' by the server and refresh this page to see the result.</li>' );
            }
          } 
        }, 
        error : function( jqXHR, textStatus, errorThrown ) { 
          $( '#system_check_div div.check_rw' ).show( 'slow' ); 
          $( '#system_check_div ul.noks' ).append( '<li>' + app + '/' + urls [ action ] + ' : ' + textStatus + ', ' + errorThrown + '</li>' );
        } 
    } ); 
  } 
} // end function check_rw()

function check_modules() {
  $( '#check_modules div.check_modules ul.oks' ).html('')
  $.ajax( { 
    url : 'mydlje/check_modules', 
    success : function( data, succsess_code, jqXHR ) { 
      $( '#check_modules div.check_modules' ).show( 'slow' ); 
      for( module in data ) {
        var ok = data[ module ][ 'ok' ];
        $( '#check_modules div.check_modules ul.oks' ).append( 
          '<li ' +( ok == 0 ? ' style="color:red;"' : '' ) + '>'
          + ( ok == 0 ? alert_icon : ok_icon )  
          + module + ': ' + ( ok == 0 ? data[ module ][ 'message' ] : 'ok' ) + '</li>' );
      }
    }, 
    error : function( jqXHR, textStatus, errorThrown ) {
      alert(textStatus+': '+errorThrown.toString())
    }
  });
}//end function check_modules

function perl_info (){
  

}

function run_actions(event, ui) {
  //ui.newHeader // jQuery object, activated header
  //ui.oldHeader // jQuery object, previous header
  //ui.newContent // jQuery object, activated content
  //ui.oldContent // jQuery object, previous content
  if(ui.newHeader.attr('id')=='check_modules_h2'){
    check_modules()
  }
}// end function run_actions(event, ui)

$( window ).load( function( ) { 
    $.ajaxSetup( { 
        async : false, 
        cache : false, 
        context : $( '#setup' ).get( )
    } ); 
    // Accordion
    $( '#setup' ).accordion( { 
        header : 'h2', 
        autoHeight : false,
        animated: 'bounceslide'
    } ); 
    $('#setup').bind('accordionchange',run_actions);
    window.setTimeout( scripts_are_executable, 2000 );
} ); 
