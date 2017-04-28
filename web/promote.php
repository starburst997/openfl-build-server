<?php

  include("config.php");
  include("utils.php");

  $adminPassword = $password;

  // Simple password check, really dummy...
  if ( get('password') == $password )
  {
    $id = get('id');
    $git = get('git');
    $version = get('version');

    $beta = get('beta');
    $release = get('release');

    // Get default config
    if ( file_exists("./builds/$id/config.php") )
    {
      include("./builds/$id/config.php");
    }

    if ( $beta == '1' )
    {
      // Promote to beta
      if ( !file_exists("./builds/$id/beta") )
      {
        mkdir("./builds/$id/beta");
      }
      else
      {
        deleteDir("./builds/$id/beta");
        mkdir("./builds/$id/beta");
      }

      if ( file_exists("./builds/$id/$git") )
      {
        // Copy everything to beta
        copyDir("./builds/$id/$git", "./builds/$id/beta");

        // Add info.txt
        $gits = loadGit($id);
        foreach ( $gits as $key=>$value )
        {
          if ( $value['git'] == $git )
          {
            $file = fopen("./builds/$id/beta/git.txt", "w") or die("Unable to open file!");
            fwrite($file, $value['git'].":".$value['sort'].":".$value['version']);
            fclose($file);
            break;
          }
        }

        // Redirect
        header("Location: ./view.php?id=$id&beta=1&password=$password");
        die();
      }
    }
    else if ( $release == '1' )
    {
      // Promote beta to release
      if ( file_exists("./builds/$id/beta") )
      {
        $beta = loadLatest($id, "beta");

        if ( !$beta )
        {
          die('Invalid beta');
        }

        if ( !file_exists("./builds/$id/release") )
        {
          mkdir("./builds/$id/release");
        }

        // Add version directory
        if ( !file_exists("./builds/$id/release/".$beta['version']) )
        {
          mkdir("./builds/$id/release/".$beta['version']);
        }
        else
        {
          deleteDir("./builds/$id/release/".$beta['version']);
          mkdir("./builds/$id/release/".$beta['version']);
        }

        // Copy file
        copyDir("./builds/$id/beta", "./builds/$id/release/".$beta['version']);

        // Write git.txt
        if ( !file_exists("./builds/$id/release/git.txt") )
        {
          $file = fopen("./builds/$id/release/git.txt", "w") or die("Unable to open file!");
          fwrite($file, $beta['git'].":".$beta['sort'].":".$beta['version']);
          fclose($file);
        }
        else
        {
          $builds = loadGit("$id/release");
          $builds[] = $beta;

          usort($r, 'sortCustom');

          // Rewrite text file
          $first = true;
          $file = fopen("./builds/$id/release/git.txt", "w") or die("Unable to open file!");
          foreach ($builds as $key => $value)
          {
            if ( !$first ) {
              fwrite($file, "\n");
            }
            fwrite($file, $value['git'].":".$value['sort'].":".$value['version']);
            $first = false;
          }
          fclose($file);
        }

        // Change latest dir
        $builds = loadGit("$id/release");
        $build = $builds[0];

        if ( !file_exists("./builds/$id/release/latest") )
        {
          mkdir("./builds/$id/release/latest");
        }
        else
        {
          deleteDir("./builds/$id/release/latest");
          mkdir("./builds/$id/release/latest");
        }

        copyDir("./builds/$id/beta", "./builds/$id/release/latest", $beta['git']);

        // Redirect
        header("Location: ./view.php?id=$id&release=".$beta['version']."&password=$password");
        die();
      }
    }
  }
  else
  {
    die('ERROR');
  }
?>