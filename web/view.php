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

    <title>Notessimo 4</title>

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
		<div class="row featurette" style="margin-bottom:80px; margin-top:80px; text-align:center;">

			<div class="versionHeaderContainer">
				<h1>Notessimo 4</h1>
			</div>
			<br/>
			 <div class="versionEntries">

				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_flash.jpg" height="60"> Flash <span class="versionSubtitle" title="<?php echo showTime("flash/Notessimo4.swf"); ?>">(<?php echo showFilesize('flash/Notessimo4.swf'); ?>B)<br/><i>Same file, support both mode</i></span></p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						(Stage3D)
						<div>
						<a class="btn btn-lg btn-primary" href="./flash/direct.html" target="_blank" role="button">800x600</a>
						<a class="btn btn-lg btn-primary" href="./flash/100.html" target="_blank" role="button">100%</a><br/><br/>
						</div>
						(Normal)
						<div>
						<a class="btn btn-lg btn-primary" href="./flash/" target="_blank" role="button">800x600</a>
						<a class="btn btn-lg btn-primary" href="./flash/100_normal.html" target="_blank" role="button">100%</a>
						</div>
					</div>
				 </div>
				 <HR>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_html5.jpg" height="60"> HTML 5 <span class="versionSubtitle" title="<?php echo showTime("html5/Notessimo4.js"); ?>">(<?php echo showFilesize('html5/Notessimo4.zip'); ?>B)</span></p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						<a class="btn btn-lg btn-primary" href="./html5/index.html" target="_blank" role="button">800x600</a>
						<!--<a class="btn btn-lg btn-primary" href="https://www.notessimo.net/pintown_aXmdnNhG/html5/100.html" target="_blank" role="button">HTTPS</a>!-->
						<a class="btn btn-lg btn-primary" href="./html5/100.html" target="_blank" role="button">100%</a>
					 </div>
				 </div>
				 <HR>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_android.jpg" height="60"> Android</p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						<a class="btn btn-lg btn-primary" href="/release_temp/Notessimo4/Notessimo4.apk" role="button" title="<?php echo showTime("../../release_temp/Notessimo4/Notessimo4.apk"); ?>">Download (<?php echo showFilesize('../../release_temp/Notessimo4/Notessimo4.apk'); ?>B)</a>
					 </div>
				 </div>
				 <HR>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_ios.jpg" height="60"> iOS <span class="versionSubtitle"><br/><i>Ask us for signed IPA</i></span></p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						<a class="btn btn-lg btn-primary" href="/release_temp/Notessimo4/Notessimo4.ipa" role="button" title="<?php echo showTime("../../release_temp/Notessimo4/Notessimo4.ipa"); ?>">Download (<?php echo showFilesize('../../release_temp/Notessimo4/Notessimo4.ipa'); ?>B)</a>
					 </div>
				 </div>
				 <HR>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_win.jpg" height="60"> Windows</p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						<a class="btn btn-lg btn-primary" href="./Notessimo4.zip" role="button" title="<?php echo showTime("Notessimo4.zip"); ?>">Download (<?php echo showFilesize('Notessimo4.zip'); ?>B)</a>
					 </div>
				 </div>
				 <HR>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_mac.jpg" height="60"> Mac OS</p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						<a class="btn btn-lg btn-primary" href="./Notessimo4.dmg" role="button" title="<?php echo showTime("Notessimo4.dmg"); ?>">Download (<?php echo showFilesize('Notessimo4.dmg'); ?>B)</a>
					 </div>
				 </div>
				 <HR>
				 <div class="versionEntry verticalAlign">
					 <div class="col-md-6 col-sm-6 noPadMar versionDesc">
						<p class="versionTitle"><img src="images/platform_linux.jpg" height="60"> Linux</p>
					 </div>
					 <div class="col-md-6 col-sm-6 noPadMar versionBtns">
						<a class="btn btn-lg btn-primary" href="./Notessimo4.tar.gz" role="button" title="<?php echo showTime("Notessimo4.tar.gz"); ?>">Download (<?php echo showFilesize('Notessimo4.tar.gz'); ?>B)</a>
					 </div>
				 </div>


			 </div>

		</div>


		<center style="font-size: 1.4em"><a class="btn btn-lg btn-primary" href="mailto:info@failsafegames.com">info@failsafegames.com</a></center>
		<br/><br/><br/>
	</div>


	<!-- FOOTER -->
	<footer class="footer2 container-fluid" style="background-color:#000; color:#FFF; padding:40px;">
		<p class="pull-right"><a class="aRed" href="#">Back to top</a></p>
		<p>&copy; 2014 FailSafe Games</p>
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
