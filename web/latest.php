<?php

  include("config.php");
  include("utils.php");

  $id = get('id');
  $t = get('t');
  if ( $t == '' )
  {
    $t = 'release';
  }

  $l = loadLatest($id, $t);
  $version = 'error';

  if ( $l )
  {
    $version = $l['version'];
  }

?>
{
  "id": "<?php echo $id; ?>",
  "version": "<?php echo $version; ?>",
  "type": "<?php echo $t; ?>"
}