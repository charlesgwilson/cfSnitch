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
component output="false" displayname="HipChat Notification" hint="HipChat notification for cfSnitch" {

    public void function process( required struct exception, required boolean isNewException, required struct snitchSettings, required struct pluginSettings ) {
        var _local = {};
        var _http = new http();

        if ( arguments.isNewException || !arguments.pluginSettings.onlyNotifyNew ) {
            _local['color'] = (arguments.isNewException) ? 'red' : 'yellow';
            _local['message'] = '[<a href="'&arguments.snitchSettings.url&'">' & arguments.snitchSettings.applicationName & '</a>] Snitch tracked an exception, ' & arguments.exception['key'] & ', please visit your Snitch installation for more details. (<a href="'&arguments.snitchSettings.url&'?id='&arguments.exception['key']&'">View</a>)';
            _local['notify'] = true;
            _local['message_format'] = 'html';

            _http.setURL("https://api.hipchat.com/v2/room/"&arguments.pluginSettings.room&"/notification?auth_token="&arguments.pluginSettings.authtoken);
            _http.setMethod("POST");
            _http.setTimeout(60);
            _http.addParam( type="header", name="Content-Type", value="application/json" );
            _http.addParam( type="body", value="#serializeJSON(_local)#" ); 
            _http.send();
        }
    }
}