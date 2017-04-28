<?php

  function showTime($name) {
    return date ("F d Y H:i:s", filemtime( __DIR__ . "/" . $name ) );
  }
  function showFilesize($name, $decimals = 2) {
    $bytes = filesize( __DIR__ . "/" . $name );

    $sz = 'BKMGTP';
    $factor = floor((strlen($bytes) - 1) / 3);
    return sprintf("%.{$decimals}f", $bytes / pow(1024, $factor)) . " " . @$sz[$factor];
  }

  // Get a var
  function get($name, $check = true)
  {
    $r = "";
    if ( isset($_GET[$name]) )
    {
      $r = $_GET[$name];
    }

    if ( isset($_POST[$name]) )
    {
      $r = $_POST[$name];
    }

    if ( !$check )
    {
      return $r;
    }

    if ( preg_match('/[a-z0-9\-_]+/', $r) )
    {
      return $r;
    }

    return "";
  }

  // Random string generator
  function generateRandomString($length = 10) {
    $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $charactersLength = strlen($characters);
    $randomString = '';
    for ($i = 0; $i < $length; $i++) {
        $randomString .= $characters[rand(0, $charactersLength - 1)];
    }
    return $randomString;
  }

  // Just empty a folder
  function deleteDir($dirPath)
  {
    if (file_exists($dirPath) && is_dir($dirPath)) {
      if (substr($dirPath, strlen($dirPath) - 1, 1) != '/') {
        $dirPath .= '/';
      }
      $files = glob($dirPath . '*', GLOB_MARK);
      foreach ($files as $file) {
        if (is_dir($file)) {
          deleteDir($file);
        } else {
          unlink($file);
        }
      }
      rmdir($dirPath);
    }
  }

  // Load git text
  function loadGit($id)
  {
    $file = fopen("./builds/$id/git.txt", "r") or die('No git.txt found!');

    $size = filesize("./builds/$id/git.txt");

    $r = array();
    if ( $size > 0 )
    {
      $txt = fread($file,$size);

      $array = explode("\n", $txt);
      if ( (count($array) > 0) && ($array[0] != "") )
      {
        foreach ($array as &$value)
        {
          $value = explode(":", $value);

          $build = array();
          $build['git'] = $value[0];
          $build['sort'] = intval($value[1]);
          $build['time'] = gmdate("m/d/Y, H:i", intval($value[1]));

          if ( count($value) > 2 )
          {
            $build['version'] = $value[2];
          }
          else
          {
            $build['version'] = "1.0.0";
          }

          $r[] = $build;
        }
      }

      usort($r, 'sortCustom');
    }

    fclose($file);

    return $r;
  }

  // Sort builds
  function sortCustom($a, $b) {
    return $b['sort'] - $a['sort'];
  }

  // Load latest
  function loadLatest($id, $t = "")
  {
    $builds = null;

    if ( $t == "" )
    {
      $builds = loadGit("$id");
    }
    else
    {
      $builds = loadGit("$id/$t");
    }

    if ( count($builds) > 0 )
    {
      return $builds[0];
    }

    return null;
  }

  // Copy dir
  function copyDir($src,$dst, $remove = "") {
    $dir = opendir($src);
    @mkdir($dst);
    while(false !== ( $file = readdir($dir)) ) {
      if (( $file != '.' ) && ( $file != '..' )) {
        if ( is_dir($src . '/' . $file) ) {
          copyDir($src . '/' . $file,$dst . '/' . $file, $remove);
        }
        else {
          $f = $file;
          if ( $remove != "" )
          {
            $f = str_replace("-$remove", "", $f);
            $f = str_replace("_$remove", "", $f);
            $f = str_replace("$remove", "", $f);
          }
          copy($src . '/' . $file,$dst . '/' . $f);
        }
      }
    }
    closedir($dir);
  }

?>