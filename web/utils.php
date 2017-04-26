<?php

  // Get a var
  function get($name)
  {
    if ( isset($_GET[$name]) )
    {
      return $_GET[$name];
    }

    if ( isset($_POST[$name]) )
    {
      return $_POST[$name];
    }

    return "";
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
          $r[$value[0]] = intval($value[1]);
        }
      }

      arsort($r);
    }

    fclose($file);

    return $r;
  }

?>