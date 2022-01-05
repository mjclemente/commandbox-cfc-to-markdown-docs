/**
* Generate markdown from your CFCs
* This is how you call it:
*
* {code:bash}
* markdowndoc path
* {code}
*

**/
component aliases="mdd" {

  variables.templatePath = "/commandbox-cfc-to-markdown-docs/templates/";

  /**
  * @path.hint Path to the CFC that you want to generate documentation for (required)
  * @directory.hint Destination directory to in which to generate the markdown file (default CWD)
  * @force.hint Overwrite an existing markdown file if present (default false)
  * @template.hint Template that controls how the markdown docs for each function are displayed
  * @layout.hint Template that determines the layout of the markdown document
  * @methodOrder.hint Determines the order that functions are displayed in the generated output (default positional)
  * @methodOrder.options positional,alphabetical
  * @generateFile.hint Generate a markdown file with the documentation (default true).
  * @attemptMerge.hint Attempt to merge the generated CFC function documentation into the existing documentation file. Use with caution and inspect resulting file. (default false)
  */
  function run(
    required string path,
    string directory = '',
    boolean force = false,
    string template = 'default',
    string layout = 'default',
    string methodOrder = 'positional',
    boolean generateFile = true,
    boolean attemptMerge = false
  ){
    if( path.listlast( '.' ) != 'cfc' ){
      error( "You can only run this command on CFCs." );
    }

    var resolvedPath = fileSystemUtil.makePathRelative( resolvePath( path ) );
    if ( !fileExists( resolvedPath ) ) {
			return error( "The CFC #resolvedPath# does not exist. Please check the path and try again." );
    }

    var functionTemplatePath = templatePath & '#template#.cfm';
    var layoutTemplatePath = templatePath & 'layouts/#layout#.cfm';

    if ( !fileExists( functionTemplatePath ) ) {
			return error( "The template #template# does not exist. Please check the name and try again." );
    }
    if ( !fileExists( layoutTemplatePath ) ) {
			return error( "The layout #layout# does not exist. Please check the name and try again." );
    }

    var cfcPath = resolvedPath.left( resolvedPath.len() - 4 );
    InspectTemplates();
    var metadata = getComponentMetadata( cfcPath );

    var properties = [];
    var functions = [];

    // We get a list of the properties here to exclude from the generated documentation
    if( metadata.keyExists( 'properties' ) ){
      properties = metadata.properties.reduce(
        function( result, item, index ){
          result.append( item.name );
          return result;
        }, []
      );
    }

    // Get our function list, by filtering out unwanted methods
    if( metadata.keyExists( 'functions' ) ){
      functions = metadata.functions.filter(
        function( item, index ){
          // Exclude init method
          if( item.name == 'init' ){
            return false;
          }
          // Exclude priate methods
          if( item.access == 'private' ){
            return false;
          }
          // exclude generated getters/setters
          if( !item.keyExists( 'hint') && item.name.len() > 3 ){
            if( arrayContains( ['get','set'], item.name.left(3) ) ){
              var prop = item.name.replacenocase( item.name.left(3), '' );
              return !properties.containsnocase( prop );
            }
          }

          return true;
        }
      );
    }

    if( methodOrder == 'positional' ){
      functions.sort(
        (e1, e2 ) => {
          if( e1.position.start < e2.position.start ){
            return -1;
          } else if( e1.position.start > e2.position.start ){
            return 1;
          } else {
            return 0
          }
        }
      );
    } else {
      functions.sort(
        (e1, e2 ) => {
          return compare( e1.name, e2.name );
        }
      );
    }

    // directory
    var destinationDirectory = directory.len() ? resolvePath( directory ) : getCWD();
    var cfcFileName = getFileFromPath( resolvedPath );
    var destinationFileName = cfcFileName.rereplacenocase( '\.cfc$', '.md' );
    var docPath = "#destinationDirectory#/#destinationFileName#";
    var docExists = fileExists( docPath );
    if( generateFile ){
      // Create dir if it doesn't exist
      print.line( "Confirming destination directory: #destinationDirectory#" );
      directoryCreate( destinationDirectory, true, true );
      if( !force && docExists ){
        error( "A markdown file already exists here (#docPath#). Use the --force flag if you wish to overwrite it." );
      }
    }
    var mergeDocContent = '';
    var doMerge = attemptMerge && docExists;
    if( doMerge ){
      mergeDocContent = fileRead(docPath);
      // determine if the document actually has any of the functions in it
      var mergeFunctionFound = functions.reduce(
        (result, f, index ) => {
          if( !result ){
            result = mergeDocContent.reFindNoCase(_mergeRE(f.name));
          }
          return result;
        }, false
      )
    }

    var body = functions.reduce(
      ( result, f, index ) => {
        // This is generating the params, whether they're required, and their defaults
        var params = f.parameters.reduce(
          function( result, item, index, orig ){
            var param = '';
            if( item.required ){
              param &= 'required';
              param &= ' #item.type#';
              param &= ' #item.name#';
            } else {
              param &= '#item.type#';
              param &= '#param.len() ? ' ' : ''##item.name#';
            }
            if( item.keyExists('default') ){
              if( isBoolean( item.default ) || isNumeric( item.default ) ){
                param &= '=#item.default#';
              } else if( item.default == '[runtime expression]' && item.type == 'array' ) {
                var functionBody = fileReadLines(resolvedPath,f.position.start, f.position.end);
                var defaultValue = reMatchNoCase('#item.name# ?= ?\[[^\]]*?\]',functionBody);
                param &= '=#defaultValue[1].listLast('=').trim()#';
              } else if( item.default == '[runtime expression]' && item.type == 'struct' ) {
                var functionBody = fileReadLines(resolvedPath,f.position.start, f.position.end);
                var defaultValue = reMatchNoCase('#item.name# ?= ?{[^}]*?}',functionBody);
                param &= '=#defaultValue[1].listLast('=').trim()#';
              }
              else {
                param &= '="#item.default#"';
              }

            }
            result &= '#param#';
            if( !item.equals( orig.last() ) ){
              result &=', '
            }
            return result;
          }, ''
        );
        // end param check

        var paramHints = f.parameters.reduce(
          function( result, item, index ){
            if( item.keyExists( 'hint' ) && item.hint.trim().len() ){
              result &= 'The parameter `#item.name#` #item.hint##item.hint.right(1) != "." ? "." : ""# ';
            }
            return result;
          }, ' '
        );
        var functionMarkdown = '';
        savecontent variable="functionMarkdown" {
          include template="#functionTemplatePath#";
        }

        if( doMerge && mergeFunctionFound ){
          var mergeRegex = _mergeRE( f.name );
          if( result.reFindNoCase( mergeRegex ) ){
            // print.line( "Found function #f.name#. Replacing with updated documentation." );
            result = result.rereplacenocase( mergeRegex, functionMarkdown );
          } else {
            // the function is being added

            // unless this is the first function in our list, the function before it should have been added to the result. Just place it after that function
            if( index != 1 ){

              var priorFunction = result.reFindNoCase(_mergeRE(functions[index-1].name),1,true);
              var insertPosition = priorFunction.pos[1] + priorFunction.len[1];
              result = result.insert( newLine() & functionMarkdown.rereplacenocase('\n$','') & newline(), insertPosition );

            } else {
              // this is the first function, so we need to find the next function that's present in the document and add it before that

              var functionIndex = 2;
              while( functionIndex <= functions.len() ){
                var nextFunction = result.reFindNoCase(_mergeRE(functions[functionIndex].name),1,true);
                if( nextFunction.match.len() ){
                  var insertPosition = nextFunction.pos[1] - 1;
                  result = result.insert( functionMarkdown, insertPosition );
                  break;
                }
                functionIndex++;
              }

            }

          }

        } else {
          result &= functionMarkdown & newLine();
        }

        return result;
      }, mergeDocContent
    );
    // end of function loop

    // generate markdown file
    var markdown = '';
    // don't use the full layout if we're attempting a merge
    if( doMerge ){
      markdown = body;
    } else {
      savecontent variable="markdown" {
        include template="#layoutTemplatePath#";
      }
    }

    // clean it up
    while( markdown.reFind( _newlineRE() ) ) {
      markdown = markdown.rereplace( _newlineRE(), newLine() );
    }

    if( generateFile ){
      fileWrite( docPath, markdown );
      print.greenLine( "Generated Documentation: #docPath#" ).toConsole();
      return;
    }

    return markdown;
  }

  private string function _mergeRE( required string name ){
    return "(?:##{0,6}| |\*\*?) ?`#name#\((?:[^\)]*)\)`(?:\*\*?)?[\s]{0,2}(?:[^##\n\r]*)";
  }

  private string function _newlineRE() {
    return '(?m)^(?:\s){2,}';
  }

  /**
  *
  * Based on a UDF by Raymond Camden (https://cflib.org/udf/FileRead)
  *
  * @hint Read a range of lines from a file
  * @filepath path to the file being read
  * @start number of the first line to read
  * @end number of the last line to read
  */
  public string function fileReadLines( required string filepath, required numeric start, required numeric end ) {

    if( !fileExists(filepath) ){
      return "";
    }

    var fileLines = '';
    var fileObject = fileOpen(filepath);
    var done = false;
    var lineNumber = 0;

    try {
      while( !done ) {
        lineNumber++;
        var line = fileReadLine(fileObject);
        if( lineNumber >= start ){
          fileLines &= line;
          if( lineNumber < end ){
            fileLines &= Chr(13) & Chr(10);
          }
        }
        if( lineNumber == end ){
          done = true;
        }
      }
    } catch( any e ) {
        rethrow;
    } finally {
        fileClose( fileObject );
    }

    return fileLines;
  }
}
