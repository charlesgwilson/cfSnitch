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
    public snitch function init( string settingsFile = getDirectoryFromPath(getCurrentTemplatePath()) & "config/settings.ini.cfm" ) {
        var _propertyFileGroups = getProfileSections( arguments.settingsFile );
        var _local = {};

        if ( !structKeyExists( _propertyFileGroups, "default" ) ) {
            throwError(errorcode="snitch_no_default_group", message="No default group in settings file.", detail="A default group of settings must be in the settings file.");
        }

        // Set reserved group names - names of groups not allowed as plugins
        variables.reservedGroupNames = "default,local,development,staging,production,snitch";

        // Create settings struct and load default values
        variables.settings = {};
        variables.settings['snitch'] = {};
        variables.settings['snitch']['applicationName'] = "Snitch_" & hash(GetCurrenttemplatepath());
        variables.settings['snitch']['restrictedKeys'] = "auth_password,password,creditcard,cc";
        variables.settings['snitch']['maskRestrictedKeys'] = true;
        variables.settings['snitch']['additionalScopes'] = "form,url,session,cgi";
        variables.settings['snitch']['logsFolder'] = "/org/snitch/logs";
        variables.settings['snitch']['saveLog'] = true;
        variables.settings['snitch']['onlySaveNew'] = false;
        variables.settings['snitch']['url'] = "";

        // Load default settings from file
        for ( _local.index = 1; _local.index <= listLen( _propertyFileGroups['default'] ); _local.index++ ) {
            _local.property = listGetAt( _propertyFileGroups['default'], _local.index );
            variables.settings['snitch'][_local.property] = getProfileString( arguments.settingsFile, 'default', _local.property );
        }

        // Load target environment settings from file, overriding default settings
        var _environment = getProfileString( arguments.settingsFile, "default", "environment" );

        if ( len(trim(_environment)) && structKeyExists( _propertyFileGroups, _environment ) ) {
            for ( _local.index = 1; _local.index <= listLen( _propertyFileGroups[_environment] ); _local.index++ ) {
                _local.property = listGetAt( _propertyFileGroups[_environment], _local.index );
                variables.settings['snitch'][_local.property] = getProfileString( arguments.settingsFile, _environment, _local.property );
            }
        }

        // Load settings for notification plugins
        for ( var _local.key in _propertyFileGroups ) {
            if ( !listFindNoCase( variables.reservedGroupNames, _local.key ) ) {
                variables.settings[_local.key] = {};
                
                for ( _local.index = 1; _local.index <= listLen( _propertyFileGroups[_local.key] ); _local.index++ ) {
                    _local.property = listGetAt( _propertyFileGroups[_local.key], _local.index );
                    variables.settings[_local.key][_local.property] = getProfileString( arguments.settingsFile, _local.key, _local.property );
                }
            }
        }

        return this;
    }

    /**
     * Public methods
     */
    public void function delete( required string logID ) {
        var _fileName = generateLogFileName( arguments.logID );
        if ( fileExists( _fileName ) ) {
            fileDelete( _fileName );
        }
    }

    public struct function get( required string logID ) {
        var _ret = {};
        var _fileName = generateLogFileName( arguments.logID );
        if ( fileExists( _fileName ) ) {
            _ret = deserializeJSON( fileRead( _fileName, "utf-8" ) );
        }
        return _ret;
    }

    public query function list() {
        return directoryList( expandPath( variables.settings.snitch.logsFolder ), true, "query",  "*.log", "datelastmodified DESC" );
    }

    public void function log( required any exception, struct overrides = {} ) {
        var _local = {};
        _local.log = {};
        _local.log['exception'] = parseException( arguments.exception, arguments.overrides );
        _local.log['scopes'] = parseAdditionalScopes();
        _local.log['key'] = generateKey( _local.log['exception'] );
        _local.log['timeStamp'] = now();
        _local.isNewException = !fileExists( generateLogFileName( _local.log['key'] ) );
        _local.key = "";
        _local.plugin = "";

        if ( variables.settings.snitch.saveLog ) {
            saveToLogFile( _local.log, _local.isNewException );
        }

        for ( _local.key in variables.settings ) {
            if ( !listFindNoCase( variables.reservedGroupNames, _local.key ) && variables.settings.snitch[_local.key] && fileExists( getDirectoryFromPath(getCurrentTemplatePath()) & "notifications/"&lCase(_local.key)&".cfc" ) ) {
                _local.plugin = createObject( "component",  "notifications/"&lCase(_local.key) );
                _local.plugin.process( exception=_local.log, isNewException=_local.isNewException, snitchSettings=variables.settings.snitch, pluginSettings=variables.settings[_local.key] );
            }
        }
    }

    /**
     * Private methods
     */
    private string function generateKey( required struct exception ) {
        var _ret = "";
        var _stacktrace = "";
        if ( len(trim(arguments.exception.stacktrace)) ) {
            _stacktrace = reMatch("[\w.\$]*\([\w.:\\/]*\)", lCase(trim(arguments.exception.stacktrace)));
            _ret = lCase( hash( arrayToList(_stacktrace, ","), "SHA" ) );
        }
        else if ( len(trim(arguments.exception.message)) ) {
            _ret = lCase( hash( lCase( trim(arguments.exception.message) ), "SHA" ) );
        }
        return ( len(trim(_ret)) ) ? _ret : lCase( hash( getTickCount(), "SHA" ) );
    }

    private string function generateLogFileName( required string key ) {
        return expandPath(variables.settings.snitch.logsFolder & "/" & arguments.key & ".log");
    }

    private struct function parseAdditionalScopes() {
        var _ret = {};
        var _local = {};
        _local.scope = "";
        _local.index = 1;
        if ( len(trim(variables.settings.snitch.additionalScopes)) ) {
            for ( _local.index = 1; _local.index <= listLen(variables.settings.snitch.additionalScopes, ","); _local.index++ ) {
                _local.scope = listGetAt(variables.settings.snitch.additionalScopes, _local.index, ",");
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
            if ( !listFindNoCase( variables.settings.snitch.restrictedKeys, _local.key ) ) {
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
                if ( variables.settings.snitch.maskRestrictedKeys && isValid("string", arguments.obj[_local.key]) ) {
                    _ret[_local.key] = len(arguments.obj[_local.key]) > 0 ?  repeatString("*", len(arguments.obj[_local.key])) : "Value was empty, Snitch had nothing to mask.";
                }
                else {
                    _ret[_local.key] = "Value removed by Snitch.";
                }
            }
        }
        return _ret;
    }

    private void function saveToLogFile( required struct obj, required boolean isNewException ) {
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

            if ( isNewException || !variables.settings.snitch.onlySaveNew ) {
                arrayAppend( _fileObj['exceptions'], arguments.obj );
            }

            fileWrite( _fileName, serializeJSON(_fileObj), "utf-8" );
        }
    }

    private void function throwError( string errorcode="snitch_no_errorcode_provided", string message="No error message provided.", string detail="" ) {
        throw( type="Snitch", errorcode=arguments.errorCode, message=arguments.message, detail=(len(trim(arguments.detail))) ? arguments.detail : arguments.message );
    }
}