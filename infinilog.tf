; Name: Infinilog
; Version: 1.3
; Lowest tested version: tf 5.0b8
; Source: https://raw.github.com/Sketch/tinyfugue-scripts/HEAD/infinilog.tf
; Author: Sketch@M*U*S*H
; REQUIRE: assoc.tf http://diamond-age.net/~aiviru/assoc.tf
;
; Purpose:
;  Auto-log upon connection to a world and roll over to a new log each day.
;
; Important notes:
;  This script overrides the built-in /dc and /log so that:
;   /dc calls the inflog_hook_disconnect hook.
;   /log off and /log -w[World] off call /inflog to resume managed logging.
;  You can use /@log off and /@log -w[World] off to really stop logging,
;   or comment out the relevant code below if you really hate this behavior.
;
; Usage:
;  /require infinilog.tf in your .tfrc.
;  You should probably read below for more details.
;
;  Logs are managed such that if you use /log to log to a different filename
;  that isn't the inflog_fileformat's format with today's date, it won't
;  roll over the log to the next day. This is intentional, and done so you
;  can individually log your roleplay/combat however you like.
;  Be sure to use /inflog, not /log -w off, 
;
;  Worlds with 'NoLog' in their world type will not be logged.
;  /set inflog_fileformat in your .tfrc before loading this script to change
;  where infinilog logs to. It defaults to logging to:
;   ~/logs/auto/{WORLDNAME}.YYYY-MM-DD.txt
;  inflog_fileformat will be parsed in ftime() (see /help ftime()) and
;  then [W] will be replace()d by the relevant worldname.
;
; Timestamps:
;  If you want timestamps echoed to managed worlds on the hour, run
;  /inflog_hourly after loading this script.
;  If you want to change the message that is echoed on the hour,
;  /set inflog_hourly_stamp to an ftime()-combatible string.
;  inflog_hourly_stamp defaults to "[%H:00]".
;  By default, the messages will only be sent to managed worlds.
;  /set inflog_hourly_style=all to send the messages to all worlds.
;  /set inflog_hourly_style=auto is the default.
;  Worlds with 'NoStamp' in their world type will not receive timestamps.
;
; Status field:
;  If you want the @log status field to be an "(Auto)" (by default) or
;  "A" (if you've loaded one of the activity_status.tf scripts) when all
;  logs are being managed, run /inflog_status after loading this script.
;
; 
; Notes to scripters:
;  * The function inflog_all_managed() returns nonzero if all worlds are
;    logging to managed log files.
;  * Check near the bottom of the field for how to set up the status field.
;    Some extra code is provided for your convenience.
;  * /log is overwritten to call /inflog to resume managed logging.
;  * /dc is overwritten so that the /inflog_hook_disconnect is called on /dc.
;  * If you need to override /dc or /log for your own purposes, you can call
;    infinilog's methods with /_inflog_dc and /_inflog_log, with the original
;    arguments to /dc or /log.
; 
; Improvements to be made:
; * The timers break during Daylight Saving Time transitions.
; 
; I've implemented everything I want. I'm Sketch@M*U*S*H
; (mush.pennmush.org 4201) if you want to suggest something.

/loaded infinilog.tf
/require assoc.tf
/require lisp.tf

; Default to logging to ~/logs/auto/{WORLDNAME}.YYYY-MM-DD.txt
/eval /set inflog_fileformat=%{inflog_fileformat-~/logs/auto/[W].%%F.txt}
/eval /set inflog_hourly_stamp=%{inflog_hourly_stamp-[%%H:00]}
/eval /set inflog_hourly_style=%{inflog_hourly_style-auto}
; inflog_log is passed the desired world name as %{1}
/def -i inflog_logname=/return replace('[W]',{1},ftime({inflog_fileformat}))

; inflog is passed the desired world name as %{1}, or none at all (current world).
/def -i inflog=\
  /let logfile=$[filename(inflog_logname({1-${world_name}}))]%;\
  /assoc infinilog %{1-${world_name}}=%{logfile}%;\
  /log -w%{1-${world_name}} %{logfile}%;\
  /inflog_update_status_field

; Check if world {1} is being logged to {2}.
/def -i inflog_isloggingto=/return $[strstr($(/log),strcat('% Logging world ',{1},' output to ',{2})) != -1]

; Start logging on connect, if the user isn't logging something already.
/def -iF -h"CONNECT" inflog_hook_connect=\
  /let logfile=$[filename(inflog_logname({1-${world_name}}))]%;\
  /assoc infinilog %{1-${world_name}}=%{logfile}%;\
  /if (!inflog_isloggingto({1},''))\
    /if (toupper(world_info({1},'type')) !/ '*NOLOG*') \
      /inflog %{1}%;\
    /endif%;\
  /endif%;\
  /inflog_update_status_field

; Kill managed logs if they're still logging to the stored logfile.
/def -iF -h"DISCONNECT" inflog_hook_disconnect=\
  /let logfile=$(/rassoc infinilog %{1})%;\
  /if (!inflog_isloggingto({1},''))\
    /assoc infinilog %{1}%;\
  /elseif (inflog_isloggingto({1},{logfile}))\
    /assoc infinilog %{1}%;\
    /@log -w%{1} off%;\
  /endif%;\
  /inflog_update_status_field

; Check and change the status field when the user logs.
/def -iF -h"LOG" inflog_hook_log=/repeat -0 1 /inflog_update_status_field

; Roll over the logs at midnight every day. Innermost code is at the top.
; %{*} is "infinilog <WORLDNAME>=<LOGFILE>"
/def -i _inflog_map_daily_cmd=\
  /split %{*}%;\
  /let Worldname=$(/rest %{P1})%;\
  /if (inflog_isloggingto({Worldname},{P2}))\
    /inflog %{Worldname}%;\
  /endif
/def -i inflog_daily_cmd=/mapassoc infinilog=/_inflog_map_daily_cmd %; /inflog_daily
/def -i inflog_daily=\
  /at 00:00:00 /inflog_daily_cmd%;\
  /set inflog_daily_id=%?
/eval /kill %{inflog_daily_id}
/inflog_daily

; Print hourly timestamps for managed worlds.
/def -i _inflog_map_hourly_cmd=\
  /split %{*}%;\
  /let Worldname=$(/rest %{P1})%;\
  /if ((toupper(world_info({Worldname},'type')) !/ '*NOSTAMP*') &\
         ( inflog_isloggingto({Worldname},{P2}) \
         | toupper({inflog_hourly_style}) =~ 'ALL')\
      )\
    /echo -aA -w%{Worldname} $[ftime({inflog_hourly_stamp})]%;\
  /endif
/def -i inflog_hourly_cmd=\
  /mapassoc infinilog=/_inflog_map_hourly_cmd%;\
  /inflog_hourly
/def -i inflog_hourly=\
  /kill %{inflog_hourly_id}%;\
  /at $[mod(ftime('%H')+1,24)]:00 /inflog_hourly_cmd%;\
  /set inflog_hourly_id=%?

;; Status field code
; Returns nonzero if all connected worlds use managed logging, zero otherwise.
/def -i inflog_all_managed=\
  /let all_auto=1%;\
  /mapassoc infinilog=/_inflog_all_managed%;\
  /result {all_auto}

; Inner loop for inflog_all_managed.
/def -i _inflog_all_managed=\
  /split %{*}%;\
  /let Worldname=$(/rest %{P1})%;\
  /if (!inflog_isloggingto({Worldname},{P2})) /test all_auto:=0%; /endif

/set inflog_status_short=nlog() ? (inflog_all_managed() ? "A" : "L") : ""
/set inflog_status_long=nlog() ? (inflog_all_managed() ? "(Auto)" : "(Log)") : ""
/set inflog=0
/def -i inflog_update_status_field=/test inflog := !{inflog}
/def -i inflog_status=\
  /let status_length=0%;\
  /if (status_fields() !/ "*@log*")\
    /_echo Couldn't replace status field--are you using a custom one?%;\
    /return%;\
  /endif%;\
  /if ({status_int_log} =~ 'nlog() ? "(Log)" : ""')\
    /eval /set status_var_inflog=%{inflog_status_long}%;\
    /let status_length=6%;\
  /elseif ({status_int_log} =~ 'nlog() ? "L" : ""')\
    /eval /set status_var_inflog=%{inflog_status_short}%;\
    /let status_length=1%;\
  /endif%;\
  /eval /status_add -A@log inflog:%{status_length}%;\
  /status_rm @log

;; Standard command redefinition

; %{*} is "infinilog <WORLDNAME>=<LOGFILE>"
/def -i _inflog_map_log=\
  /split %{*}%;\
  /let Worldname=$(/rest %{P1})%;\
  /inflog %{Worldname}
; Redefine /log so worlds become managed on /log off
/def -i log=/_inflog_log %{*}
/def -i _inflog_log=\
  /if (toupper({*}) =~ 'OFF')\
    /mapassoc infinilog=/_inflog_map_log%;\
    /_echo %% Now managing logs for all worlds.%;\
  /elseif (regmatch('^\\s*-w(.*)\\s+[Oo][Ff][Ff]$',{*})) \
    /if (strlen($(/listworlds -s %{P1}))) \
      /inflog %{P1}%;\
    /else \
;     The line below is intended to print the built-in error message.\
      /@log -w%{P1} off%;\
    /endif%;\
  /else \
    /@log %{*}%;\
  /endif%;\

; %{*} is "infinilog <WORLDNAME>=<LOGFILE>"
/def -i _inflog_map_dc=\
  /split %{*}%;\
  /let Worldname=$(/rest %{P1})%;\
  /inflog_hook_disconnect %{Worldname}
; Redefine /dc so the disconnect hook will work. Grumble.
/def -i dc=/_inflog_dc %{*}
/def -i _inflog_dc=\
  /@dc %{*}%;\
  /if (toupper({*}) =~ '-ALL')\
    /mapassoc infinilog=/_inflog_map_dc%;\
/else \
    /inflog_hook_disconnect %{*-${world_name}}%;\
 /endif

