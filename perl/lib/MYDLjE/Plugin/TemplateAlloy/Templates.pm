package MYDLjE::Plugin::TemplateAlloy::Templates;
use strict;
use warnings;
use utf8;

1;

__DATA__

@@ not_found.development.html.tt
<html>
  <body>
  <div class="container" style=" border:1px solid red;padding:2px;">
    template.name: <b style="color:red">[% template.name %]</b> 
  </div>
  </body>
</html>

@@ exception.development.html.tt 

<pre>[% $e.message %]</pre>

@@ exception.html.tt

<!DOCTYPE html>
<html>
  <head><title>Server Error</title></head>
  <style>
      body { background-color: #caecf6 }
      #raptor {
        background: url([% c.url_for '/failraptor.png' %]);
        height: 488px;
        left: 50%;
        margin-left: -371px;
        margin-top: -244px;
        position:absolute;
        top: 50%;
        width: 743px;
      }
  </stle>
  <body><div id="raptor"></div></body>
</html>

@@ auth/loginscreen.html.tt

hello from 'DATA' auth/loginscreen.html.tt


@@ loginscreen.html.tt

hello from 'DATA' loginscreen.html.tt



__END__

=
