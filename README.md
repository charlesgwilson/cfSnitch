cfSnitch
========

Snitch is an exception logger / tracker for ColdFusion and Railo

##This is no longer being maintaned and has been left up for reference purposes only
I appologize I never finished this, my team has been using Errbit along with the AirBrake Notifier for some time now and has been realy pleased with it. If you would like more information on how to set up Errbit or how the notifier works, please see the links below or feel free to contact me.

https://github.com/timblair/coldfusion-airbrake-notifier
https://github.com/charlesgwilson/mura-airbrake

How does it work? 
--------------------------
Simple, here's a quick example:

```
variables.snitch = createObject('org.snitch.snitch').init();
try {
        throw("Show how Snitch works!");
}
catch( any e ) {
       variables.snitch.log(e);
}
```

Snitch simply takes the exception, gathers other requested scopes, parses them to remove or mask any key values as defined in the settings and can either email the information to an email address, save it to a file, or both. 

What do the settings mean?
----------------------------------------
> applicationName=Snitch

Snitch uses the applicationName in the Subject line of the email to help you quickly decipher which application this error came from

> restrictedKeys=auth_password,password,creditcard,cc

restrictedKeys is a comma delimited list that Snitch uses to know what keys to make or remove so that sensitive information is not saved or emailed.

> maskRestrictedKeys=true

maskRestrictedKeys tells Snitch whether or not to replace the values with * (when true) or remove the value all together (when false)

> additionalScopes=form,url,session,cgi

additionalScopes is a comma delimited list that tells Snitch what all scopes you would like in your email or log along with the exception. These scopes are also parsed for restrictedKeys.

> logsFolder=/org/snitch/logs

logsFolder defines the location Snitch will use to save its logs.

> saveLog=true

saveLog defines whether or not you would like Snitch to save a log file

> onlySaveNew=false

onlySaveNew defines whether Snitch should save only new exceptions, or keep a record of each exception occurred. 

> sendEmail=false

sendEmail defines whether or not you would like to receive the log via email

> onlySendNew=false

onlySendNew defines whether Snitch should send only new exceptions, or every exception, regardless of if it has been hit before.

> emailFrom=test@email.com

emailFrom defines the email address Snitch should use to send emails from

> emailTo=test@email.com

emailTo defines the email address Snitch should send emails to

> useDefaultMailServer=true

useDefaultMailServer defines whether or not Snitch should use the default mail server in the ColdFusion/Railo Admin

> mailServerHost=

mailServerHost defines what host should be used when useDefaultMailServer is set to false

> mailServerPort=

mailServerPort defines what port should be used when useDefaultMailServer is set to false

> mailServerUsername=

mailServerUsername defines the username Snitch should use to connect to the mail server

> mailServerPassword=

mailServerPassword defines the password Snitch should use to connect to the mail server

> useSSL=false

useSSL defines whether or not Snitch should connect to the mail server using SSL

> useTLS=false

useTLS defines whether or not Snitch should connect to the mail server using TLS

What Overrides can be provided?
------------------------------------------------
The log method of Snitch accepts a second argument, a struct of overrides. Currently only two key are accepted, those are 'url' and 'client'. These provide a way for you to use Snitch to log JavaScript errors and override the URL and Client information.


What's left to be done?
----------------------------------
The web portal is still under construction to be able to view saved logs.

What's the estimated time frame on the web portal?
---------------------------------------------------------------------------
Soon :-)

Other information, if your bored...
-------------------------------------------------

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
