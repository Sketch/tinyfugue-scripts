; Name: Re-pose
; Version: 1.2
; Lowest tested version: tf 5.0b8
; Source: https://raw.github.com/Sketch/tinyfugue-scripts/HEAD/repose.tf
; Author: Sketch@M*U*S*H
; REQUIRE: vworld.tf http://diamond-age.net/~aiviru/vworld.tf
; Notice: This script requires the 'cut' coreutil.
;
; Purpose:
;  Assists the user in reposing lines from logs.
;
; Usage:
;  /repose presents the user with a list of recent log files.
;  Default length of log file list is 10. Change it with:
;  /set repose_queue_size=11
;
;  Typing /repose <LOGFILE> opens a virtual world and prints out all
;  lines, numbered from the top.
;  Type in line numbers to paste them back to the originating world.
;   Example: 1-5 8 10
;  Pastes lines 1, 2, 3, 4, 5, 8, and 10 back to origin world.
;  Pasted lines will have %{repose_prefix} as a prefix.
;  repose_prefix defaults to "@emit/noeval ". Change it with:
;  /set repose_prefix=spoof/noeval 
;  The trailing space is important!

; Scripter's notes:
; 'repose_queue' is a list of uniquely-named recently opened logs.
; 'repose_queue_length' keeps track of its current length.
; 
; The variables _repose_filename_<WORLDNAME> = <LOGFILE>
; keep track of what logfile is being used for each (virtual) world.

; To-Do:
;  * Add '/repose this' to repose from current logfile.
;  * Add repose_prefix altering option to /repose
;  * Make /repose DIRNAME print a list of files in that directory.
;  * Make /repose FILENAME print near matches in that directory.
;  * Figure out how to /quote to virtual world without /fg it first, so that
;    a player's terminal isn't bombed by 300KB+ of logfile text at once.
;    ^ Maybe use tail -1000, with a /repose -a option to load the whole file?
;  * The core function, /_repose_sender, will NOT work with
;    alternate-encoding (including any Unicode) files. Fix it....somehow.
;  * Add different (default?) repose_prefixes for different world types.

/loaded sketch_repose.tf
/require vworld.tf
/require stack-q.tf
/require textencode.tf

/eval /set repose_queue_size=%{repose_queue_size-10}
/eval /set repose_queue_length=%{repose_queue_length-0}
/eval /set repose_prefix=%{repose_prefix-@emit/noeval }

; Keep track of recent logfiles
/def -iF -h"LOG" repose_log_hook=\
  /let filename=$[textencode({1})]%;\
  /if (strstr({repose_queue},{filename}) == -1)\
    /enqueue %{filename} repose_queue%;\
    /test ++repose_queue_length%;\
    /if ({repose_queue_length} > {repose_queue_size})\
      /test $(/dequeue repose_queue)%;\
      /test --repose_queue_length%;\
    /endif%;\
  /endif

; List recent logfiles
/def -i _repose_list=\
  /let i=%{repose_queue_length}%;\
  /_echo %% List of recent logs:%;\
  /while (i > 0)\
    /let filename=$(/dequeue repose_queue)%;\
    /_echo %% $[textdecode({filename})]%;\
    /enqueue %{filename} repose_queue%;\
    /test --i%;\
  /done

; Master command.
; /repose           - Call _repose_list to print a list of recent logs.
; /repose <logfile> - Open virtual world with line numbered from bottom.
;
; _repose_file line checks if var _repose_filename_<CURRENT_WORLD> exists.
; If it does, we have a logfile/virtual world open for this world already.
/def -i repose=\
  /if ({#} == 0)\
    /_repose_list%;\
    /return%;\
  /endif%;\
  /eval /set _repose_file=%%{_repose_filename_$[textencode(${world_name})]}%;\
  /if ({_repose_file} =~ '') \
    /let file=$[filename({*})]%;\
    /if ($(/quote -S -decho !test -r %{file};echo \$?) == 0)\
      /_repose_open_vworld ${world_name} %{file}%;\
    /else \
      /if ($(/quote -S -decho !test -f %{file};echo \$?) == 0)\
        /echo -e File \"%{file}\" not readable.%;\
      /else \
        /echo -e No such file \"%{file}\".%;\
      /endif%;\
    /endif%;\
  /else \
    /echo -e This world already has a repose world open!%;\
  /endif%;\
  /unset _repose_file

; Create virtual world for reposer, print out lines with linenumbers.
; {1} = world name
; {-1} = log file name
/def -i _repose_open_vworld=\
  /set _repose_filename_$[textencode({1})]=%{-1}%;\
  /vw_create -s/_repose_sender -tNoLog repose_%{1}%;\
  /fg repose_%{1}%;\
  /quote -S -decho -wrepose_%{1} !"nl -w1 -ba %{-1}"%;\
  /echo -p %% Lines will be pasted with "@{B}%{repose_prefix}@{n}" as a prefix.%;\
  /echo -p %% Foregrounded repose world. Type "@{B}.@{n}" to exit.

; Close the reposer virtual world.
; {1} is repose_<WORLDNAME>
/def -i _repose_close_vworld=\
  /let current=${world_name}%;\
  /let origin=$[substr({1},strchr({1},'_')+1)]%;\
  /unset _repose_filename_$[textencode({origin})]%;\
  /vw_delete %{1}%;\
  /if ({current} =~ {1}) /fg %{origin}%; /endif%;\

; The send-handler for the virtual repose world.
; {1} is repose_<WORLDNAME>
; {-1} is the text the user typed.
/def -i _repose_sender=\
  /let chosen=$[replace(' ',',',_repose_squish({-1}))]%;\
  /let origin=$[substr({1},strchr({1},'_')+1)]%;\
  /if (regmatch('^[-,0-9]+$',{chosen}) != 0)\
    /let delim=\0x1A%;\
    /eval /set _repose_file=%%{_repose_filename_$[textencode({origin})]}%;\
    /quote -0.1 -dsend -w%{1} >REROUTE> !"tr '\\\\n' '%{delim}' < %{_repose_file} | cut -d\'%{delim}\' --fields=%{chosen} | tr '%{delim}' '\\\\n'"%;\
    /unset _repose_file%;\
  /elseif ({-1} =/ ">REROUTE>*") \
;    /eval /set _world_repose_prefix=%%{_repose_prefix_$[textencode(${world_type})]}%;\
    /echo -w%{1} $[substr({-1},strlen(">REROUTE>"))]%;\
    /send -w%{origin} $[strcat({repose_prefix},substr({-1},strlen(">REROUTE>")))]%;\
;    /unset _world_repose_prefix;\
  /elseif ({chosen} =~ '.') \
    /_repose_close_vworld %{1}%;\
  /endif

;; INLINED: http://diamond-age.net/~aiviru/squish.tf
;;  repose_squish(s1)
;;  repose_squish(s1, s2)
;;          (str) Returns <s1> with runs of <s2> (default space) compressed
;;          into one occurrence.
/def -i _repose_squish=\
  /let squishstring=%{1}%;\
  /let squishchar=$[({#} > 1) ? {2} : " "]%;\
  /while (strstr({squishstring}, strrep({squishchar}, 2)) > -1) \
    /test squishstring := replace(strrep({squishchar}, 2), \
                                  {squishchar}, \
                                  {squishstring}) %;\
  /done%;\
  /return {squishstring}
