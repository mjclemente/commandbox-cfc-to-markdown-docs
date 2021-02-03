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
  */
  function run(
    required string path,
    string directory = '',
    boolean force = false,
    string template = 'default',
    string layout = 'default',
    string methodOrder = 'positional',
    boolean generateFile = true
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

    var body = functions.reduce(
      ( result, f, index ) => {
        // This is generating the params, whether they're required, and their defaults
        var params = f.parameters.reduce(
          function( result, item, index, orig ){
            var param = '';
            if( item.required ){
              param &= 'required';
            }
            param &= ' #item.type#';
            param &= ' #item.name#';
            if( item.keyExists('default') ){
              if( isBoolean( item.default ) || isNumeric( item.default ) ){
                param &= '=#item.default# ';
              } else {
                param &= '="#item.default#" ';
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
        result &= functionMarkdown;

        return result;
      }, ''
    );
    // end of function loop

    // generate markdown file
    // directory
    var destinationDirectory = directory.len() ? resolvePath( directory ) : getCWD();
    var cfcFileName = getFileFromPath( resolvedPath );
    var destinationFileName = cfcFileName.rereplacenocase( '\.cfc$', '.md' );
    var docPath = "#destinationDirectory#/#destinationFileName#";
    // Create dir if it doesn't exist
    print.line( "Confirming destination directory: #destinationDirectory#" );
    directoryCreate( destinationDirectory, true, true );
    if( generateFile && !force && fileExists( docPath ) ){
      error( "A markdown file already exists here (#docPath#). Use the --force option if you wish to overwrite it." );
    }

    var markdown = '';
    savecontent variable="markdown" {
      include template="#layoutTemplatePath#";
    }

    if( generateFile ){
      fileWrite( docPath, markdown );
      print.greenLine( "Generated Documentation: #docPath#" ).toConsole();
      return;
    }

    return markdown;
  }
}
