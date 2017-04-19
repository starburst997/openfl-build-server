package;

import haxe.Json;
import haxe.io.Path;

import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

import neko.Lib;

using StringTools;

// Project definition
typedef Project =
{
  var json:ProjectJSON;
  var path:String;
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
    trace('You need to have the following installed: git, npm');
    trace('Install "switchx" to switch between haxe version:');
    trace('    npm install haxeshim -g && npm install switchx -g && switchx');
    trace('');
    trace('Makes sure you can build on each of the platform');
    trace('WIN: Windows / HTML5 / Android');
    trace('MAC: Mac / iOS');
    trace('LINUX: Linux');
    
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
        gitLoop();
      }
      else
      {
        trace('No project found!');
      }
    }
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
        if ( head != current )
        {
          trace('Start compilation!');
          compileProject( project );
        }
      }
      
      // Wait 30sec...
      Sys.sleep(30);
    }
  }
  
  // Start a command and return the output
  static function call( cmd:String, args:Array<String> = null )
  {
    Sys.command( cmd, args );
    
    return ''; // Temporary fix...
  }
  static function getCall( cmd:String, args:Array<String> = null )
  {
    var p = new Process( cmd, args );
    p.exitCode(true);
    
    var output = p.stdout.readAll().toString();
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
        call('haxelib set ${library.name} ${library.version} --always');
        call('haxelib dev ${library.name} --always'); // Makes sure to switch off dev version...
      }
    }
    
    trace('');
    trace('Verifying haxelib...');
    trace('');
    call('haxelib', ['list']);
    
    separ();
  }
  
  // Compile a project
  static function compileProject( project:Project )
  {
    // Set environment
    switchProject( project );
    
    // Update GIT repo
    trace('Updating GIT repo...');
    trace('');
    
    call('git', ['pull']);
    call('git', ['submodule', 'update', '--init', '--recursive']);
    
    var head = getCall('git', ['rev-parse', 'HEAD']);
    var current = getCall('git', ['rev-parse', '@{u}']);
    trace('${head} - ${current}');
    
    separ();
    
    // Compile projects
    for ( p in project.json.projects )
    {
      // Get into the CWD
      Sys.setCwd('${cwd}/${project.path}/${p.folder}');
      
      switch ( Sys.systemName() )
      {
        case 'Windows':
          trace('Compiling for Windows platform...');
          if ( p.win != null )
          {
            compile(p.win);
          }
          else
          {
            compileHTML5( project );
            //compileWindows( project );
            //compileAndroid( project );
          }
        case 'Mac':
          trace('Compiling for Mac platform...');
          if ( p.mac != null )
          {
            compile(p.mac);
          }
          else
          {
            compileMac( project );
            compileIOS( project );
          }
        case 'Linux':
          trace('Compiling for Linux platform...');
          if ( p.linux != null )
          {
            compile(p.linux);
          }
          else
          {
            compileLinux( project );
          }
      }
    }
  }
  
  // Compile custom commands
  static function compile( commands:Array<String> )
  {
    for ( command in commands )
    {
      call(command);
    }
  }
  
  // Compile HTML5
  static function compileHTML5( project:Project )
  {
    // Compile
    var log:String = '';
    
    if ( project.json.legacy )
    {
      log = getCall('haxelib', ['run', 'openfl', 'build', 'html5', '-Dwebgl', '-minify', '-yui']);
    }
    else
    {
      log = getCall('haxelib', ['run', 'openfl', 'build', 'html5', '-final']);
    }
    
    trace('');
    Sys.print(log);
    trace('');
    
    // Package ZIP
    
    
    // Send to server
    
  }
  
  // Compile Windows
  static function compileWindows( project:Project )
  {
    // Compile
    var log:String = '';
    
    if ( project.json.legacy )
    {
      log = call('haxelib', ['run', 'openfl', 'build', 'windows', '-Dlegacy']);
    }
    else
    {
      log = call('haxelib', ['run', 'openfl', 'build', 'windows', '-final']);
    }
    
    trace('');
    Sys.print(log);
    trace('');
    
    // Create installer
    
    
    // Send to server
    
  }
  
  // Compile Android
  static function compileAndroid( project:Project )
  {
    // Create XML project file
    
    
    // Compile
    var log:String = '';
    
    if ( project.json.legacy )
    {
      log = call('haxelib', ['run', 'openfl', 'build', 'project.android.xml', 'android', '-Dlegacy']);
    }
    else
    {
      log = call('haxelib', ['run', 'openfl', 'build', 'project.android.xml', 'android', '-final']);
    }
    
    trace('');
    Sys.print(log);
    trace('');
    
    // Send to server
    
  }
  
  // Compile Mac
  static function compileMac( project:Project )
  {
    // Compile
    var log:String = '';
    
    if ( project.json.legacy )
    {
      log = call('haxelib', ['run', 'openfl', 'build', 'mac', '-Dlegacy']);
    }
    else
    {
      log = call('haxelib', ['run', 'openfl', 'build', 'mac', '-final']);
    }
    
    trace('');
    Sys.print(log);
    trace('');
    
    // Create DMG
    
    
    // Send to server
    
  }
  
  // Compile iOS
  static function compileIOS( project:Project )
  {
    // Compile
    var log:String = '';
    
    if ( project.json.legacy )
    {
      log = call('haxelib', ['run', 'openfl', 'build', 'ios', '-Dlegacy']);
    }
    else
    {
      log = call('haxelib', ['run', 'openfl', 'build', 'ios', '-final']);
    }
    
    trace('');
    Sys.print(log);
    trace('');
    
    // Send to server
    
  }
  
  // Compile Linux
  static function compileLinux( project:Project )
  {
    // Compile
    var log:String = '';
    
    if ( project.json.legacy )
    {
      log = call('haxelib', ['run', 'openfl', 'build', 'linux', '-Dlegacy']);
    }
    else
    {
      log = call('haxelib', ['run', 'openfl', 'build', 'linux', '-final']);
    }
    
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