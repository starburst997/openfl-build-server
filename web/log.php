<?php

  include("config.php");
  include("utils.php");

  $adminPassword = $password;

  $id = get('id');
  $git = get('git');

  if ( $git == '1' )
  {
    // Get latest git
    $gits = loadGit($id);
    $git = key($gits);
  }

  $release = get('release');
  $beta = get('beta');

  if ( file_exists("./builds/$id/config.php") )
  {
    include("./builds/$id/config.php");
  }

  $p = get('password');
  if ( ($p != $password) && ($p != $adminPassword) )
  {
    die('No access!');
  }

  $platform = get('platform');

  if ( file_exists("./builds/$id/$git/logs/$platform.log") )
  {
    $log = file_get_contents("./builds/$id/$git/logs/$platform.log");
    $log = str_replace("\r", "", $log);
  }
  else
  {
    die('No file!');
  }

?>

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Official Website of FailSafe Games">
    <meta name="author" content="">
	  <meta name="keywords" content="flash,game,games,failsafe,notessimo,terminal,sift,heads,stick,rpg,action,html5,ios,android" />
    <link rel="icon" href="favicon.ico">

    <title><?php echo $id; ?> - Log - <?php echo $platform; ?></title>

    <script src="js/ansi_up.js" type="text/javascript"></script>
  </head>

  <body style="background-color: #000000; color: #00FF00">

    <pre id="console"><?php echo $log; ?></pre>

    <script type="text/javascript">

    var cdiv = document.getElementById("console");
    var txt  = cdiv.innerHTML;//.replace(/<br>/g, '');
    var ansi_up = new AnsiUp;
    ansi_up.escape_for_html = false;
    var html = ansi_up.ansi_to_html(txt);

    cdiv.innerHTML = html;
    </script>

  </body>
</html>
