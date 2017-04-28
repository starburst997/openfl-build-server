<?php

  include("config.php");
  include("utils.php");

  include("SensioLabs/AnsiConverter/AnsiToHtmlConverter.php");
  include("SensioLabs/AnsiConverter/Theme/Theme.php");

  use SensioLabs\AnsiConverter\AnsiToHtmlConverter;

  $N = 10;

  $adminPassword = $password;

  // Check IP is valid
  if ( isset($ip) && ($ip != "") )
  {
    if ( getenv('REMOTE_ADDR') != $ip )
    {
      die('Not authorized');
    }
  }

  // Simple password check, really dummy...
  if ( get('password') == $password )
  {
    $id = get('id');
    $git = get('git');
    $version = get('version');
    $platform = get('platform');
    $error = get('error', false);

    if ( !file_exists("./builds") )
    {
      mkdir("./builds");
    }

    // Create dir + check gits
    if ( $id && $git && $platform && $version )
    {
      // Check if we need to create project
      if ( !file_exists("./builds/$id") )
      {
        mkdir("./builds/$id");

        // Copy config
        //copy("./config.php", "./builds/$id/config.php");

        $config = file_get_contents("./config.php");
        $config = str_replace($password, generateRandomString(12), $config);

        $file = fopen("./builds/$id/config.php", "w") or die("Unable to open file!");
        fwrite($file, $config);
        fclose($file);

        // Create git text file
        $file = fopen("./builds/$id/git.txt", "w") or die("Unable to open file!");
        fwrite($file, "");
        fclose($file);
      }

      // Check if git exists
      if ( !file_exists("./builds/$id/$git") )
      {
        mkdir("./builds/$id/$git");

        // Load git text file
        $gits = loadGit($id);

        // Add new git
        $build = array();
        $build['git'] = $git;
        $build['version'] = $version;
        $build['time'] = gmdate("m/d/Y, H:i", time());
        $build['sort'] = time();

        $gits[] = $build;

        // Sort builds
        usort($gits, 'sortCustom');

        // If we are over N delete oldest
        if ( count($gits) > $N )
        {
          while ( count($gits) > $N )
          {
            $build = array_pop($gits);

            deleteDir("./builds/$id/".$build['git']);
          }
        }

        // Rewrite text file
        $first = true;
        $file = fopen("./builds/$id/git.txt", "w") or die("Unable to open file!");
        foreach ($gits as $key => $value)
        {
          if ( !$first ) {
            fwrite($file, "\n");
          }
          fwrite($file, $value['git'].":".$value['sort'].":".$value['version']);
          $first = false;
        }
        fclose($file);
      }
    }

    // Check requirement
    if ( $id && $git && $platform && $error )
    {
      // oops we got an error!
      //$error = str_replace("<br>", "\n", $error);
      //$error = str_replace("<br>", "\r", $error);

      //use SensioLabs\AnsiConverter\AnsiToHtmlConverter;
      $converter = new AnsiToHtmlConverter();
      $html = $converter->convert($error);

      $to      = $email;
      $subject = "* Error: $id ($git) for $platform";
      $message = "<html><body>There was an error while compiling $id ($git) for $platform<br><br><br><pre style=\"font: monospace; background-color: #000000; color: #00FF00;\">";
      $message .= $html;
      $message .= "</pre></body></html>";
      $headers = 'MIME-Version: 1.0' . "\r\n" .
                 'Content-type: text/html; charset=iso-8859-1' . "\r\n" .
                 "From: $from" . "\r\n" .
                 "Reply-To: $from" . "\r\n" .
                 "X-Mailer: PHP/" . phpversion();
      mail($to, $subject, $message, $headers);
    }
    else if ( $id && $git && $platform && isset($_FILES['log']) )
    {
      // Log
      if ( !file_exists("./builds/$id/$git/logs") )
      {
        mkdir("./builds/$id/$git/logs");
      }
      move_uploaded_file($_FILES['log']['tmp_name'], "./builds/$id/$git/logs/$platform.log");

      // Load specific password
      if ( file_exists("./builds/".get('id')."/config.php") )
      {
        include("./builds/".get('id')."/config.php");
      }

      // Usually the log is the last thing, so we can send the email now
      $logContent = file_get_contents("./builds/$id/$git/logs/$platform.log");

      //$logContent = str_replace("<br>", "\n", $logContent);
      //$logContent = str_replace("<br>", "\r", $logContent);

      //use SensioLabs\AnsiConverter\AnsiToHtmlConverter;
      $converter = new AnsiToHtmlConverter();
      $html = $converter->convert($logContent);

      $to      = $email;
      $subject = "$id ($git) for $platform successful";
      $message = "<html><body>$id ($git) for $platform has completed successfully!<br><br><br>";
      $message .= "<a href=\"$url/view.php?id=$id&git=$git&password=".urlencode($password)."\">$url/view.php?id=$id&git=$git&password=".urlencode($password)."</a><br><br><br><pre style=\"font: monospace; background-color: #000000; color: #00FF00;\">";
      $message .= $html;
      $message .= "</pre></body></html>";
      $headers = 'MIME-Version: 1.0' . "\r\n" .
                 'Content-type: text/html; charset=iso-8859-1' . "\r\n" .
                 "From: $from" . "\r\n" .
                 "Reply-To: $from" . "\r\n" .
                 "X-Mailer: PHP/" . phpversion();
      mail($to, $subject, $message, $headers);
    }
    else if ( $id && $git && $platform && isset($_FILES['file']) )
    {
      // Makes sure to delete platform
      deleteDir("./builds/$id/$git/$platform");
      mkdir("./builds/$id/$git/$platform");

      // Save file
      $f = "./builds/$id/$git/$platform/".$_FILES['file']['name'];
      if ( $platform == "windows-cert" )
      {
        $f = "./builds/$id/$git/$platform/$id-$git.cer";
      }

      move_uploaded_file($_FILES['file']['tmp_name'], $f);

      // Special case for some platform
      if ( $platform == "html5" )
      {
        deleteDir("./builds/$id/$git/html5_run");

        // Unzip folder
        $zip = new ZipArchive;
        $res = $zip->open($f);
        if ($res === TRUE) {
          $zip->extractTo("./builds/$id/$git/html5_run/");
          $zip->close();
        } else {
          echo 'Error with unziping!';
        }

        // Copy icon to root
        if ( file_exists("./builds/$id/$git/html5_run/") && file_exists("./builds/$id/$git/html5_run/favicon.png") )
        {
          if ( file_exists("./builds/$id/icon.png") ) {
            unlink("./builds/$id/icon.png");
          }

          copy("./builds/$id/$git/html5_run/favicon.png", "./builds/$id/icon.png");
        }
      }
    }
    else
    {
      echo "Nope";
    }
  }
  else
  {
    die('ERROR');
  }

  // This should be the only output if everything is right!
  echo "1";

?>