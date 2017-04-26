package;

import haxe.Http;
import haxe.Json;
import haxe.Timer;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Path;
import haxe.xml.Fast;
import neko.vm.Lock;
import neko.vm.Thread;
import neko.vm.Ui;

import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

import neko.Lib;

import zip.*;

using StringTools;

// Icon definition
typedef Icon =
{
  var name:String;
  var width:Int;
  var height:Int;
};

// Project definition
typedef Project =
{
  var json:ProjectJSON;
  var path:String;
}

// Config JSON, mainly just default values
typedef Config =
{
  var password:String;
  var company:String;
  var website:String;
  var publisher:String;
  var url:String;
}

// Lime Project XML, very basic processing
typedef HXProject = 
{
  var app:HXProjectApp;
  var meta:HXProjectMeta;
  @optional var certificate:HXProjectCertificate;
}
typedef HXProjectApp =
{
  var file:String;
  var main:String;
  var path:String;
}
typedef HXProjectMeta =
{
  var pkg:String;
  var company:String;
  var title:String;
  var version:String;
}
typedef HXProjectCertificate =
{
  var teamID:String;
}

// Project JSON
typedef ProjectJSON = 
{
  // Haxe version
  var haxe:String;
  
  // Project inside project that will get build (folder relative path)
  var projects:Array<ProjectInfo>;
  
  // Library with haxelib version or dev mention
  var libraries:Array<Library>;
  
  // If this is a legacy OpenFL project
  @optional var legacy:Bool;
}

// Project inside project info
typedef ProjectInfo = 
{
  var folder:String;
  
  @optional var website:String;
  @optional var copyright:String;
  @optional var languages:Array<String>;
  
  // Replace commands run with those one
  @optional var win:Array<String>;
  @optional var mac:Array<String>;
  @optional var linux:Array<String>;
}

// Library
typedef Library = 
{
  var name:String;
  var version:String; // Version or "dev" mention
  @optional var folder:String; // Only for dev (we will suppose this is a git repo)
}

// Key vars
typedef Key =
{
  var password:String;
  var alias:String;
  var aliasPassword:String;
  var identity:String;
  var publisher:String;
  var family:String;
}

/**
 * Simple Build Server Script
 */
class Main 
{
  // Constants
  static inline var PROJECTS = 'projects';
  static inline var JSON = 'project.json';
  
  // Var
  static var git:String = '';
  static var cwd:String = '';
  static var projects:Array<Project> = null;
  static var config:Config = null;
  static var oldTrace = haxe.Log.trace;
  
  static var action:String = 'build';
  
  static var fix = false; // Hack
  static var test = 0; // Run tests for debugging
  
	// Starting point
	static function main() 
	{
    // Simple replace of the trace
    haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos)
    {
      if ( Std.is(v, String) )
      {
        var str:String = cast(v, String);
        str = str.replace('\n', '');
        str = str.replace('\r', '');
        Sys.println(str);
      }
    };
    
		// Init
    trace('Simple Build Server for OpenFL');
    trace('You need to have the following installed: git, npm, ruby');
    trace('');
    trace('Install "switchx" to switch between haxe version:');
    trace('    npm install haxeshim -g && npm install switchx -g && switchx');
    trace('Install "fastlane" for easy deploy');
    trace('    gem install fastlane');
    trace('');
    trace('Makes sure you can build on each of the platform');
    trace('WIN: Windows / HTML5');
    trace('MAC: Mac / iOS');
    trace('LINUX: Linux / Android');
    
    separ();
    
    // Check args
    var action = 'build';
    var rel = '.';
    var args = Sys.args();
    if ( args.length > 0 )
    {
      if ( args[0] == 'switch' )
      {
        action = 'switch';
        if ( args.length > 1 ) rel = args[1];
      }
      else if ( args[0] == 'build' )
      {
        action = 'build';
        if ( args.length > 1 ) rel = args[1];
        if ( args.length > 2 ) 
        {
          fix = args[2] == 'fix';
        }
      }
      else if ( args[0] == 'compile' )
      {
        action = 'compile';
        if ( args.length > 1 ) rel = args[1];
        if ( args.length > 2 ) 
        {
          fix = args[2] == 'fix';
        }
      }
      else if ( args[0] == 'test' )
      {
        action = 'build';
        rel = './projects';
        if ( (args.length > 1) && (Std.parseInt(args[1]) > 0) ) test = Std.parseInt(args[1]);
      }
    }
    
    Main.action = action;
    
    // Check CWD
    if ( args.length > 0 )
    {
      var last:String = (new Path(args[args.length-1])).toString();
      var slash = last.substr(-1);
      if (slash=="/"|| slash=="\\") 
        last = last.substr(0,last.length-1);
      if (FileSystem.exists(last) && FileSystem.isDirectory(last)) {
        Sys.setCwd(last);
      }
    }
    
    Sys.setCwd(rel);
    cwd = Sys.getCwd();
    trace('CWD: ${cwd}');
    
    separ();
    
    if ( config == null )
    {
      config = 
      {
        url: 'http://localhost/builds/api.php',
        password: '123456',
        company: 'FailSafe Games',
        website: 'https://www.failsafegames.com/',
        publisher: 'Jean-Denis Boivin'
      };
    }
    
    if ( action == 'compile' )
    {
      var project = getProject('.');
      if ( project != null )
      {
        compileProject( project );
        
        trace('Project compiled!');
      }
      else
      {
        trace('Cannot compile!');
      }
    }
    else if ( action == 'switch' )
    {
      var project = getProject('.');
      if ( project != null )
      {
        switchProject( project );
        
        trace('Project switched!');
      }
      else
      {
        trace('Cannot switch!');
      }
    }
    else
    {
      // Get projects
      projects = getProjects();
      
      // Start loop
      if ( projects.length > 0 )
      {
        if ( fix )
        {
          gitLoop();
        }
        else
        {
          // Create a Thread instead, the program was never being properly quit otherwise
          var t = Thread.create(gitLoop);
          
          //gitLoop();
          
          // We wait for a input from the user (simply hit enter)
          // Couldn't figure out how to "listens" for an interrupt on neko...
          trace('Waiting for enter...');
          var input = Sys.stdin().readInt16();
          trace('All done ${input} ...');
          
          t.sendMessage(666);
        }
      }
      else
      {
        trace('No project found!');
      }
    }
    
