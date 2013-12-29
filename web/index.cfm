<cfscript>
    variables.snitch = createObject('org.snitch.snitch').init();
    try {
        throw("Show how Snitch works!");
    }
    catch( any e ) {
        variables.snitch.log(e);
    }
    
</cfscript>

