<?php

  include("config.php");
  include("utils.php");

  $N = 10;

  // Simple password check, really dummy...
  if ( get('password') == $password )
  {
    $id = get('id');
    $git = get('git');
    $platform = get('platform');
    $error = get('error');

    if ( !file_exists("./builds") )
    {
      mkdir("./builds");
    }

    // Create dir + check gits
    if ( $id && $git && $platform )
    {
      // Check if we need to create project
      if ( !file_exists("./builds/$id") )
      {
        mkdir("./builds/$id");

        // Copy config
        copy("./config.php", "./builds/$id/config.php");

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
        $gits[$git] = time();
        arsort($gits);

        // If we are over N delete oldest
        if ( count($gits) > $N )
        {
          while ( count($gits) > $N )
          {
            $val = end($gits);
            $key = key($gits);
            array_pop($gits);

            deleteDir("./builds/$id/$key");
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
          fwrite($file, "$key:$value");
          $first = false;
        }
        fclose($file);
      }
    }

    // Check requirement
    if ( $id && $git && $platform && $error )
    {
      // oops we got an error!
      $to      = $email;
      $subject = "* Error: $id ($git) for $platform";
      $message = "There was an error while compiling $id ($git) for $platform\n\n";
      $message .= $error;
      $headers = "From: $from" . "\r\n" .
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

      $to      = $email;
      $subject = "$id ($git) for $platform successful";
      $message = "$id ($git) for $platform has completed successfully!\n\n";
      $message .= "$url/view.php?id=$id&git=$git&password=$password\n\n";
      $message .= $logContent;
      $headers = "From: $from" . "\r\n" .
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