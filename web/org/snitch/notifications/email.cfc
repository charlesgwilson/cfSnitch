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
component output="false" displayname="eMail Notification" hint="eMail notification for cfSnitch" {

    public void function process( required struct exception, required boolean isNewException, required struct snitchSettings, required struct pluginSettings ) {
        var _local = {};
        var _mail = new mail();
        _local.key = "";
        if ( arguments.isNewException || !arguments.pluginSettings.onlySendNew ) {
            savecontent variable="_emailHTMLContent" {
                writeOutput("<h3>Snitch tracked an exception, " & arguments.exception['key'] & ", details are as follows:</h3><br/><br />");
                for ( _local.key in arguments.exception ) {
                    writeDump( label=_local.key, var=arguments.exception[_local.key] );
                    writeOutput("<br />");
                }
                writeOutput("<br />Please <a href='"&arguments.snitchSettings.url&"?id="&arguments.exception['key']&"'>visit your Snitch</a> installation for more details.");
            }
            savecontent variable="_emailTextContent" {
                writeOutput("Snitch tracked an exception, key: " & arguments.exception['key'] & ", please visit your Snitch installation for more details.");
            }

            _mail.setSubject( "[" & arguments.snitchSettings.applicationName & "] Snitch tracked exception " & arguments.exception['key'] );
            _mail.setFrom( arguments.pluginSettings.emailFrom );
            _mail.setTo( arguments.pluginSettings.emailTo );
            if ( !arguments.pluginSettings.useDefaultMailServer ) {
                _mail.setServer( arguments.pluginSettings.mailServerHost );
                _mail.setPort( arguments.pluginSettings.mailServerPort );
            }
            if ( len(trim(arguments.pluginSettings.mailServerUsername)) > 0 ) {
                _mail.setUsername( arguments.pluginSettings.mailServerUsername );
            }
            if ( len(trim(arguments.pluginSettings.mailServerPassword)) > 0 ) {
                _mail.setPassword( arguments.pluginSettings.mailServerPassword );
            }
            _mail.setUseSSL( arguments.pluginSettings.useSSL );
            _mail.setUseTLS( arguments.pluginSettings.useTLS );

            _mail.addPart( type="html", charset="utf-8", body=trim( _emailHTMLContent ) );
            _mail.addPart( type="text", charset="utf-8", wraptext="72", body=trim( _emailTextContent ) );

            _mail.send();
        }
    }
}