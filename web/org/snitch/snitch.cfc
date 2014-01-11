/*
    cfSnitch, Exception logger / tracker

    History: Our team had been using Hoth since before I joined them in mid-2011
    and I am greatly appreciative of Aaron Greenlee and others who contributed
    to its success. With the project sitting what appears to be idle since about
    that same time period and the needs of my team changing I decided it was time
    to finally start Snitch. 

    Why call it Snitch: That's easy. From childhood tattle tails to Mafia informants, 
    those who tell on others are referred to as snitches.

    Thanks: I would like to thank Aaron Greenlee and those who contributed to Hoth
    my team utilized it for several years and it served us well. If Snitch is
    not what you are looking for I would recommend looking into hoth at
    https://github.com/aarongreenlee/Hoth

    Copyright (c) 2013, Greg Wilson (http://www.imawilson.com/)

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
component output="false" displayname="cfSnitch" hint="Snitch is an exception logger / tracker for ColdFusion and Railo" {

    /**
     * Constructor method
     */
    public snitch function init( string settingsFile = getDirectoryFromPath(getCurrentTemplatePath()) & "/config/settings.ini.cfm" ) {
        var _settings = createObject( "java", "java.util.Properties" ).init();
        var _fs = createObject( "java", "java.io.FileInputStream" ).init( arguments.settingsFile );
        _settings.load( _fs );
        _fs.close();

        variables.settings = {};
        variables.settings.applicationName = _settings.getProperty( "applicationName", "Snitch_" & hash(GetCurrenttemplatepath()) ) ;
        variables.settings.restrictedKeys = _settings.getProperty( "restrictedKeys", "auth_password,password,creditcard,cc" );
        variables.settings.maskRestrictedKeys = _settings.getProperty( "maskRestrictedKeys", "true" );
        variables.settings.additionalScopes = _settings.getProperty( "additionalScopes", "form,url,session,cgi" );
        variables.settings.logsFolder = _settings.getProperty( "logsFolder", "/org/snitch/logs" );
        variables.settings.saveLog = _settings.getProperty( "saveLog", "true" );
        variables.settings.onlySaveNew = _settings.getProperty( "onlySaveNew", "false" );
        variables.settings.sendEmail = _settings.getProperty( "sendEmail", "true" );
        variables.settings.onlySendNew = _settings.getProperty( "onlySendNew", "false" );
        variables.settings.emailFrom = _settings.getProperty( "emailFrom", "" );
        variables.settings.emailTo = _settings.getProperty( "emailTo", "" );

        return this;
    }

    /**
     * Public methods
     */
    public void function log( required any exception, struct overrides = {} ) {
        var _local = {};
        _local['exception'] = parseException( arguments.exception, arguments.overrides );
        _local['scopes'] = parseAdditionalScopes();
        _local['key'] = lCase( ( len(trim(_local['exception'].stacktrace)) ) ? hash( lCase( trim(_local['exception'].stacktrace) ), "SHA" ) : hash( lCase( trim(_local['exception'].message) ), "SHA" ) );

        if ( variables.settings.sendEmail ) {
            sendEmailAlert( _local );
        }

        if ( variables.settings.saveLog ) {
            saveToLogFile( _local );
        }
    }

    /**
     * Private methods
     */
    private string function generateLogFileName( required string key ) {
        return expandPath(variables.settings.logsFolder & "/" & arguments.key & ".log");
    }

    private struct function parseAdditionalScopes() {
        var _ret = {};
        var _local = {};
        _local.scope = "";
        _local.index = 1;
        if ( len(trim(variables.settings.additionalScopes)) ) {
            for ( _local.index = 1; _local.index <= listLen(variables.settings.additionalScopes, ","); _local.index++ ) {
                _local.scope = listGetAt(variables.settings.additionalScopes, _local.index, ",");
                if ( isDefined(_local.scope) && !isNull( evaluate(_local.scope) ) ) {
                    _ret[_local.scope] = evaluate(_local.scope);
                }
            }
        }
        return removeRestrictedKeys( _ret );
    }

    private struct function parseException( required any exception, struct overrides = {} ) {
        var _ret = {
            'detail' = "",
            'message' = "",
            'stacktrace' = "",
            'context' = "",
            'url' = ( structKeyExists( arguments.overrides, "url" ) ) ? arguments.overrides.url : CGI.HTTP_HOST & CGI.path_info,
            'client' = ( structKeyExists( arguments.overrides, "client" ) ) ? arguments.overrides.client : CGI.HTTP_USER_AGENT
        };
        var _local = {};
        _local.key = "";
        for ( _local.key in arguments.exception ) {
            _ret[_local.key] = arguments.exception[_local.key];
        }
        return removeRestrictedKeys( _ret );
    }

    private struct function removeRestrictedKeys( required struct obj ) {
        var _ret = {};
        var _local = {};
        _local.key = "";
        _local.index = 1;
        for ( _local.key in arguments.obj ) {
            if ( !listFindNoCase( variables.settings.restrictedKeys, _local.key ) ) {
                if( isValid("struct", arguments.obj[_local.key]) ) {
                    _ret[_local.key] = removeRestrictedKeys( arguments.obj[_local.key] );
                }
                else if( isValid("array", arguments.obj[_local.key]) ) {
                    _ret[_local.key] = [];
                    for ( _local.index = 1; _local.index <= arrayLen(arguments.obj[_local.key]); _local.index++ ) { 
                        if( isValid("struct", arguments.obj[_local.key][_local.index]) ) {
                            _ret[_local.key][_local.index] = removeRestrictedKeys( arguments.obj[_local.key][_local.index] );
                        }
                        else {
                            _ret[_local.key][_local.index] = arguments.obj[_local.key][_local.index];
                        }
                    }
                }
                else {
                    _ret[_local.key] = arguments.obj[_local.key];
                }
            }
            else {
                if ( variables.settings.maskRestrictedKeys && isValid("string", arguments.obj[_local.key]) ) {
                    _ret[_local.key] = len(arguments.obj[_local.key]) > 0 ?  repeatString("*", len(arguments.obj[_local.key])) : "Value was empty.";
                }
                else {
                    _ret[_local.key] = "Value removed by Snitch.";
                }
            }
        }
        return _ret;
    }

    private void function saveToLogFile( required struct obj ) {
        var _fileName = generateLogFileName( arguments.obj['key'] );
        var _fileObj = {
            'count' = 1,
            'lastOccurance' = "",
            'exceptions' = []
        };
        lock name=arguments.obj['key'] timeout=1 type="exclusive" {
            if ( fileExists( _fileName ) ) {
                _fileObj = deserializeJSON( fileRead( _fileName, "utf-8" ) );
                _fileObj['count'] = val(_fileObj['count']) + 1;
            }

            _fileObj['lastOccurance'] = dateFormat( now(), "mm/dd/yyyy" ) & " " & timeFormat( now(), "hh:mm:ss tt" );

            if ( _fileObj['count'] == 1 || !variables.settings.onlySaveNew ) {
                arrayAppend( _fileObj['exceptions'], arguments.obj );
            }

            fileWrite( _fileName, serializeJSON(_fileObj), "utf-8" );
        }
    }

    private void function sendEmailAlert( required struct obj ) {
        var _local = {};
        _local.key = "";
        if ( !variables.settings.onlySendNew || !fileExists( generateLogFileName( arguments.obj['key'] ) ) ) {
            savecontent variable="_emailHTMLContent" {
                writeOutput("<h3>Snitch tracked an exception, " & arguments.obj['key'] & ", details are as follows:</h3><br/><br />");
                for ( _local.key in arguments.obj ) {
                    writeDump( label=_local.key, var=arguments.obj[_local.key] );
                    writeOutput("<br />");
                }
                writeOutput("<br />Please visit your Snitch installation for more details.");
            }
            savecontent variable="_emailTextContent" {
                writeOutput("Snitch tracked an exception, key: " & arguments.obj['key'] & ", please visit your Snitch installation for more details.");
            }

            var mail = new mail();
            mail.setSubject( "[" & variables.settings.applicationName & "] Snitch tracked exception " & arguments.obj['key'] );
            mail.setFrom( variables.settings.emailFrom );
            mail.setTo( variables.settings.emailTo );

            mail.addPart( type="html", charset="utf-8", body=trim( _emailHTMLContent ) );
            mail.addPart( type="text", charset="utf-8", wraptext="72", body=trim( _emailTextContent ) );

            mail.send();
        }
    }

    private void function throwError( string errorcode="snitch_no_errorcode_provided", string message="No error message provided.", string detail="" ) {
        throw( type="Snitch", errorcode=arguments.errorCode, message=arguments.message, detail=(len(trim(arguments.detail))) ? arguments.detail : arguments.message );
    }
}