<?php

  include("config.php");
  include("utils.php");

  if ( get('password') != $password )
  {
    die('No access!');
  }

  $adminPassword = $password;

  // Save cookie
  $cookie_name = "adminPassword";
  $cookie_value = $password;
  setcookie($cookie_name, $cookie_value, time() + (86400 * 30), "/"); // 86400 = 1 day

  // Read dirs
  $dirs = scandir('./builds');
  $builds = array();
  foreach ( $dirs as $key=>$value )
  {
    if ( substr($value, 0, 1) != '.' )
    {
      $build = array();
      $build['name'] = $value;

      if ( file_exists("./builds/$value/icon.png") )
      {
        $build['icon'] = "./builds/$value/icon.png";
      }
      else
      {
        $build['icon'] = "./images/icon.png";
      }

      if ( file_exists("./builds/$value/config.php") )
      {
        include "./builds/$value/config.php";

        $build['password'] = $password;
      }
      else
      {
        $build['password'] = $adminPassword;
      }

      $gits = loadGit($value);

      if ( count($gits) > 0 )
      {
        $b = $gits[0];
        $build['sort'] = $b['sort'];
        $build['time'] = $b['time'];
        $build['git'] = $b['git'];
        $build['version'] = $b['version'];

        $builds[] = $build;
      }
    }
  }

  usort($builds, 'sortCustom');

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

    <title>Builds Server</title>

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

    .versionTitle a {
      text-decoration: none !important;
    }

	</style>
  <script>
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
    m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

    ga('create', '<?php echo $analytics; ?>', 'auto');
    ga('send', 'pageview');

  </script>
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
		<div class="row featurette" style="margin-bottom:80px; margin-top:80px; text-align:center;">

			<div class="versionHeaderContainer">
				<h1>Builds Server</h1>
			</div>
			<br/>
			 <div class="versionEntries">


        <?php $first = true; ?>
        <?php foreach($builds as $key=>$value): ?>

          <?php if ( !$first ) { echo '<HR>'; } ?>
          <div class="versionEntry verticalAlign">
           <div class="col-md-6 col-sm-6 noPadMar versionDesc">
            <p class="versionTitle"><a href="<?php echo "./view.php?id=".$value['name']."&git=".$value['git']."&password=".$value['password']; ?>"><img src="<?php echo $value['icon']; ?>" height="60"/> <?php echo $value['name']; ?></a></p>
           </div>
           <div class="col-md-6 col-sm-6 noPadMar versionBtns">
            <?php echo $value['version']; ?> - <b><?php echo $value['git']; ?></b> (<i><?php echo $value['time']; ?></i>)
           </div>
          </div>

        <?php $first = false; ?>
        <?php endforeach; ?>


			 </div>

		</div>


		<center style="font-size: 1.4em"><a class="btn btn-lg btn-primary" href="mailto:info@failsafegames.com">info@failsafegames.com</a></center>
		<br/><br/><br/>
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
