<cfoutput>######## `#f.name#(#params.len() ? ' #params# ' : ''#)`
<cfif f.keyExists( 'hint' )>
#f.hint##f.hint.right(1) != '.' ? '.' : ''##paramHints.trim().len() ? ' #paramHints.trim()#' : ''##f.keyExists( 'docs' ) ? ' *[Endpoint docs](#f.docs#)*' : ''#</cfif></cfoutput>