    Sys.exit(0);
	}
  
  // Send to server async
  static function sendServer( id:String, platform:String, file:String )
  {
    // Fix?
    Sys.sleep(1);
    
    trace('Sending to server (${platform}): ${file}');
    /*var worker = Thread.create( function()
    {*/
      var password = config.password;
      var url = config.url;
      var h = new Http(url);
      
      h.setParameter('password', password);
      
      h.setParameter('id', id);
      h.setParameter('git', git);
      h.setParameter('platform', platform);
      
      if ( !FileSystem.exists(file) )
      {
        h.setParameter('error', 'File: ${file} not found!');
      }
      else
      {
        var bytes = File.getBytes(file);
        var p = new Path(file);
        h.fileTransfer('file', '${p.file}.${p.ext}', new BytesInput(bytes), bytes.length );
      }
      
      h.onStatus = function( status )
      {
        trace('http status: ${status}');
      };
      
      h.onData = function( data )
      {
        trace('http data: ${data}');
      };
      
      h.onError = function( error )
      {
        trace('http error: ${error}');
      };
      
      h.request( true );
    //} );
  }
  
  // Send to server async
  static function sendError( id:String, platform:String, error:String )
  {
    // Fix?
    Sys.sleep(1);
    
    trace('Sending to server (${platform}): ${id}');
    /*var worker = Thread.create( function()
    {*/
      var password = config.password;
      var url = config.url;
      var h = new Http(url);
      
      h.setParameter('password', password);
      
      h.setParameter('id', id);
      h.setParameter('git', git);
      h.setParameter('platform', platform);
      
      h.setParameter('error', '${error}');
      
      h.onStatus = function( status )
      {
        trace('http status: ${status}');
      };
      
      h.onData = function( data )
      {
        trace('http data: ${data}');
      };
      
      h.onError = function( error )
      {
        trace('http error: ${error}');
      };
      
      h.request( true );
    //} );
  }
  
  // Send to server async
  static function sendLogServer( id:String, platform:String, file:String )
  {
    // Fix?
    Sys.sleep(1);
    
    trace('Sending to server (${platform}): ${file}');
    /*var worker = Thread.create( function()
    {*/
      var password = config.password;
      var url = config.url;
      var h = new Http(url);
      
      h.setParameter('password', password);
      
      h.setParameter('id', id);
      h.setParameter('git', git);
      h.setParameter('platform', platform);
      
      if ( !FileSystem.exists(file) )
      {
        h.setParameter('error', 'Log: ${file} not found!');
      }
      else
      {
        var bytes = File.getBytes(file);
        var p = new Path(file);
        h.fileTransfer('log', '${p.file}.${p.ext}', new BytesInput(bytes), bytes.length );
      }
      
      h.onStatus = function( status )
      {
        trace('http status: ${status}');
      };
      
      h.onData = function( data )
      {
        trace('http data: ${data}');
      };
      
      h.onError = function( error )
      {
        trace('http error: ${error}');
      };
      
      h.request( true );
    //} );
  }
  
  // Just a distinc separation
  static function separ()
  {
    trace('');
    trace('/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*');
    trace('');
  }
  
  // Wait 30sec between each check to see if GIT repo has changes
  static function gitLoop()
  {
    // Now loop every 30sec and check if there was a change to the git
    while ( true )
    {
      if ( Thread.readMessage(false) == 666 )
      {
        trace('Message received!');
        break;
      }
      
      //var l = new Lock();
      
      separ();
      
      trace('Press enter to exit properly...');
      
      separ();
      
      for ( project in projects )
      {
        trace('Checking GIT status for ${project.path}...');
        trace('');
        
        // Get into the CWD
        Sys.setCwd('${cwd}/${project.path}');
        
        call('git fetch');
        
        var head = getCall('git', ['rev-parse', 'HEAD']);
        trace('HEAD: ${head}');
        
        var current = getCall('git', ['rev-parse', '@{u}']);
        trace('Current: ${current}');
        trace('');
        
        // Fix for when current is empty
        if ( current == '' )
        {
          call('git checkout master');
        }
        
        // Trigger if they are different
        if ( (test > 0) || ((head != '') && (current != '') && (head != null) && (current != null) && (head != current)) )
        {
          trace('Start compilation!');
          compileProject( project );
        }
        
        // Only do one project per test
        if ( test != 0 )
        {
          break;
        }
      }
      
      //l.release();
      
      // Wait 30sec...
      //Sys.sleep(1);
      Sys.sleep(30);
      
      if ( test != 0 )
      {
        break;
      }
    }
    
    trace('');
    trace('Done!');
    trace('');
    
    // Trying timer since while loop since to break ctrl+c
    //Sys.sleep(1);
    //Timer.delay(gitLoop, 1000);
    
    //Sys.exit(0);
  }
  
  // Start a command and return the output
  static function call( cmd:String, args:Array<String> = null )
  {
    trace('Calling: ${cmd}');
    
    if ( fix && (Sys.systemName() == 'Windows') )
    {
      // Mainly for debugging....
      Sys.command( cmd, args );
    }
    else
    {
      /*var t = getCall( cmd, args );
      Sys.print( t );
      return t;*/
      
      var p = new Process( cmd, args );
      p.exitCode(true);
      p.close();
    }
    
    return '';
    
    /*var t = getCall( cmd, args );
    Sys.print( t );
    
    return t;*/
    
    /*Sys.command( cmd, args );
    return '';*/
  }
  static function getCall( cmd:String, args:Array<String> = null )
  {
    var p = new Process( cmd, args );
    p.exitCode(true);
    
    var output = p.stdout.readAll().toString();
    //p.kill();
    p.close();
    
    return output;
  }
  
  // Switch environment for this project
  static function switchProject( project:Project )
  {
    // Switch Haxe version
    trace('Switching haxe version to ${project.json.haxe}');
    call('switchx install ${project.json.haxe}');
    call('haxe -version');
    
    separ();
    
    // Set all haxelib versions
    trace('Updating haxelib...');
    trace('');
    
    for ( library in project.json.libraries )
    {
      if ( library.version == 'dev' )
      {
        call('haxelib', ['dev', library.name, library.folder]);
      }
      else
      {
        trace('Set ${library.name} to ${library.version}');
        Sys.command('haxelib set ${library.name} ${library.version} --always');
        Sys.command('haxelib dev ${library.name} --always'); // Makes sure to switch off dev version...
      }
    }
    
    trace('');
    trace('Verifying haxelib...');
    trace('');
    call('haxelib', ['list']);
    
    separ();
  }
  
  // Parse project XML
  static function parseHXProject( path:String )
  {
    if ( FileSystem.exists(path) )
    {
      var content = File.getContent( path );
      var xml = Xml.parse( content );
      var fast = new Fast(xml.firstElement());
      
      var app = fast.node.app;
      var meta = fast.node.meta;
      
      var project:HXProject = 
      {
        app: 
        {
          main: app.att.main,
          path: app.att.path,
          file: app.att.file
        },
        meta:
        {
          title: meta.att.title,
          pkg: meta.att.resolve('package'),
          version: meta.att.version,
          company: meta.att.company
        },
        certificate: null
      };
      
      if ( fast.node.certificate != null )
      {
        project.certificate = 
        {
          teamID: fast.node.certificate.att.resolve('team-id')
        };
      }
      
      return project;
    }
    
    return null;
  }
  
  // Compile a project
  static function compileProject( project:Project )
  {
    var head = getCall('git', ['rev-parse', 'HEAD']);
    var current = '';
    
    if ( (test == 0) && (action == 'build') )
    {
      // Update GIT repo
      trace('Updating GIT repo...');
      trace('');
      
      // Ignore any local changes (dunno why but sometimes in some weird instances I get git 
      // telling me there's some local changes when it isn't true, maybe some LR/CR, permission issue...
      // Anyway, we don't ever change anything in those repo on the machine this code run on, so better be safe!
      call('git reset --hard origin/master');
      
      // Pull
      call('git pull');
      call('git submodule update --init --recursive');
      
      head = getCall('git', ['rev-parse', 'HEAD']);
      current = getCall('git', ['rev-parse', '@{u}']);
      trace('${head} - ${current}');
      
      if ( head != current )
      {
        separ();
        trace('- WARNING: Something wrong with git pull... -');
        separ();
        return;
      }
    }
    
    git = head.substr(0, 7);
    
    separ();
    
    // Update project file
    var newProject = getProject('.');
    project.json = newProject.json;
    
    // Set environment
    switchProject( project );
    
    // Compile projects
    for ( p in project.json.projects )
    {
      // Get into the CWD
      Sys.setCwd('${cwd}/${project.path}/${p.folder}');
      
      trace('* ${p.folder} : ${Sys.getCwd()}...');
      separ();
      
      // Delete Release / Export folder (make sure we don't have old assets)
      if ( test == 0 )
      {
        trace('Removing Release / Export directory...');
        removeDir('Release');
        removeDir('Export'); // Necessary???
        
        createDir('Release');
        createDir('Export');
      }
      
      trace('');
      
      // Get lime project
      var limeProject = parseHXProject('${cwd}/${project.path}/${p.folder}/project.xml');
      
      // Compile based on platform
      switch ( Sys.systemName() )
      {
        case 'Windows':
          trace('Compiling for Windows platform...');
          trace('');
          if ( test != 0 )
          {
            if ( test == 1 ) installerWindows( project, p, limeProject );
            if ( test == 2 ) installerHTML5Windows( project, p, limeProject );
          }
          else 
          {
            if ( p.win != null )
            {
              compile( project, p, limeProject, p.win );
            }
            else
            {
              compileHTML5( project, p, limeProject );
              compileWindows( project, p, limeProject );
            }
          }
        case 'Mac':
          trace('Compiling for Mac platform...');
          trace('');
          if ( test != 0 )
          {
            if ( test == 1 ) installerMac( project, p, limeProject );
          }
          else 
          {
            if ( p.mac != null )
            {
              compile( project, p, limeProject, p.mac );
            }
            else
            {
              compileMac( project, p, limeProject );
              compileIOS( project, p, limeProject );
            }
          }
        case 'Linux':
          trace('Compiling for Linux platform...');
          trace('');
          if ( test != 0 )
          {
            if ( test == 1 ) installerLinux( project, p, limeProject );
          }
          else
          {
            if ( p.linux != null )
            {
              compile( project, p, limeProject, p.linux );
            }
            else
            {
              compileLinux( project, p, limeProject );
              compileAndroid( project, p, limeProject );
            }
          }
      }
      
      separ();
      
      // Only do one project per test
      if ( test != 0 )
      {
        break;
      }
    }
  }
  
  // Get full path from CWD
  static function full( path:String = '' )
  {
    var cwd = Sys.getCwd();
    cwd = cwd.substr(0, cwd.length - 1);
    
    var full = path == '' ? cwd : '${cwd}/${path}';
    return full;
  }
  
  // Windows path
  static function winPath(path:String)
  {
    return path.replace('/', '\\');
  }
  
  // Remove a directory and everything inside
  static function removeDir( path:String )
  {
    if ( FileSystem.exists(path) && FileSystem.isDirectory(path) )
    {
      for ( file in FileSystem.readDirectory(path) )
      {
        if ( FileSystem.isDirectory('${path}/${file}') )
        {
          removeDir('${path}/${file}');
        }
        else
        {
          try
          {
            FileSystem.deleteFile('${path}/${file}');
          }
          catch ( e:Dynamic )
          {
            trace('Could not delete file: ${path}/${file}');
          }
        }
      }
      
      try
      {
        FileSystem.deleteDirectory(path);
      }
      catch ( e:Dynamic )
      {
        trace('Could not delete directory: ${path}');
      }
    }
  }
  static function emptyDir( path:String )
  {
    removeDir( path );
    
    if ( !FileSystem.exists( path ) )
    {
      FileSystem.createDirectory( path );
      trace('Created directory ${path}');
    }
  }
  
  // Zip Folder
  static function zipFolder( path:String )
  {
    if ( FileSystem.exists(path) && FileSystem.isDirectory(path) )
    {
      var zip:ZipWriter = new ZipWriter();
      
      zipAdd( zip, path, path.length + 1 );
      
      return zip.finalize();
    }
    
    return null;
  }
  static function zipAdd( zip:ZipWriter, path:String, skipPath:Int = 0 )
  {
    for ( file in FileSystem.readDirectory(path) )
    {
      var f = '${path}/${file}';
      if ( FileSystem.isDirectory(f) )
      {
        zipAdd( zip, f, skipPath );
      }
      else
      {
        zip.addBytes( File.getBytes(f), f.substr(skipPath), true );
      }
    }
  }
  
  // Add file to release folder
  static function addRelease( bytes:Bytes, name:String )
  {
    if ( bytes != null )
    {
      if ( !FileSystem.exists('Release') )
      {
        FileSystem.createDirectory('Release');
      }
      
      if ( FileSystem.exists('Release/${name}') )
      {
        FileSystem.deleteFile('Release/${name}');
      }
      
      File.saveBytes('Release/${name}', bytes);
    }
    else
    {
      trace('!!! ERROR: empty bytes for ${name}');
    }
  }
  
  // Read KEY
  static function readKey():Key
  {
    // Check for JSON
    var json = 'key.json';
    if ( FileSystem.exists(json) )
    {
      try
      {
        return Json.parse(File.getContent(json));
      }
      catch ( e:Dynamic )
      {
        trace('Error parsing JSON (${json}): ${e}');
        
        return null;
      }
    }
    
    return null;
  }
  
  // Compile custom commands
  static function compile( project:Project, info:ProjectInfo, lime:HXProject, commands:Array<String> )
  {
    for ( command in commands )
    {
      var log = getCall(command);
      
      separ();
      Sys.print(log);
      separ();
    }
  }
  
  // Get log
  static function getLog( path:String )
  {
    Sys.sleep(5); // Making sure we can access the log (also for some weird reason, legacy need some time...)
    
    if ( FileSystem.exists(path) )
    {
      var log = File.getContent(path);
      return log;
    }
    
    return '- Log not found!';
  }
  
  // Makes sure a directory exists
  static function createDir( path:String )
  {
    if ( !FileSystem.exists(path) )
    {
      FileSystem.createDirectory(path);
    }
    
    var dirs = path.split('/');
    var p = '';
    
    for ( dir in dirs )
    {
      p += (p == '' ? '' : '/') + dir;
      if ( !FileSystem.exists(p) )
      {
        FileSystem.createDirectory(p);
      }
    }
  }
  
  // Copy folder
  static function copyFolder( path:String, destination:String )
  {
    if ( FileSystem.exists(path) && FileSystem.isDirectory(path) )
    {
      if ( FileSystem.exists(destination) )
      {
        if ( FileSystem.isDirectory(destination) ) 
        {
          removeDir(destination);
        }
        else
        {
          FileSystem.deleteFile(destination);
        }
      }
      
      FileSystem.createDirectory(destination);
      
      // Alright begin with this copy!
      for ( file in FileSystem.readDirectory(path) )
      {
        if ( FileSystem.isDirectory('${path}/${file}') )
        {
          copyFolder('${path}/${file}', '${destination}/${file}');
        }
        else
        {
          File.saveBytes( '${destination}/${file}', File.getBytes('${path}/${file}') );
        }
      }
    }
  }
  
  // Get program based dir
  static function getPath()
  {
    return new Path(Sys.programPath()).dir;
  }
  
  // Compile HTML5
  static function compileHTML5( project:Project, info:ProjectInfo, lime:HXProject )
  {
    trace("- HTML5 -");
    
    // Compile
    var log:String = '';
    
    if ( project.json.legacy )
    {
      removeDir('Export/html5/bin');
      call('rm -Rf Export/html5');
      
      log = call('haxelib run openfl build html5 -verbose -Dwebgl -minify -yui > Release/html5.log');
    }
    else
    {
      // Weird bug?
      removeDir('Export/html5/final/bin');
      createDir('Export/html5/final/haxe/_generated');
      
      log = call('haxelib run openfl build html5 -verbose -final > Release/html5.log');
    }
    
    log = getLog('Release/html5.log');
    
    separ();
    Sys.print(log);
    separ();
    
    // Package ZIP
    if ( project.json.legacy )
    {
      // Copy Icon as Favicon
      var index:String = File.getContent('Export/html5/bin/index.html');
      index = index.replace('</title>', '<title/>\n<link rel="shortcut icon" type="image/png" href="./favicon.png">');
      FileSystem.deleteFile('Export/html5/bin/index.html');
      File.saveContent('Export/html5/bin/index.html', index);
      
      call('magick convert utils/icon.png -resize 192x192 -crop 192x192+0+0 -strip +repage Export/html5/bin/favicon.png');
      
      copyFolder('Export/html5/bin', 'Release/html5');
    }
    else
    {
      copyFolder('Export/html5/final/bin', 'Release/html5');
    }
    
    addRelease( zipFolder('Release/html5'), '${lime.app.file}-html5-${git}.zip' );
    
    // Add test run
    var html5 = File.getContent('${getPath()}/utils/html5.sh');
    File.saveContent('Release/html5.sh', html5);
    
    // Chrome version
    installerCRX( project, info, lime );
    
    // Send to server
    if ( FileSystem.exists('Release/html5/${lime.app.file}.js') )
    {
      sendServer('${lime.app.file}', 'html5', 'Release/${lime.app.file}-html5-${git}.zip');
      sendLogServer('${lime.app.file}', 'html5', 'Release/html5.log');
    }
    else if ( FileSystem.exists('Release/html5.log') )
    {
      var log = File.getContent('Release/html5.log');
      sendError('${lime.app.file}', 'html5', 'Compile error:\n\n${log}');
    }
    else
    {
      sendError('${lime.app.file}', 'html5', 'Fatal Error: Not even a log output!');
    }
  }
  
  // Compile Windows
  static function compileWindows( project:Project, info:ProjectInfo, lime:HXProject )
  {
    trace("- WINDOWS -");
    
    // Compile
    var log:String = '';
    
    if ( project.json.legacy )
    {
      removeDir('Export/windows/cpp/bin');
      
      log = call('haxelib run openfl build windows -verbose -Dlegacy > Release/windows.log');
    }
    else
    {
      // Weird bug?
      removeDir('Export/windows/cpp/final/bin');
      createDir('Export/windows/cpp/final/haxe/_generated');
      
      log = call('haxelib run openfl build windows -verbose -final > Release/windows.log');
    }
    
    log = getLog('Release/windows.log');
    
    separ();
    Sys.print(log);
    separ();
    
    // Package ZIP
    if ( project.json.legacy )
    {
      copyFolder('Export/windows/cpp/bin', 'Release/windows');
    }
    else
    {
      copyFolder('Export/windows/cpp/final/bin', 'Release/windows');
    }
    
    addRelease( zipFolder('Release/windows'), '${lime.app.file}-windows-${git}.zip' );
    
    // Create installer
    installerWindows( project, info, lime );
    installerHTML5Windows( project, info, lime );
    
    // Send to server
    if ( FileSystem.exists('Release/windows/${lime.app.file}.exe') )
    {
      sendServer('${lime.app.file}', 'windows', 'Release/${lime.app.file}-windows-${git}.zip');
      sendLogServer('${lime.app.file}', 'windows', 'Release/windows.log');
    }
    else if ( FileSystem.exists('Release/windows.log') )
    {
      var log = File.getContent('Release/windows.log');
      sendError('${lime.app.file}', 'windows', 'Compile error:\n\n${log}');
    }
    else
    {
      sendError('${lime.app.file}', 'windows', 'Fatal Error: Not even a log output!');
    }
  }
  
  // Create windows installer
  static function installerWindows( project:Project, info:ProjectInfo, lime:HXProject )
  {
    installerNSIS( project, info, lime );
    installerAPPX( project, info, lime );
  }
  static function installerHTML5Windows( project:Project, info:ProjectInfo, lime:HXProject )
  {
    installerHTML5APPX( project, info, lime );
  }
  static function installerCRX( project:Project, info:ProjectInfo, lime:HXProject )
  {
    // Create installer APPX
    trace('Creating HTML5 CRX installer for windows');
    
    removeDir('Release/html5-crx');
    copyFolder('Release/html5', 'Release/html5-crx');
    
    // Find the first <script> we need to replace
    var html = File.getContent('Release/html5-crx/index.html');
    
    // Fix 1
    var r1 = ~/(<script>\n[^<]*<\/script>)/s;
    if ( r1.match(html) )
    {
      var m = r1.matched(0);
      var n = m.replace('<script>', '').replace('</script>', '');
      
      if ( FileSystem.exists('Release/html5-crx/fix1.js') ) FileSystem.deleteFile('Release/html5-crx/fix1.js');
      File.saveContent('Release/html5-crx/fix1.js', n);
      
      html = html.replace(m, '<script type="text/javascript" src="./fix1.js"></script>');
    }
    
    // Fix 2
    var r2 = ~/(<script type="text\/javascript">\n[^<]*<\/script>)/s;
    if ( r2.match(html) )
    {
      var m = r2.matched(0);
      var n = m.replace('<script type="text/javascript">', '').replace('</script>', '');
      
      if ( FileSystem.exists('Release/html5-crx/fix2.js') ) FileSystem.deleteFile('Release/html5-crx/fix2.js');
      File.saveContent('Release/html5-crx/fix2.js', n);
      
      html = html.replace(m, '<script type="text/javascript" src="./fix2.js"></script>');
    }
    
    FileSystem.deleteFile('Release/html5-crx/index.html');
    File.saveContent('Release/html5-crx/index.html', html);
    
    // Create images
    var squares:Array<Icon> = [
      {name: 'icon_16.png', width: 16, height: 16},
      {name: 'icon_128.png', width: 128, height: 128}
    ];
    
    for ( icon in squares )
    {
      call('magick convert utils/icon.png -resize ${icon.width}x${icon.height} -crop ${icon.width}x${icon.height}+0+0 -strip +repage Release/html5-crx/${icon.name}');
    }
    
    // Manifest
    var manifest = File.getContent('${getPath()}/utils/manifest.json');
    
    manifest = manifest.replace('::PUBLISHER::', '${config.publisher}');
    manifest = manifest.replace('::VERSION::', '${lime.meta.version}');
    manifest = manifest.replace('::NAME::', '${lime.meta.title}');
    manifest = manifest.replace('::FILE::', '${lime.app.file}');
    
    File.saveContent('Release/html5-crx/manifest.json', manifest);
    
    // Main.js
    var main = File.getContent('${getPath()}/utils/main.js');
    
    main = main.replace('::WIDTH::', '800');
    main = main.replace('::HEIGHT::', '600');
    main = main.replace('::FILE::', '${lime.app.file}');
    
    File.saveContent('Release/html5-crx/main.js', main);
    
    // Command
    call('crx pack Release/html5-crx -o Release/${lime.app.file}-${git}.crx -p certificates/key.pem --zip-output Release/${lime.app.file}-chrome-${git}.zip');
    
    // Send server
    sendServer('${lime.app.file}', 'chrome-crx', 'Release/${lime.app.file}-${git}.crx');
    sendServer('${lime.app.file}', 'chrome', 'Release/${lime.app.file}-chrome-${git}.zip');
  }
  static function installerHTML5APPX( project:Project, info:ProjectInfo, lime:HXProject )
  {
    // Create installer APPX
    trace('Creating HTML5 APPX installer for windows');
    
    removeDir('Release/html5-appx');
    copyFolder('Release/html5', 'Release/html5-appx');
    
    FileSystem.createDirectory('Release/html5-appx/uwp');
    
    // Find the first <script> we need to replace
    /*var html = File.getContent('Release/html5-appx/index.html');
    var js = File.getContent('Release/html5-appx/${lime.app.file}.js');
    
    html = html.replace('<script type="text/javascript" src="./${lime.app.file}.js"></script>', '');
    
    // Fix 1
    var r1 = ~/(<script>\n[^<]*<\/script>)/s;
    if ( r1.match(html) )
    {
      var m = r1.matched(0);
      var n = m.replace('<script>', '').replace('</script>', '');
      
      js += '\n' + n;
      
      html = html.replace(m, '');
    }
    
    // Fix 2
    var r2 = ~/(<script type="text\/javascript">\n[^<]*<\/script>)/s;
    if ( r2.match(html) )
    {
      var m = r2.matched(0);
      var n = m.replace('<script type="text/javascript">', '').replace('</script>', '');
      
      js += '\n' + n;
      
      html = html.replace(m, '<script type="text/javascript" src="./${lime.app.file}.js"></script>');
    }
    
    FileSystem.deleteFile('Release/html5-appx/index.html');
    File.saveContent('Release/html5-appx/index.html', html);
    
    FileSystem.deleteFile('Release/html5-appx/${lime.app.file}.js');
    File.saveContent('Release/html5-appx/${lime.app.file}.js', js);*/
    
    // Create images
    var squares:Array<Icon> = [
      {name: 'AppLargeTile.scale-100.png', width: 310, height: 310},
      {name: 'AppLargeTile.scale-125.png', width: 388, height: 388},
      {name: 'AppLargeTile.scale-150.png', width: 465, height: 465},
      {name: 'AppLargeTile.scale-200.png', width: 620, height: 620},
      {name: 'AppLargeTile.scale-400.png', width: 1240, height: 1240},
      {name: 'AppList.scale-100.png', width: 44, height: 44},
      {name: 'AppList.scale-125.png', width: 55, height: 55},
      {name: 'AppList.scale-150.png', width: 66, height: 66},
      {name: 'AppList.scale-200.png', width: 88, height: 88},
      {name: 'AppList.scale-400.png', width: 176, height: 176},
      {name: 'AppList.targetsize-16.png', width: 16, height: 16},
      {name: 'AppList.targetsize-16_altform-unplated.png', width: 16, height: 16},
      {name: 'AppList.targetsize-24.png', width: 24, height: 24},
      {name: 'AppList.targetsize-24_altform-unplated.png', width: 24, height: 24},
      {name: 'AppList.targetsize-256.png', width: 256, height: 256},
      {name: 'AppList.targetsize-256_altform-unplated.png', width: 256, height: 256},
      {name: 'AppList.targetsize-32.png', width: 32, height: 32},
      {name: 'AppList.targetsize-32_altform-unplated.png', width: 32, height: 32},
      {name: 'AppList.targetsize-48.png', width: 48, height: 48},
      {name: 'AppList.targetsize-48_altform-unplated.png', width: 48, height: 48},
      {name: 'AppMedTile.scale-100.png', width: 150, height: 150},
      {name: 'AppMedTile.scale-125.png', width: 188, height: 188},
      {name: 'AppMedTile.scale-150.png', width: 225, height: 225},
      {name: 'AppMedTile.scale-200.png', width: 300, height: 300},
      {name: 'AppMedTile.scale-400.png', width: 600, height: 600},
      {name: 'AppSmallTile.scale-100.png', width: 71, height: 71},
      {name: 'AppSmallTile.scale-125.png', width: 89, height: 89},
      {name: 'AppSmallTile.scale-150.png', width: 107, height: 107},
      {name: 'AppSmallTile.scale-200.png', width: 142, height: 142},
      {name: 'AppSmallTile.scale-400.png', width: 284, height: 284},
      {name: 'AppStoreLogo.scale-100.png', width: 50, height: 50},
      {name: 'AppStoreLogo.scale-125.png', width: 63, height: 63},
      {name: 'AppStoreLogo.scale-150.png', width: 75, height: 75},
      {name: 'AppStoreLogo.scale-200.png', width: 100, height: 100},
      {name: 'AppStoreLogo.scale-400.png', width: 200, height: 200},
    ];
    var wides:Array<Icon> = [
      {name: 'AppWideTile.scale-100.png', width: 310, height: 150},
      {name: 'AppWideTile.scale-125.png', width: 388, height: 188},
      {name: 'AppWideTile.scale-150.png', width: 465, height: 225},
      {name: 'AppWideTile.scale-200.png', width: 620, height: 300},
      {name: 'AppWideTile.scale-400.png', width: 1240, height: 600}
    ];
    
    for ( icon in squares )
    {
      call('magick convert utils/icon.png -resize ${icon.width}x${icon.height} -crop ${icon.width}x${icon.height}+0+0 -strip +repage Release/html5-appx/uwp/${icon.name}');
    }
    for ( icon in wides )
    {
      call('magick convert utils/wide.png -resize ${icon.width}x${icon.height} -crop ${icon.width}x${icon.height}+0+0 -strip +repage Release/html5-appx/uwp/${icon.name}');
    }
    
    // Create script
    var year = Date.now().getFullYear();
    var appx = File.getContent('${getPath()}/utils/AppxManifest-html5.xml');
    
    var key = readKey();
    appx = appx.replace('::KEY_IDENTITY::', '${key.identity}');
    appx = appx.replace('::KEY_PUBLISHER::', '${key.publisher}');
    appx = appx.replace('::KEY_FAMILY::', '${key.family}');
    
    appx = appx.replace('::PUBLISHER::', '${config.publisher}');
    appx = appx.replace('::VERSION::', '${lime.meta.version}.0');
    appx = appx.replace('::NAME::', '${lime.meta.title}');
    appx = appx.replace('::FILE::', '${lime.app.file}');
    
    // Save script
    File.saveContent('Release/html5-appx/AppxManifest.xml', appx);
    
    // Run script
    // Reaaallllyyyyy weeeird!!!! I get security errors when running makepri...... dunno why on getImageData....
    /*Sys.setCwd('${cwd}/${project.path}/${info.folder}/Release/html5-appx');
    
    if ( FileSystem.exists('priconfig.xml') ) FileSystem.deleteFile('priconfig.xml');
    if ( FileSystem.exists('resources.pri') ) FileSystem.deleteFile('resources.pri');
    if ( FileSystem.exists('resources.scale-125.pri') ) FileSystem.deleteFile('resources.scale-125.pri');
    if ( FileSystem.exists('resources.scale-150.pri') ) FileSystem.deleteFile('resources.scale-150.pri');
    if ( FileSystem.exists('resources.scale-200.pri') ) FileSystem.deleteFile('resources.scale-200.pri');
    if ( FileSystem.exists('resources.scale-400.pri') ) FileSystem.deleteFile('resources.scale-400.pri');
    
    call('makepri createconfig /cf priconfig.xml /dq en-US');
    call('makepri new /pr ${winPath(full())} /cf ${winPath(full("priconfig.xml"))}');
    
    if ( FileSystem.exists('priconfig.xml') ) FileSystem.deleteFile('priconfig.xml');
    
    Sys.setCwd('${cwd}/${project.path}/${info.folder}');*/
    
    if ( FileSystem.exists('Release/${lime.app.file}-html5-${git}.appx') ) FileSystem.deleteFile('Release/${lime.app.file}-html5-${git}.appx');
    Sys.command('MakeAppx.exe pack /l /d Release/html5-appx /p Release/${lime.app.file}-html5-${git}.appx');
    Sys.command('signtool.exe sign -f certificates/my.pfx -fd SHA256 -v Release/${lime.app.file}-html5-${git}.appx');
    
    // Send to server
    sendServer('${lime.app.file}', 'windows-html5-appx', 'Release/${lime.app.file}-html5-${git}.appx');
  }
  static function installerAPPX( project:Project, info:ProjectInfo, lime:HXProject )
  {
    // Create installer APPX
    trace('Creating APPX installer for windows');
    
    if ( FileSystem.exists('Release/windows/AppxManifest.xml') )
    {
      FileSystem.deleteFile('Release/windows/AppxManifest.xml');
    }
    
    emptyDir('Release/windows/uwp');
    
    // Create images
    var squares:Array<Icon> = [
      {name: 'AppLargeTile.scale-100.png', width: 310, height: 310},
      {name: 'AppLargeTile.scale-125.png', width: 388, height: 388},
      {name: 'AppLargeTile.scale-150.png', width: 465, height: 465},
      {name: 'AppLargeTile.scale-200.png', width: 620, height: 620},
      {name: 'AppLargeTile.scale-400.png', width: 1240, height: 1240},
      {name: 'AppList.scale-100.png', width: 44, height: 44},
      {name: 'AppList.scale-125.png', width: 55, height: 55},
      {name: 'AppList.scale-150.png', width: 66, height: 66},
      {name: 'AppList.scale-200.png', width: 88, height: 88},
      {name: 'AppList.scale-400.png', width: 176, height: 176},
      {name: 'AppList.targetsize-16.png', width: 16, height: 16},
      {name: 'AppList.targetsize-16_altform-unplated.png', width: 16, height: 16},
      {name: 'AppList.targetsize-24.png', width: 24, height: 24},
      {name: 'AppList.targetsize-24_altform-unplated.png', width: 24, height: 24},
      {name: 'AppList.targetsize-256.png', width: 256, height: 256},
      {name: 'AppList.targetsize-256_altform-unplated.png', width: 256, height: 256},
      {name: 'AppList.targetsize-32.png', width: 32, height: 32},
      {name: 'AppList.targetsize-32_altform-unplated.png', width: 32, height: 32},
      {name: 'AppList.targetsize-48.png', width: 48, height: 48},
      {name: 'AppList.targetsize-48_altform-unplated.png', width: 48, height: 48},
      {name: 'AppMedTile.scale-100.png', width: 150, height: 150},
      {name: 'AppMedTile.scale-125.png', width: 188, height: 188},
      {name: 'AppMedTile.scale-150.png', width: 225, height: 225},
      {name: 'AppMedTile.scale-200.png', width: 300, height: 300},
      {name: 'AppMedTile.scale-400.png', width: 600, height: 600},
      {name: 'AppSmallTile.scale-100.png', width: 71, height: 71},
      {name: 'AppSmallTile.scale-125.png', width: 89, height: 89},
      {name: 'AppSmallTile.scale-150.png', width: 107, height: 107},
      {name: 'AppSmallTile.scale-200.png', width: 142, height: 142},
      {name: 'AppSmallTile.scale-400.png', width: 284, height: 284},
      {name: 'AppStoreLogo.scale-100.png', width: 50, height: 50},
      {name: 'AppStoreLogo.scale-125.png', width: 63, height: 63},
      {name: 'AppStoreLogo.scale-150.png', width: 75, height: 75},
      {name: 'AppStoreLogo.scale-200.png', width: 100, height: 100},
      {name: 'AppStoreLogo.scale-400.png', width: 200, height: 200},
    ];
    var wides:Array<Icon> = [
      {name: 'AppWideTile.scale-100.png', width: 310, height: 150},
      {name: 'AppWideTile.scale-125.png', width: 388, height: 188},
      {name: 'AppWideTile.scale-150.png', width: 465, height: 225},
      {name: 'AppWideTile.scale-200.png', width: 620, height: 300},
      {name: 'AppWideTile.scale-400.png', width: 1240, height: 600}
    ];
    
    for ( icon in squares )
    {
      call('magick convert utils/icon.png -resize ${icon.width}x${icon.height} -crop ${icon.width}x${icon.height}+0+0 -strip +repage Release/windows/uwp/${icon.name}');
    }
    for ( icon in wides )
    {
      call('magick convert utils/wide.png -resize ${icon.width}x${icon.height} -crop ${icon.width}x${icon.height}+0+0 -strip +repage Release/windows/uwp/${icon.name}');
    }
    
    // Create script
    var appx = File.getContent('${getPath()}/utils/AppxManifest.xml');
    
    var key = readKey();
    if ( key != null )
    {
      appx = appx.replace('::KEY_IDENTITY::', '${key.identity}');
      appx = appx.replace('::KEY_PUBLISHER::', '${key.publisher}');
      appx = appx.replace('::KEY_FAMILY::', '${key.family}');
    }
    else
    {
      appx = appx.replace('::KEY_IDENTITY::', 'TEST');
      appx = appx.replace('::KEY_PUBLISHER::', 'CN=TEST');
      appx = appx.replace('::KEY_FAMILY::', 'TEST');
    }
    
    appx = appx.replace('::PUBLISHER::', '${config.publisher}');
    appx = appx.replace('::VERSION::', '${lime.meta.version}.0');
    appx = appx.replace('::NAME::', '${lime.meta.title}');
    appx = appx.replace('::FILE::', '${lime.app.file}');
    
    // Save script
    File.saveContent('Release/windows/AppxManifest.xml', appx);
    
    // Run script
    Sys.setCwd('${cwd}/${project.path}/${info.folder}/Release/windows');
    
    if ( FileSystem.exists('priconfig.xml') ) FileSystem.deleteFile('priconfig.xml');
    if ( FileSystem.exists('resources.pri') ) FileSystem.deleteFile('resources.pri');
    if ( FileSystem.exists('resources.scale-125.pri') ) FileSystem.deleteFile('resources.scale-125.pri');
    if ( FileSystem.exists('resources.scale-150.pri') ) FileSystem.deleteFile('resources.scale-150.pri');
    if ( FileSystem.exists('resources.scale-200.pri') ) FileSystem.deleteFile('resources.scale-200.pri');
    if ( FileSystem.exists('resources.scale-400.pri') ) FileSystem.deleteFile('resources.scale-400.pri');
    
    call('makepri createconfig /cf priconfig.xml /dq en-US');
    call('makepri new /pr ${winPath(full())} /cf ${winPath(full("priconfig.xml"))}');
    
    if ( FileSystem.exists('priconfig.xml') ) FileSystem.deleteFile('priconfig.xml');
    
    Sys.setCwd('${cwd}/${project.path}/${info.folder}');
    
    if ( FileSystem.exists('Release/${lime.app.file}-${git}.appx') ) FileSystem.deleteFile('Release/${lime.app.file}-${git}.appx');
    Sys.command('MakeAppx.exe pack /l /d Release/windows /p Release/${lime.app.file}-${git}.appx');
    Sys.command('signtool.exe sign -f certificates/my.pfx -fd SHA256 -v Release/${lime.app.file}-${git}.appx');
    
    // Send to server
    sendServer('${lime.app.file}', 'windows-cert', 'certificates/my.cer');
    sendServer('${lime.app.file}', 'windows-appx', 'Release/${lime.app.file}-${git}.appx');
  }
  static function unixPath( path:String )
  {
    return path.replace('\\', '/'); 
  }
  static function installerNSIS( project:Project, info:ProjectInfo, lime:HXProject )
  {
    // Create installer NSIS
    trace('Creating NSIS installer for windows');
    
    if ( FileSystem.exists('Release/installer.nsi') )
    {
      FileSystem.deleteFile('Release/installer.nsi');
    }
    
    // Use windows backslash
    var year = Date.now().getFullYear();
    var nsis = File.getContent('${getPath()}/utils/installer.nsi');
    nsis = nsis.replace('::GIT::', '${git}');
    nsis = nsis.replace('::NAME::', '${lime.meta.title}');
    nsis = nsis.replace('::COMPANY::', '${lime.meta.company}');
    nsis = nsis.replace('::WEBSITE::', '${info.website == null ? config.website : info.website}');
    nsis = nsis.replace('::VERSION::', '${lime.meta.version}.0');
    nsis = nsis.replace('::COPYRIGHT::', '${info.copyright == null ? "Copyright "+year+" - "+config.company : info.copyright}');
    nsis = nsis.replace('::FILE::', '${lime.app.file}');
    nsis = nsis.replace('::RELEASE_PATH::', '${winPath(Sys.getCwd()+"Release")}');
    
    nsis = nsis.replace('::BANNER::', '${winPath(Sys.getCwd()+"utils/installer.bmp")}');
    nsis = nsis.replace('::ICO::', '${winPath(Sys.getCwd()+"Release/windows/icon.ico")}');
    
    var languages = '';
    if ( info.languages != null )
    {
      for ( language in info.languages )
      {
        languages += '!insertmacro MUI_LANGUAGE "${language}"\n';
      }
    }
    else
    {
      languages += '!insertmacro MUI_LANGUAGE "English"';
    }
    nsis = nsis.replace('::LANGUAGES::', '${languages}');
    
    // Files
    var files = fileDirectoryWindows('Release/windows');
    nsis = nsis.replace('::FILES::', '${files}');
    
    // Deletes
    var deletes = deleteDirectoryWindows('Release/windows');
    nsis = nsis.replace('::DELETES::', '${deletes}');
    
    // Save script
    File.saveContent('Release/installer.nsi', nsis);
    
    // Run script
    call('makensis Release/installer.nsi');
    
    // Send to server
    sendServer('${lime.app.file}', 'windows-setup', 'Release/${lime.app.file}-${git}.exe');
  }
  static function fileDirectoryWindows( path:String, outPath:String = "$INSTDIR" )
  {
    var keep:Array<String> = [];
    
    var str = '';
    str += 'SetOutPath "${outPath}"\n';
    for ( file in FileSystem.readDirectory(path) )
    {
      var p = '${path}/${file}';
      if ( FileSystem.isDirectory(p) )
      {
        keep.push( file );
      }
      else
      {
        str += 'File "${winPath(full(p))}"\n';
      }
    }
    
    // Parse directory
    for ( file in keep )
    {
      str += fileDirectoryWindows('${path}/${file}', '${outPath}\\${file}');
    }
    
    return str;
  }
  static function deleteDirectoryWindows( path:String, outPath:String = "$INSTDIR" )
  {
    var keep:Array<String> = [];
    
    var str = '';
    for ( file in FileSystem.readDirectory(path) )
    {
      var p = '${path}/${file}';
      if ( FileSystem.isDirectory(p) )
      {
        keep.push( file );
      }
      else
      {
        str += 'Delete "${outPath}\\${file}"\n';
      }
    }
    
    // Parse directory
    for ( file in keep )
    {
      str += deleteDirectoryWindows('${path}/${file}', '${outPath}\\${file}');
      str += 'RmDir "${outPath}\\${file}"\n';
    }
    
    return str;
  }
  
  // Compile Android
  static function compileAndroid( project:Project, info:ProjectInfo, lime:HXProject )
  {
    trace("- ANDROID -");
    
    // Create XML project file
    if ( FileSystem.exists('project.android.xml') )
    {
      FileSystem.deleteFile('project.android.xml');
    }
    
    var pkg = lime.meta.pkg;
    
    var key = readKey();
    if ( key != null )
    {
      var xml:String = File.getContent('project.xml');
      xml = xml.replace('</project>', '<certificate path="certificates/key.keystore" password="${key.password}" alias="${key.alias}" alias-password="${key.aliasPassword}" /></project>');
      
      var fast = new Fast( Xml.parse(xml).firstElement() );
      for ( node in fast.nodes.meta )
      {
        if ( node.has.resolve('package') && node.has.resolve('if') && (node.att.resolve('if') == 'android') )
        {
          xml = xml.replace('${lime.meta.pkg}', node.att.resolve('package'));
          pkg = node.att.resolve('package');
        }
      }
      
      File.saveContent('project.android.xml', xml);
    }
    else
    {
      trace('!!! ERROR: MISSING KEY FOR ANDROID');
      return;
    }
    
    // Compile
    var log:String = '';
    
    if ( project.json.legacy )
    {
      removeDir('Export/android/bin');
      
      log = call('haxelib run openfl build project.android.xml android -verbose -Dlegacy -Drelease > Release/android.log');
    }
    else
    {
      // Weird bug?
      removeDir('Export/android');
      createDir('Export/android/final/haxe/_generated');
      
      log = call('haxelib run openfl build project.android.xml android -verbose -final > Release/android.log');
    }
    
    // Cleanup
    FileSystem.deleteFile('project.android.xml');
    
    // Get log
    log = getLog('Release/android.log');
    
    trace('');
    Sys.print(log);
    trace('');
    
    // Copy package
    var bytes:Bytes = null;
    
    if ( project.json.legacy )
    {
      if ( FileSystem.exists('Export/android/bin/bin/${lime.app.file}-release.apk') ) bytes = File.getBytes('Export/android/bin/bin/${lime.app.file}-release.apk');
    }
    else
    {
      if ( FileSystem.exists('Export/android/final/bin/app/build/outputs/apk/${lime.app.file}-release.apk') ) bytes = File.getBytes('Export/android/final/bin/app/build/outputs/apk/${lime.app.file}-release.apk');
    }
    
    addRelease( bytes, '${lime.app.file}-${git}.apk' );
    
    // Test script
    var script = File.getContent('${getPath()}/utils/android.sh');
    script = script.replace('::APK::', '${lime.app.file}-${git}.apk');
    script = script.replace('::PKG::', '${pkg}');
    File.saveContent('Release/android.sh', script);
    call('chmod +x Release/android.sh');
    
    // Deploy android script
    script = File.getContent('${getPath()}/utils/deploy_android.sh');
    script = script.replace('::APK::', '${lime.app.file}-${git}.apk');
    script = script.replace('::PKG::', '${pkg}');
    script = script.replace('::JSON::', '${getPath()}/../google.json');
    File.saveContent('Release/deploy_android.sh', script);
    call('chmod +x Release/deploy_android.sh');
    
    // Send to server
    if ( FileSystem.exists('Release/${lime.app.file}-${git}.apk') )
    {
      sendServer('${lime.app.file}', 'android', 'Release/${lime.app.file}-${git}.apk');
      sendLogServer('${lime.app.file}', 'android', 'Release/android.log');
    }
    else if ( FileSystem.exists('Release/android.log') )
    {
      var log = File.getContent('Release/android.log');
      sendError('${lime.app.file}', 'android', 'Compile error:\n\n${log}');
    }
    else
    {
      sendError('${lime.app.file}', 'android', 'Fatal Error: Not even a log output!');
    }
  }
  
  // Compile Mac
  static function compileMac( project:Project, info:ProjectInfo, lime:HXProject )
  {
    trace("- MAC -");
    
    // DEPLOY
    // fastlane deliver -u failsafegames@gmail.com --pkg Release/${lime.app.file}-store-${git}.pkg --force
    
    // Some issue with the app signing
    call('sudo rm -Rf "Release/app"');
    call('sudo rm -Rf "Release/store"');
    
    // Compile
    var log:String = '';
    
    // Weird issue with package name
    if ( FileSystem.exists('project.mac.xml') )
    {
      FileSystem.deleteFile('project.mac.xml');
    }
    var xml:String = File.getContent('project.xml');
    
    var fast = new Fast( Xml.parse(xml).firstElement() );
    for ( node in fast.nodes.meta )
    {
      if ( node.has.resolve('package') && node.has.resolve('if') && (node.att.resolve('if') == 'mac') )
      {
        xml = xml.replace('${lime.meta.pkg}', node.att.resolve('package'));
      }
    }
    File.saveContent('project.mac.xml', xml);
    
    // Build
    if ( project.json.legacy )
    {
      log = call('haxelib run openfl build project.mac.xml mac -verbose -Dlegacy > Release/mac.log');
    }
    else
    {
      createDir('Export/mac64/cpp/final/haxe/_generated');
      log = call('haxelib run openfl build project.mac.xml mac -verbose -final > Release/mac.log');
    }
    
    if ( FileSystem.exists('project.mac.xml') )
    {
      FileSystem.deleteFile('project.mac.xml');
    }
    
    log = getLog('Release/mac.log');
    
    trace('');
    Sys.print(log);
    trace('');
    
    // Copy .app
    var bytes:Bytes = null;
    
    // Call command instead... Seems like some permission are lost or I dunno...
    createDir('Release/app');
    createDir('Release/store');
    if ( project.json.legacy )
    {
      call('cp -R "Export/mac64/cpp/bin/${lime.app.file}.app" "Release/app/${lime.app.file}.app"');
      call('cp -R "Export/mac64/cpp/bin/${lime.app.file}.app" "Release/store/${lime.app.file}.app"');
      //copyFolder('Export/mac64/cpp/bin/${lime.app.file}.app', 'Release/${lime.app.file}.app');
    }
    else
    {
      call('cp -R "Export/mac64/cpp/final/bin/${lime.app.file}.app" "Release/app/${lime.app.file}.app"');
      call('cp -R "Export/mac64/cpp/final/bin/${lime.app.file}.app" "Release/store/${lime.app.file}.app"');
      //copyFolder('Export/mac64/cpp/final/bin/${lime.app.file}.app', 'Release/${lime.app.file}.app');
    }
    
    call('sudo rm Release/app/${lime.app.file}.app/Contents/Entitlements.plist');
    call('sudo rm Release/store/${lime.app.file}.app/Contents/Entitlements.plist');
    
    // Installer
    installerMac( project, info, lime );
    
    // Deploy mac script
    var script = File.getContent('${getPath()}/utils/deploy_mac.sh');
    script = script.replace('::FILE::', 'osx/${lime.app.file}-store-${git}.pkg');
    File.saveContent('Release/deploy_mac.sh', script);
    call('chmod +x Release/deploy_mac.sh');
    
    // Send to server
    if ( FileSystem.exists('Release/app/${lime.app.file}.app') )
    {
      sendServer('${lime.app.file}', 'mac', 'Release/${lime.app.file}-${git}.dmg');
      sendLogServer('${lime.app.file}', 'mac', 'Release/mac.log');
    }
    else if ( FileSystem.exists('Release/mac.log') )
    {
      var log = File.getContent('Release/mac.log');
      sendError('${lime.app.file}', 'mac', 'Compile error:\n\n${log}');
    }
    else
    {
      sendError('${lime.app.file}', 'mac', 'Fatal Error: Not even a log output!');
    }
  }
  
  // Create Mac installer
  static function installerMac( project:Project, info:ProjectInfo, lime:HXProject )
  {
    trace('Creating mac installer');
    
    if ( FileSystem.exists('Release/app/${lime.app.file}.app') )
    {
      // Replace version
      var plist = File.getContent('Release/app/${lime.app.file}.app/Contents/Info.plist');
      
      call('sudo rm Release/app/${lime.app.file}.app/Contents/Info.plist');
      call('sudo rm Release/store/${lime.app.file}.app/Contents/Info.plist');
      
      plist = plist.replace('1.0.0', '${lime.meta.version}');
      File.saveContent('Release/app/${lime.app.file}.app/Contents/Info.plist', plist);
      File.saveContent('Release/store/${lime.app.file}.app/Contents/Info.plist', plist);
      
      FileSystem.createDirectory('Release/osx');
      
      // Sign
      call('sudo codesign -f -s "Developer ID Application: ${config.publisher} (${lime.certificate.teamID})" -v "Release/app/${lime.app.file}.app/" --deep --entitlements "${getPath()}/utils/mac.plist"');
      call('sudo codesign -f -s "3rd Party Mac Developer Application: ${config.publisher} (${lime.certificate.teamID})" -v "Release/store/${lime.app.file}.app/" --deep --entitlements "${getPath()}/utils/mac.plist"');
      
      // Create PKG
      call('productbuild --component "Release/app/${lime.app.file}.app/" /Applications --sign "Developer ID Installer: ${config.publisher} (${lime.certificate.teamID})" --product "Release/app/${lime.app.file}.app/Contents/Info.plist" "Release/${lime.app.file}-${git}.pkg"');
      call('productbuild --component "Release/store/${lime.app.file}.app/" /Applications --sign "3rd Party Mac Developer Installer: ${config.publisher} (${lime.certificate.teamID})" --product "Release/store/${lime.app.file}.app/Contents/Info.plist" "Release/osx/${lime.app.file}-store-${git}.pkg"');
      
      // Create DMG
      call('sudo ${getPath()}/utils/create-dmg/create-dmg --volname "${lime.meta.title}" --volicon ${full("Release/app")}/${lime.app.file}.app/Contents/Resources/icon.icns --background ${full("utils/dmg.png")} --window-pos 200 120 --window-size 770 410 --icon-size 100 --icon ${lime.app.file}.app 300 248 --hide-extension ${lime.app.file}.app --app-drop-link 500 243 ${full("Release")}/${lime.app.file}-${git}.dmg ${full("Release/app")}');
      
      // Sign DMG
      call('codesign -s "Developer ID Application: ${config.publisher} (${lime.certificate.teamID})" "Release/${lime.app.file}-${git}.dmg"');
      
      // Send server
      sendServer('${lime.app.file}', 'mac-setup', 'Release/${lime.app.file}-${git}.pkg');
      sendServer('${lime.app.file}', 'mac-store', 'Release/osx/${lime.app.file}-store-${git}.pkg');
    }
  }
  
  // Compile iOS
  static function compileIOS( project:Project, info:ProjectInfo, lime:HXProject )
  {
    trace("- iOS -");
    
    // Compile
    var log:String = '';
    
    if ( project.json.legacy )
    {
      // Add support for team-id on legacy project without any modification to lime
      if ( FileSystem.exists('project.ios.xml') )
      {
        FileSystem.deleteFile('project.ios.xml');
      }
      
      var projectXML = File.getContent('project.xml');
      projectXML = projectXML.replace('</project>', '<template path="templates_ignore" /></project>');
      File.saveContent('project.ios.xml', projectXML);
      
      var content = File.getContent('${getPath()}/utils/project.pbxproj');
      content = content.replace('::if DEVELOPMENT_TEAM_ID::', '::if APP_FILE::'); // true?
      content = content.replace('::DEVELOPMENT_TEAM_ID::', '${lime.certificate.teamID}');
      content = content.replace('::config.ios.identity::', 'iPhone Developer');
      
      createDir('templates_ignore/iphone/PROJ.xcodeproj');
      File.saveContent('templates_ignore/iphone/PROJ.xcodeproj/project.pbxproj', content);
      
      // Require Fullscreen
      var infoPlist = File.getContent('${getPath()}/utils/info.plist');
      FileSystem.createDirectory('templates_ignore/iphone/PROJ');
      File.saveContent('templates_ignore/iphone/PROJ/PROJ-Info.plist', infoPlist);
      
      // -Dsource-header=0
      // No idea why this is needed...
      log = call('haxelib run openfl build project.ios.xml ios -verbose -Dlegacy -Dsource-header=0 > Release/ios.log');
      
      // Cleanup
      removeDir('templates_ignore');
      FileSystem.deleteFile('project.ios.xml');
    }
    else
    {
      createDir('Export/ios/final/${lime.app.file}/haxe/_generated');
      log = call('haxelib run openfl build ios -verbose -final > Release/ios.log');
    }
    
    log = getLog('Release/ios.log');
    
    trace('');
    Sys.print(log);
    trace('');
    
    // Yup, building again with fastlane... (I know, will figure out something better, but currently have an issue with turning the .app into .ipa)
    var bytes:Bytes = null;
    
    FileSystem.createDirectory('Release/ios');
    
    // Add fullscreen required for ios submission (yup another hack, but whatev, I just want this to works...)
    /*
    if ( project.json.legacy )
    {
      if ( FileSystem.exists('Export/ios/${lime.app.file}/${lime.app.file}-Info.plist') )
      {
        var plist = File.getContent('Export/ios/${lime.app.file}/${lime.app.file}-Info.plist');
        FileSystem.deleteFile('Export/ios/${lime.app.file}/${lime.app.file}-Info.plist');
        
        plist = plist.replace('</dict>', '<key>UIRequiresFullScreen</key><true/></dict>');
        File.saveContent('Export/ios/${lime.app.file}/${lime.app.file}-Info.plist', plist);
      }
    }
    */
    
    //call('fastlane sigh -a ${lime.meta.pkg} -u failsafegames@gmail.com');
    
    if ( project.json.legacy )
    {
      call('fastlane run recreate_schemes project:Export/ios/${lime.app.file}.xcodeproj');
      
      if ( lime.certificate != null )
      {
        call('fastlane gym -p Export/ios/${lime.app.file}.xcodeproj -g ${lime.certificate.teamID} -o Release/ios -n ${lime.app.file}-${git}');
      }
      else
      {
        call('fastlane gym -p Export/ios/${lime.app.file}.xcodeproj -o Release/ios -n ${lime.app.file}-${git}');
      }
    }
    else
    {
      call('fastlane run recreate_schemes project:Export/ios/final/${lime.app.file}.xcodeproj');
      
      if ( lime.certificate != null )
      {
        call('fastlane gym -p Export/ios/final/${lime.app.file}.xcodeproj -s ${lime.app.file} -g ${lime.certificate.teamID} -o Release/ios -n ${lime.app.file}-${git}');
      }
      else
      {
        call('fastlane gym -p Export/ios/final/${lime.app.file}.xcodeproj -s ${lime.app.file} -o Release/ios -n ${lime.app.file}-${git}');
      }
    }
    
    // Test ios script
    var script = File.getContent('${getPath()}/utils/ios.sh');
    
    if ( project.json.legacy )
    {
      script = script.replace('::FILE::', '../Export/ios/build/Release-iphoneos/${lime.app.file}.app');
    }
    else
    {
      script = script.replace('::FILE::', '../Export/ios/final/build/Release-iphoneos/${lime.app.file}.app');
    }
    
    File.saveContent('Release/ios.sh', script);
    call('chmod +x Release/ios.sh');
    
    // Deploy ios script
    var script = File.getContent('${getPath()}/utils/deploy_ios.sh');
    script = script.replace('::FILE::', 'ios/${lime.app.file}-${git}.ipa');
    File.saveContent('Release/deploy_ios.sh', script);
    call('chmod +x Release/deploy_ios.sh');
    
    // Send to server
    if ( FileSystem.exists('Export/ios/build/Release-iphoneos/${lime.app.file}.app') || FileSystem.exists('Export/ios/final/build/Release-iphoneos/${lime.app.file}.app') )
    {
      sendServer('${lime.app.file}', 'ios', 'Release/ios/${lime.app.file}-${git}.ipa');
      sendLogServer('${lime.app.file}', 'ios', 'Release/ios.log');
    }
    else if ( FileSystem.exists('Release/ios.log') )
    {
      var log = File.getContent('Release/ios.log');
      sendError('${lime.app.file}', 'ios', 'Compile error:\n\n${log}');
    }
    else
    {
      sendError('${lime.app.file}', 'ios', 'Fatal Error: Not even a log output!');
    }
  }
  
  // Compile Linux
  static function compileLinux( project:Project, info:ProjectInfo, lime:HXProject )
  {
    trace("- LINUX -");
    
    // Compile
    var log:String = '';
    
    if ( project.json.legacy )
    {
      log = call('haxelib run openfl build linux -verbose -Dlegacy > Release/linux.log');
    }
    else
    {
      createDir('Export/linux64/cpp/final/haxe/_generated');
      log = call('haxelib run openfl build linux -verbose -final > Release/linux.log');
    }
    
    log = getLog('Release/linux.log');
    
    trace('');
    Sys.print(log);
    trace('');
    
    // Create .deb package for linux
    installerLinux( project, info, lime );
    
    // Send to server
    
  }
  static function installerLinux( project:Project, info:ProjectInfo, lime:HXProject )
  {
    emptyDir('Release/linux');
    
    if ( project.json.legacy )
    {
      call('cp -R Export/linux64/cpp/bin Release');
    }
    else
    {
      call('cp -R Export/linux64/cpp/final/bin Release');
    }
    
    // Create deb
    emptyDir('Release/deb');
    createDir('Release/deb/DEBIAN');
    //createDir('Release/deb/opt/${lime.app.file}');
    createDir('Release/deb/usr/bin');
    createDir('Release/deb/usr/share/applications');
    createDir('Release/deb/usr/share/icons/hicolor/16x16/apps');
    createDir('Release/deb/usr/share/icons/hicolor/32x32/apps');
    createDir('Release/deb/usr/share/icons/hicolor/48x48/apps');
    createDir('Release/deb/usr/share/icons/hicolor/128x128/apps');
    createDir('Release/deb/usr/share/icons/hicolor/256x256/apps');
    
    createDir('Release/deb/opt');
    call('cp -R Release/bin Release/deb/opt/${lime.app.file}');
    
    createDir('Release/deb/opt/${lime.app.file}/Icon/16x16');
    createDir('Release/deb/opt/${lime.app.file}/Icon/32x32');
    createDir('Release/deb/opt/${lime.app.file}/Icon/48x48');
    createDir('Release/deb/opt/${lime.app.file}/Icon/128x128');
    createDir('Release/deb/opt/${lime.app.file}/Icon/256x256');
    
    // Bin
    var bin = File.getContent('${getPath()}/utils/deb/file');
    bin = bin.replace('::FILE::', '${lime.app.file}');
    File.saveContent('Release/deb/usr/bin/${lime.app.file}', bin);
    call('chmod +x Release/deb/usr/bin/${lime.app.file}');
    
    var run = File.getContent('${getPath()}/utils/deb/run.sh');
    run = run.replace('::FILE::', '${lime.app.file}');
    File.saveContent('Release/deb/opt/${lime.app.file}/${lime.app.file}.sh', run);
    call('chmod +x Release/deb/opt/${lime.app.file}/${lime.app.file}.sh');
    
    // Desktop
    var desktop = File.getContent('${getPath()}/utils/deb/file.desktop');
    desktop = desktop.replace('::VERSION::', '${lime.meta.version}');
    desktop = desktop.replace('::NAME::', '${lime.meta.title}');
    desktop = desktop.replace('::FILE::', '${lime.app.file}');
    File.saveContent('Release/deb/usr/share/applications/${lime.app.file}.desktop', desktop);
    
    // Create icons
    var squares:Array<Icon> = [
      {name: '${lime.app.file}.png', width: 16, height: 16},
      {name: '${lime.app.file}.png', width: 32, height: 32},
      {name: '${lime.app.file}.png', width: 48, height: 48},
      {name: '${lime.app.file}.png', width: 128, height: 128},
      {name: '${lime.app.file}.png', width: 256, height: 256},
    ];
    for ( icon in squares )
    {
      call('convert utils/icon.png -resize ${icon.width}x${icon.height} -crop ${icon.width}x${icon.height}+0+0 -strip +repage Release/deb/usr/share/icons/hicolor/${icon.width}x${icon.height}/apps/${icon.name}');
      call('convert utils/icon.png -resize ${icon.width}x${icon.height} -crop ${icon.width}x${icon.height}+0+0 -strip +repage Release/deb/opt/${lime.app.file}/Icon/${icon.width}x${icon.height}/${icon.name}');
    }
    
    // Control file
    var size = getCall('du -ks Release/deb|cut -f 1').replace('\n', '');
    var control = File.getContent('${getPath()}/utils/deb/control');
    control = control.replace('::PUBLISHER::', '${config.publisher}');
    control = control.replace('::VERSION::', '${lime.meta.version}');
    control = control.replace('::NAME::', '${lime.meta.title}');
    control = control.replace('::FILE::', '${lime.app.file}');
    control = control.replace('::EMAIL::', 'jeandenis.boivin@gmail.com');
    control = control.replace('::SIZE::', '${size}');
    File.saveContent('Release/deb/DEBIAN/control', control);
    
    // Build
    call('dpkg-deb --build Release/deb Release/${lime.app.file}_${git}_amd64.deb');
    
    // Create portable
    File.saveContent('Release/deb/opt/${lime.app.file}/${lime.app.file}.desktop', desktop);
    
    Sys.setCwd('${cwd}/${project.path}/${info.folder}/Release/deb/opt');
    call('tar -cvjSf ../../${lime.app.file}_${git}_x64.tar.bz2 ${lime.app.file}');
    Sys.setCwd('${cwd}/${project.path}/${info.folder}');
    
    // Send to server
    if ( FileSystem.exists('Release/bin/${lime.app.file}') )
    {
      sendServer('${lime.app.file}', 'linux', 'Release/${lime.app.file}_${git}_x64.tar.bz2');
      sendLogServer('${lime.app.file}', 'linux', 'Release/linux.log');
    }
    else if ( FileSystem.exists('Release/linux.log') )
    {
      var log = File.getContent('Release/linux.log');
      sendError('${lime.app.file}', 'linux', 'Compile error:\n\n${log}');
    }
    else
    {
      sendError('${lime.app.file}', 'linux', 'Fatal Error: Not even a log output!');
    }
    
    sendServer('${lime.app.file}', 'ubuntu', 'Release/${lime.app.file}_${git}_amd64.deb');
  }
  
  // Get projects by reading the specified folder in cwd
  static function getProjects()
  {
    // Get default config
    if ( FileSystem.exists('config.json') )
    {
      try
      {
        config = Json.parse(File.getContent('config.json'));
      }
      catch ( e:Dynamic )
      {
        trace('Error parsing JSON (config.json): ${e}');
        
        return null;
      }
    }
    
    if ( config == null )
    {
      config = 
      {
        password: '123456',
        url: 'http://localhost/builds/api.php',
        company: 'FailSafe Games',
        website: 'https://www.failsafegames.com/',
        publisher: 'Jean-Denis Boivin'
      };
    }
    
    // Read directories
    var projects:Array<Project> = [];
    for ( file in FileSystem.readDirectory('.') )
    {
      if ( FileSystem.isDirectory('${file}') )
      {
        var project = getProject('${file}');
        if ( project != null ) projects.push( project );
      }
    }
    
    return projects;
  }
  
  // Get project JSON
  static function getProject( path:String )
  {
    // Check for JSON
    var json = '${path}/${JSON}';
    if ( FileSystem.exists(json) )
    {
      try
      {
        var project = 
        {
          path: path,
          json: Json.parse(File.getContent(json))
        };
        
        trace('Found: ${path}');
        
        return project;
      }
      catch ( e:Dynamic )
      {
        trace('Error parsing JSON (${json}): ${e}');
        
        return null;
      }
    }
    
    return null;
  }
}