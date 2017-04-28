<?php

  include("config.php");
  include("utils.php");

  $adminPassword = $password;

  $id = get('id');
  $git = get('git');
  $latest = false;

  $release = get('release');
  $beta = get('beta');

  if ( $release == '1' )
  {
    $latest = true;

    $l = loadLatest($id, "release");
    $git = "release/".$l['version'];
  }
  else if ( $release )
  {
    if ( $release == 'latest' )
    {
      $latest == true;
    }

    $git = "release/".$release;
  }

  if ( $beta == '1' )
  {
    $latest = true;
    $git = "beta";
  }

  if ( file_exists("./builds/$id/config.php") )
  {
    include("./builds/$id/config.php");
  }

  $p = get('password');
  if ( ($p != $password) && ($p != $adminPassword) )
  {
    die('No access!');
  }

  // Get latest build
  $latestRelease = null;
  $latestBeta = null;
  $latestGit = null;

  if ( file_exists("./builds/$id/beta") )
  {
    $latestBeta = loadLatest($id, "beta");

    if ( $beta == '1' )
    {
      $time = $latestBeta['sort'];
      $version = $latestBeta['version'];
      $g = $latestBeta['git'];
    }
  }

  if ( file_exists("./builds/$id/release") )
  {
    $latestRelease = loadLatest($id, "release");

    if ( ($release == '1') || ($release == 'latest') )
    {
      $latest = true;
      $time = $latestRelease['sort'];
      $version = $latestRelease['version'];
      $g = $latestRelease['git'];
    }
  }

  $latestGit = loadLatest($id);

  if ( $git == '1' )
  {
    $time = $latestGit['sort'];
    $version = $latestGit['version'];

    $latest = true;
    $git = $latestGit['git'];
  }

  // Get icon
  $icon = "./images/icon.png";
  if ( file_exists("./builds/$id/icon.png") )
  {
    $icon = "./builds/$id/icon.png";
  }

  $builds = array();
  $exists = false;

  // Get time of this release
  if ( $beta )
  {

  }
  else if  ( $release )
  {
    $builds = loadGit($id."/release");

    foreach ( $builds as $key=>$value )
    {
      if ( $value['version'] == $release )
      {
        $time = $value['sort'];
        $version = $value['version'];
        $g = $value['git'];

        if ( $key == 0 ) {
          $latest = true;
        }
      }
    }
  }
  else
  {
    $builds = loadGit($id);

    foreach ( $builds as $key=>$value )
    {
      if ( $value['git'] == $git )
      {
        $time = $value['sort'];
        $version = $value['version'];

        if ( $key == 0 ) {
          $latest = true;
        }
      }
    }
  }

  usort($builds, 'sortCustom');

  if ( file_exists("./builds/$id/$git") )
  {
    $exists = true;

    // Check release
    function getFile($path)
    {
      if ( file_exists($path) )
      {
        $dirs = scandir($path);
        if ( count($dirs) > 2 )
        {
          return $path."/".$dirs[2];
        }
      }
      return null;
    }

    $flash = getFile("builds/$id/$git/flash");
    $android = getFile("builds/$id/$git/android");
    $chrome = getFile("builds/$id/$git/chrome");
    $chromeCrx = getFile("builds/$id/$git/chrome-crx");
    $html5 = getFile("builds/$id/$git/html5");
    $ios = getFile("builds/$id/$git/ios");
    $linux = getFile("builds/$id/$git/linux");
    $mac = getFile("builds/$id/$git/mac");
    $macSetup = getFile("builds/$id/$git/mac-setup");
    $macStore = getFile("builds/$id/$git/mac-store");
    $ubuntu = getFile("builds/$id/$git/ubuntu");
    $windows = getFile("builds/$id/$git/windows");
    $windowsAppx = getFile("builds/$id/$git/windows-appx");
    $windowsHtml5Appx = getFile("builds/$id/$git/windows-html5-appx");
    $windowsSetup = getFile("builds/$id/$git/windows-setup");
    $windowsCert = getFile("builds/$id/$git/windows-cert");

    $html5_run = null;
    if ( file_exists("builds/$id/$git/html5_run") )
    {
      $html5_run = "builds/$id/$git/html5_run/index.html";
    }

    $flash_run = null;
    if ( file_exists("builds/$id/$git/flash_run") )
    {
      $flash_run = "builds/$id/$git/flash_run/index.html";
    }
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

    <title><?php echo $id; ?></title>

	<link href="//fonts.googleapis.com/css?family=Muli:300italic,300,400italic,400" rel="stylesheet" type="text/css">

    <!-- Bootstrap core CSS -->
    <link href="css/bootstrap.css" rel="stylesheet">

    <!-- Just for debugging purposes. Don't actually copy these 2 lines! -->
    <!--[if lt IE 9]><script src="js/ie8-responsive-file-warning.js"></script><![endif]-->
    <script src="js/ie-emulation-modes-warning.js"></script>

    <!-- IE10 viewport hack for Surface/desktop Windows 8 bug -->
    <script src="js/ie10-viewport-bug-workaround.js"></script>

    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->

    <!-- Custom styles for this template -->
    <link href="css/carousel.css" rel="stylesheet">
	<style>
		body{
			font-family:'Muli','Helvetica Neue',Helvetica,Arial,sans-serif;
		}

		#holder {
			min-height: 100%;
			position:relative;
		}

		#pageBody {
			padding-bottom: 100px;
		}

		.footer2{
			bottom: 0;
			height: 100px;
			left: 0;
			position: absolute;
			right: 0;
		}


		.sectionTitle{

			font-size: 50px;
			text-align:center;
			margin-bottom:80px;
			text-transform:uppercase;
		}

		.newsHeading {
			font-size: 38px;
		}

		.gameEntry {

			padding:20px 0px;
			margin:0px;

		}

		.noPadMar{
			padding:0;
			margin:0;
		}

		.imgBW2{
			-webkit-filter: grayscale(100%);
			-moz-filter: grayscale(100%);
			filter: grayscale(100%);
			opacity:0.8;

		}

		.imgBW2:hover{
			-webkit-filter: grayscale(0%);
			-moz-filter: grayscale(0%);
			filter: grayscale(0%);
			-webkit-filter:brightness(100%);
			opacity:1.0;
		}

    .btn {
      margin-top: 2px;
      margin-bottom: 2px;
    }

    .build {
      margin-top: 10px;
      margin-bottom: 10px;
    }

	</style>
  </head>
