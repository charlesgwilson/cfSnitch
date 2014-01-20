<cfabort/>
[default]
environment=local
restrictedKeys=auth_password,password,creditcard,cc
maskRestrictedKeys=true
additionalScopes=form,url,session,cgi
logsFolder=/org/snitch/logs
saveLog=true
onlySaveNew=false

[local]
applicationName=Snitch_Local
url=http://snitch.local/org/snitch/dashboard/index.cfm
email=false
hipchat=true

[staging]
applicationName=Snitch_Staging
url=http://snitch.local/org/snitch/dashboard/index.cfm
email=false
hipchat=false

[production]
applicationName=Snitch_Production
url=http://snitch.local/org/snitch/dashboard/index.cfm
email=false
hipchat=false

[email]
onlySendNew=false
emailFrom=test@email.com
emailTo=test@email.com
useDefaultMailServer=true
mailServerHost=
mailServerPort=
mailServerUsername=
mailServerPassword=
useSSL=false
useTLS=false

[hipchat]
onlyNotifyNew=false
authtoken=Gy2YhsGqvspNsqqDVwDhim9oGrBUiMFSyp2IgaDs
room=406573