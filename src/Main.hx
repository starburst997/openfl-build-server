package;

import haxe.Json;
import haxe.Timer;
import haxe.io.Bytes;
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

// Project definition
typedef Project =
{
  var json:ProjectJSON;
  var path:String;
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
  static var cwd:String = '';
  static var projects:Array<Project> = null;
  static var oldTrace = haxe.Log.trace;
  
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
      }
    }
    
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
    
    if ( action == 'switch' )
    {
      var project = getProject(cwd);
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
      else
      {
        trace('No project found!');
      }
    }
    
    Sys.exit(0);
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
        
        call('git', ['fetch']);
        
        var head = getCall('git', ['rev-parse', 'HEAD']);
        trace('HEAD: ${head}');
        
        var current = getCall('git', ['rev-parse', '@{u}']);
        trace('Current: ${current}');
        trace('');
        
        // Trigger if they are different
        if ( (head != '') && (current != '') && (head != null) && (current != null) && (head != current) )
        {
          trace('Start compilation!');
          compileProject( project );
        }
      }
      
      //l.release();
      
      // Wait 30sec...
      Sys.sleep(1);
      //Sys.sleep(30);
    }
    
    // Trying timer since while loop since to break ctrl+c
    //Sys.sleep(1);
    //Timer.delay(gitLoop, 1000);
    
    //Sys.exit(0);
  }
  
  // Start a command and return the output
  static function call( cmd:String, args:Array<String> = null )
  {
    trace('Calling: ${cmd}');
    
    var p = new Process( cmd, args );
    p.exitCode(true);
    p.close();
    
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
    // Update GIT repo
    trace('Updating GIT repo...');
    trace('');
    
    //trace('${Sys.getCwd()}');
    
    //Sys.command('git pull');
    
    call('git pull');
    call('git submodule update --init --recursive');
    
    var head = getCall('git', ['rev-parse', 'HEAD']);
    var current = getCall('git', ['rev-parse', '@{u}']);
    trace('${head} - ${current}');
    
    if ( head != current )
    {
      separ();
      trace('- WARNING: Something wrong with git pull... -');
      separ();
      return;
    }
    
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
      trace('Removing Release / Export directory...');
      removeDir('Release');
      removeDir('Export'); // Necessary???
      
      createDir('Release');
      createDir('Export');
      trace('');
      
      // Get lime project
      var limeProject = parseHXProject('${cwd}/${project.path}/${p.folder}/project.xml');
      
      // Compile based on platform
      switch ( Sys.systemName() )
      {
        case 'Windows':
          trace('Compiling for Windows platform...');
          trace('');
          if ( p.win != null )
          {
            compile( project, p, limeProject, p.win );
          }
          else
          {
            compileHTML5( project, p, limeProject );
            compileWindows( project, p, limeProject );
          }
        case 'Mac':
          trace('Compiling for Mac platform...');
          trace('');
          if ( p.mac != null )
          {
            compile( project, p, limeProject, p.mac );
          }
          else
          {
            compileMac( project, p, limeProject );
            compileIOS( project, p, limeProject );
          }
        case 'Linux':
          trace('Compiling for Linux platform...');
          trace('');
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
      
      separ();
    }
  }
  
  // Get full path from CWD
  static function full( path:String )
  {
    var cwd = Sys.getCwd();
    cwd = cwd.substr(0, cwd.length - 1);
    
    var full = '${cwd}/${path}';
    return full;
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
      addRelease( zipFolder('Export/html5/bin'), '${lime.app.file}-html5.zip' );
    }
    else
    {
      addRelease( zipFolder('Export/html5/final/bin'), '${lime.app.file}-html5.zip' );
    }
    
    // Send to server
    
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
      addRelease( zipFolder('Export/windows/cpp/bin'), '${lime.app.file}-windows.zip' );
    }
    else
    {
      addRelease( zipFolder('Export/windows/cpp/final/bin'), '${lime.app.file}-windows.zip' );
    }
    
    // Create installer
    
    
    // Send to server
    
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
    
    var key = readKey();
    if ( key != null )
    {
      var xml:String = File.getContent('project.xml');
      xml = xml.replace('_PASSWORD_', key.password);
      xml = xml.replace('_ALIAS_', key.alias);
      xml = xml.replace('_ALIAS-PASSWORD_', key.aliasPassword);
      xml = xml.replace('_CHANGE-TO-FINAL_', project.json.legacy ? 'release' : 'final');
      
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
    
    addRelease( bytes, '${lime.app.file}.apk' );
    
    // Send to server
    
  }
  
  // Compile Mac
  static function compileMac( project:Project, info:ProjectInfo, lime:HXProject )
  {
    trace("- MAC -");
    
    // Compile
    var log:String = '';
    
    if ( project.json.legacy )
    {
      log = call('haxelib run openfl build mac -verbose -Dlegacy > Release/mac.log');
    }
    else
    {
      createDir('Export/mac64/cpp/final/haxe/_generated');
      log = call('haxelib run openfl build mac -verbose -final > Release/mac.log');
    }
    
    log = getLog('Release/mac.log');
    
    trace('');
    Sys.print(log);
    trace('');
    
    // Copy .app
    var bytes:Bytes = null;
    
    // Call command instead... Seems like some permission are lost or I dunno...
    createDir('Release/app');
    if ( project.json.legacy )
    {
      call('cp -R "Export/mac64/cpp/bin/${lime.app.file}.app" "Release/app/${lime.app.file}.app"');
      //copyFolder('Export/mac64/cpp/bin/${lime.app.file}.app', 'Release/${lime.app.file}.app');
    }
    else
    {
      call('cp -R "Export/mac64/cpp/final/bin/${lime.app.file}.app" "Release/app/${lime.app.file}.app"');
      //copyFolder('Export/mac64/cpp/final/bin/${lime.app.file}.app', 'Release/${lime.app.file}.app');
    }
    
    // Create DMG
    if ( FileSystem.exists('Release/app/${lime.app.file}.app') )
    {
      call('${getPath()}/utils/create-dmg/create-dmg --volname "${lime.meta.title}" --volicon ${full("Release/app")}/${lime.app.file}.app/Contents/Resources/icon.icns --background ${full("utils/dmg.png")} --window-pos 200 120 --window-size 770 410 --icon-size 100 --icon ${lime.app.file}.app 300 248 --hide-extension ${lime.app.file}.app --app-drop-link 500 243 ${full("Release")}/${lime.app.file}.dmg ${full("Release/app")}');
    }
    
    // Send to server
    
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
      
      createDir('templates_ignore/iphone/PROJ.xcodeproj');
      File.saveContent('templates_ignore/iphone/PROJ.xcodeproj/project.pbxproj', content);
      
      // -Dsource-header=0
      // No idea why this is needed...
      log = call('haxelib run openfl build project.ios.xml ios -verbose -Dlegacy -Dsource-header=0 > Release/ios.log');
      
      // Cleanup
      //removeDir('templates_ignore');
      //FileSystem.deleteFile('project.ios.xml');
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
    
    if ( project.json.legacy )
    {
      call('fastlane run recreate_schemes project:Export/ios/${lime.app.file}.xcodeproj');
      
      if ( lime.certificate != null )
      {
        call('fastlane gym -p Export/ios/${lime.app.file}.xcodeproj -g ${lime.certificate.teamID} -o Release -n ${lime.app.file}');
      }
      else
      {
        call('fastlane gym -p Export/ios/${lime.app.file}.xcodeproj -o Release -n ${lime.app.file}');
      }
    }
    else
    {
      call('fastlane run recreate_schemes project:Export/ios/final/${lime.app.file}.xcodeproj');
      
      if ( lime.certificate != null )
      {
        call('fastlane gym -p Export/ios/final/${lime.app.file}.xcodeproj -s ${lime.app.file} -g ${lime.certificate.teamID} -o Release -n ${lime.app.file}');
      }
      else
      {
        call('fastlane gym -p Export/ios/final/${lime.app.file}.xcodeproj -s ${lime.app.file} -o Release -n ${lime.app.file}');
      }
    }
    
    // Send to server
    
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
    
    // Package .tar.gz
    
    
    // Send to server
    
  }
  
  // Get projects by reading the specified folder in cwd
  static function getProjects()
  {
    var projects:Array<Project> = [];
    for ( file in FileSystem.readDirectory('${PROJECTS}') )
    {
      if ( FileSystem.isDirectory('${PROJECTS}/${file}') )
      {
        var project = getProject('${PROJECTS}/${file}');
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