<!-- NAVBAR
================================================== -->
  <body id="page-top" data-spy="scroll" data-target=".navbar-fixed-top">
    <!-- Navigation -->

	<nav class="navbar navbar-custom navbar-fixed-top top-nav-collapse" role="navigation">
        <div class="container">
            <div class="navbar-header">
                <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
                <span class="sr-only">Toggle navigation</span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
              </button>
                <a class="navbar-brand page-scroll" href="http://www.failsafegames.com/index.html#page-top">
                    <img src="images/logoCollapse2.svg" width="30"> <span class="light">FailSafe</span> Games
                </a>
            </div>

            <!-- Collect the nav links, forms, and other content for toggling -->
            <div class="collapse navbar-collapse navbar-right navbar-main-collapse">
                <ul class="nav navbar-nav">
                    <!-- Hidden li included to remove active class from about link when scrolled up past about section -->
                    <li class="hidden"><a href="#page-top"></a></li>
                    <li><a class="page-scroll" href="http://www.failsafegames.com/index.html#services">Services</a></li>
                    <li><a class="page-scroll" href="http://www.failsafegames.com/index.html#games">Games</a></li>
                    <li><a class="page-scroll" href="http://www.failsafegames.com/index.html#about">About</a></li>
                    <li><a class="page-scroll" href="http://www.failsafegames.com/index.html#contact">Contact</a></li>
                </ul>
            </div>
            <!-- /.navbar-collapse -->
        </div>
        <!-- /.container -->
    </nav>

	<div id="holder">
	<!-- Game Container START -->
	<div id="pageBody" class="container marketing">
		<div class="row featurette" style="margin-bottom:80px; margin-top:30px; text-align:center;">

      <div class="versionEntries">
      <?php if (isset($_COOKIE['adminPassword']) && ($_COOKIE['adminPassword'] == $adminPassword) ): ?>

          <a href="./index.php?password=<?php echo urlencode($adminPassword); ?>">Back to builds</a>

          <?php if ( $beta ): ?>
          <a style="float: right" href="./promote.php?release=1&id=<?php echo $id; ?>&password=<?php echo urlencode($adminPassword); ?>" onclick="return confirm('Are you sure?')">Promote to Release</a>
          <?php elseif ( $git && !$release ): ?>
          <a style="float: right" href="./promote.php?beta=1&id=<?php echo $id; ?>&git=<?php echo $git; ?>&password=<?php echo urlencode($adminPassword); ?>" onclick="return confirm('Are you sure?')">Promote to Beta</a>
          <?php endif; ?>
      <?php endif; ?>
      &nbsp;
      </div>

			<div class="versionHeaderContainer">

        <h1><img src="<?php echo $icon; ?>" height="60"/> <?php echo $id; ?></h1>

        <?php if ( !$exists ): ?>

          <br/><br/><h2>This build is no longer available...</h2>

        <?php elseif ( $release ): ?>

          <h5><?php echo $version.($latest ? ' - latest' : ''); ?> - <b>Release</b> - <?php echo $g; ?> (<i><?php echo gmdate("m/d/Y, H:i", $time); ?></i>)</h5>
          <br/>
          <i>This is a release build, check the bottom of the page for the history</i><br/>
          Or check other builds: <a href="<?php echo './view.php?id='.$id.'&git='.$latestGit['git'].'&password='.$password; ?>">Git</a> / <a href="<?php echo './view.php?id='.$id.'&beta=1&password='.$password; ?>">Beta</a>

        <?php elseif ( $beta ): ?>

          <h5><?php echo $version; ?> - <b>Beta</b> - <?php echo $g; ?> (<i><?php echo gmdate("m/d/Y, H:i", $time); ?></i>)</h5>
          <br/>
          <i>This is a beta build, if all goes well, it should be promoted to release</i><br/>
          Or check other builds: <a href="<?php echo './view.php?id='.$id.'&git='.$latestGit['git'].'&password='.$password; ?>">Git</a> <?php if ($latestRelease): ?>/ <a href="<?php echo './view.php?id='.$id.'&release=latest&password='.$password; ?>">Release</a><?php endif; ?>

        <?php elseif ( $exists ): ?>
          <h5><?php echo $version.($latest ? ' - latest' : ''); ?> - <b><?php echo $git; ?></b> (<i><?php echo gmdate("m/d/Y, H:i", $time); ?></i>)</h5>
          <br/>
          <i>This is an automatic build, check the bottom of the page if this one is broken</i><br/>

          <?php if ( $latestRelease || $latestBeta ): ?>
          Or check manual build: <?php if ($latestBeta): ?><a href="<?php echo './view.php?id='.$id.'&beta=1&password='.$password; ?>">Beta</a><?php endif; ?> <?php if ($latestRelease): ?>/ <a href="<?php echo './view.php?id='.$id.'&release=latest&password='.$password; ?>">Release</a><?php endif; ?>
          <?php endif; ?>

        <?php endif; ?>
			</div>
			<?php if ( $exists ): ?><br/><?php endif; ?>

			 <div class="versionEntries">

         <?php if ( $exists ): ?>

         <?php if ( $flash ): ?>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_flash.jpg" height="60"> Flash <span class="versionSubtitle"><br/><i><a href="<?php echo "./log.php?id=$id&git=$git&platform=flash&password=$password"; ?>" target="_blank">View log</a></i></span></p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						<div>

              <?php if ( $flash_run ): ?>
              <a class="btn btn-lg btn-primary" href="<?php echo $flash_run; ?>" target="_blank" role="button">Run</a><br/>
              <?php endif; ?>

              <?php if ( $flash ): ?>
              <a class="btn btn-lg btn-primary" href="<?php echo $flash; ?>" target="_blank" role="button">ZIP (<?php echo showFilesize($flash); ?>B)</a>
              <?php endif; ?>

            </div>
					</div>
				 </div>
         <?php endif; ?>

         <?php if ( $flash ): ?>
				 <HR>
         <?php endif; ?>

         <?php if ( $html5 ): ?>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_html5.jpg" height="60"> HTML 5 <span class="versionSubtitle"><br/><i><a href="<?php echo "./log.php?id=$id&git=$git&platform=html5&password=$password"; ?>" target="_blank">View log</a></i></span></p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">

            <?php if ( $html5_run ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $html5_run; ?>" target="_blank" role="button">Run</a><br/>
						<?php endif; ?>

            <?php if ( $html5 ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $html5; ?>" target="_blank" role="button">ZIP (<?php echo showFilesize($html5); ?>B)</a><br/>
            <?php endif; ?>

            <?php if ( $chrome ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $chrome; ?>" target="_blank" role="button">Chrome Apps (<?php echo showFilesize($chrome); ?>B)</a><br/>
            <?php endif; ?>

            <?php if ( $chromeCrx ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $chromeCrx; ?>" target="_blank" role="button">Chrome Extension (<?php echo showFilesize($chromeCrx); ?>B)</a>
					  <?php endif; ?>
           </div>
				 </div>
         <?php endif; ?>

				 <?php if ( $html5 ): ?>
         <HR>
         <?php endif; ?>

         <?php if ( $android ): ?>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_android.jpg" height="60"> Android <span class="versionSubtitle"><br/><i><a href="<?php echo "./log.php?id=$id&git=$git&platform=android&password=$password"; ?>" target="_blank">View log</a></i><?php if ( $googlebeta ): ?><br/><i><a href="<?php echo $googlebeta; ?>" target="_blank">Google Play Beta</a></i><?php endif; ?></span></p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						<?php if ( $android ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $android; ?>" role="button" title="">APK (<?php echo showFilesize($android); ?>B)</a>
					  <?php endif; ?>
           </div>
				 </div>
         <?php endif; ?>

         <?php if ( $android ): ?>
         <HR>
         <?php endif; ?>

         <?php if ( $ios ): ?>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_ios.jpg" height="60"> iOS <span class="versionSubtitle"><br/><i><a href="<?php echo "./log.php?id=$id&git=$git&platform=ios&password=$password"; ?>" target="_blank">View log</a></i><?php if ( $testflight ): ?><br/><i><a href="<?php echo $testflight; ?>" target="_blank">TestFlight Beta Signup</a></i><?php endif; ?></span></p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						<?php if ( $ios ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $ios; ?>" role="button" title="">IPA (<?php echo showFilesize($ios); ?>B)</a>
					  <?php endif; ?>
           </div>
				 </div>
         <?php endif; ?>

         <?php if ( $ios ): ?>
         <HR>
         <?php endif; ?>

         <?php if ( $windows ): ?>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_win.jpg" height="60"> Windows <span class="versionSubtitle"><br/><i><a href="<?php echo "./log.php?id=$id&git=$git&platform=windows&password=$password"; ?>" target="_blank">View log</a></i><?php if ( $windowsCert ): ?><br/><i><a href="<?php echo $windowsCert; ?>">Certificate for UWP</a> (<a href="https://docs.microsoft.com/en-us/windows/application-management/sideload-apps-in-windows-10" target="_blank">see</a>)</i><?php endif; ?></span></p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						<?php if ( $windows ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $windows; ?>" role="button" title="">Portable - 32bit (<?php echo showFilesize($windows); ?>B)</a><br/>
            <?php endif; ?>
            <?php if ( $windowsSetup ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $windowsSetup; ?>" role="button" title="">Setup - 32bit (<?php echo showFilesize($windowsSetup); ?>B)</a><br/>
            <?php endif; ?>
            <?php if ( $windowsAppx ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $windowsAppx; ?>" role="button" title="">UWP - 32bit (<?php echo showFilesize($windowsAppx); ?>B)</a><br/>
            <?php endif; ?>
            <?php if ( $windowsHtml5Appx ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $windowsHtml5Appx; ?>" role="button" title="">UWP (HWA) (<?php echo showFilesize($windowsHtml5Appx); ?>B)</a>
					  <?php endif; ?>
           </div>
				 </div>
         <?php endif; ?>

         <?php if ( $windows ): ?>
         <HR>
         <?php endif; ?>

         <?php if ( $mac ): ?>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_mac.jpg" height="60"> Mac OS <span class="versionSubtitle"><br/><i><a href="<?php echo "./log.php?id=$id&git=$git&platform=mac&password=$password"; ?>" target="_blank">View log</a></i></span></p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						<?php if ( $mac ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $mac; ?>" role="button" title="">DMG - 64bit (<?php echo showFilesize($mac); ?>B)</a><br/>
            <?php endif; ?>
            <?php if ( $macSetup ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $macSetup; ?>" role="button" title="">PKG - 64bit (<?php echo showFilesize($macSetup); ?>B)</a><br/>
            <?php endif; ?>
            <?php if ( $macStore ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $macStore; ?>" role="button" title="">PKG - 64bit (Store) (<?php echo showFilesize($macStore); ?>B)</a>
					  <?php endif; ?>
           </div>
				 </div>
         <?php endif; ?>

         <?php if ( $mac ): ?>
         <HR>
         <?php endif; ?>

         <?php if ( $linux ): ?>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_linux.jpg" height="60"> Linux <span class="versionSubtitle"><br/><i><a href="<?php echo "./log.php?id=$id&git=$git&platform=linux&password=$password"; ?>" target="_blank">View log</a></i></span></p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						<?php if ( $ubuntu ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $ubuntu; ?>" role="button" title="">Ubuntu - 64bit (<?php echo showFilesize($ubuntu); ?>B)</a><br/>
            <?php endif; ?>
            <?php if ( $linux ): ?>
            <a class="btn btn-lg btn-primary" href="<?php echo $linux; ?>" role="button" title="">Portable - 64bit (<?php echo showFilesize($linux); ?>B)</a>
					  <?php endif; ?>
           </div>
				 </div>
         <?php endif; ?>


          <HR>
          <?php endif; ?>

        <br/>
        <center><h3>Other Builds</h3></center>
        <br/>

        <?php if ( $latestRelease ): ?>
        <center><h5 class="build"><a href="<?php echo './view.php?id='.$id.'&release=latest&password='.$password; ?>"><b><?php echo $latestRelease['version']; ?> - Release (<?php echo $latestRelease['time']; ?>)</b></a></h5></center>
        <?php endif; ?>
        <?php if ( $latestBeta ): ?>
        <center><h5 class="build"><a href="<?php echo './view.php?id='.$id.'&beta=1&password='.$password; ?>"><b><?php echo $latestBeta['version']; ?> - Beta (<?php echo $latestBeta['time']; ?>)</b></a></h5></center>
        <?php endif; ?>
        <?php if ( $latestGit ): ?>
        <center><h5 class="build"><a href="<?php echo './view.php?id='.$id.'&git='.$latestGit['git'].'&password='.$password; ?>"><b><?php echo $latestGit['version']; ?> - Git (<?php echo $latestGit['time']; ?>)</b></a></h5></center>
        <?php endif; ?>
        <br/>

        <?php if ( $release ): ?>
        <center>- Release -</center>
        <br/>
        <?php elseif ( !$beta ): ?>
        <center>- Git -</center>
        <br/>
        <?php endif; ?>

        <?php $first = true; ?>
        <?php foreach($builds as $key=>$value): ?>
          <?php if ( !$first ) { echo /*'<br/>';*/ ''; } ?>
          <?php if ( $release ): ?>
          <center><h5 class="build"><a href="<?php echo './view.php?id='.$id.'&release='.$value['version'].'&password='.$password; ?>"><?php echo $value['version']; ?> - <?php echo $value['git']; ?> (<?php echo $value['time']; ?>)</a></h5></center>
          <?php else: ?>
          <center><h5 class="build"><a href="<?php echo './view.php?id='.$id.'&git='.$value['git'].'&password='.$password; ?>"><?php echo $value['version']; ?> - <?php echo $value['git']; ?> (<?php echo $value['time']; ?>)</a></h5></center>
          <?php endif; ?>
          <?php $first = false; ?>
        <?php endforeach; ?>

			 </div>

		</div>


		<center style="font-size: 1.4em"><a class="btn btn-lg btn-primary" href="mailto:info@failsafegames.com">info@failsafegames.com</a></center>

    <br/>

    <br/><br/>
	</div>


	<!-- FOOTER -->
	<footer class="footer2 container-fluid" style="background-color:#000; color:#FFF; padding:40px;">
		<p class="pull-right"><a class="aRed" href="#">Back to top</a></p>
		<p>&copy; 2010 - 2017 FailSafe Games</p>
	</footer>
	</div>
    <!-- Bootstrap core JavaScript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>

    <!--<script src="js/bootstrap.min.js"></script>-->
    <script src="js/bootstrap.js"></script>
    <script src="js/docs.min.js"></script>

	<!-- Contact Form -->
	<script src="js/jqBootstrapValidation.js"></script>
	<script src="js/contact_me.js"></script>

	<!-- Plugin JavaScript -->
    <script src="js/jquery.easing.min.js"></script>

    <!-- Custom Theme JavaScript -->
	<script src="js/mobileswipe.js"></script>

	<script type="text/javascript">
		$(function() {

			$('ul.navbar-nav a').bind('click',function(event){
			var $anchor = $(this);
			$('html, body').stop().animate({
				scrollTop: $($anchor.attr('href')).offset().top - 50
				}, 1500,'easeInOutExpo');
				event.preventDefault();
			});

		});
	</script>

  </body>
</html>
