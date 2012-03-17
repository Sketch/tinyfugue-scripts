; Name: Repost
; Lowest tested version: tf 5.0b8
; Source: https://raw.github.com/Sketch/tinyfugue-scripts/HEAD/rp/repost.tf
; Author: Sketch@M*U*S*H
; REQUIRE: vworld.tf https://raw.github.com/Sketch/tinyfugue-scripts/HEAD/lib/vworld.tf
; Notice: This script requires the 'cut' coreutil.
;
; Purpose:
;  Assists the user in reposting lines from logs.
;
; Usage:
;  /repost presents the user with a list of recent log files.
;  Default length of log file list is 10. Change it with:
;  /set repost_queue_size=11
;
;  Typing /repost <LOGFILE> opens a virtual world and prints out all
;  lines, numbered from the top.
;  Type in line numbers to paste them back to the originating world.
;   Example: 1-5 8 10
;  Pastes lines 1, 2, 3, 4, 5, 8, and 10 back to origin world.
;  Pasted lines will have %{repost_prefix} as a prefix.
;  repost_prefix defaults to "@emit/noeval ". Change it with:
;  /set repost_prefix=spoof/noeval
;  The trailing space is important!

; Scripter's notes:
; 'repost_queue' is a list of uniquely-named recently opened logs.
; 'repost_queue_length' keeps track of its current length.
; 
; The variables _repost_filename_<WORLDNAME> = <LOGFILE>
; keep track of what logfile is being used for each (virtual) world.

; To-Do:
;  * Add '/repost this' to repost from current logfile.
;  * Add repost_prefix altering option to /repost
;  * Make /repost DIRNAME print a list of files in that directory.
;  * Make /repost FILENAME print near matches in that directory.
;  * Figure out how to /quote to virtual world without /fg it first, so that
;    a player's terminal isn't bombed by 300KB+ of logfile text at once.
;    ^ Maybe use tail -1000, with a /repost -a option to load the whole file?
;  * The core function, /_repost_sender, will NOT work with
;    alternate-encoding (including any Unicode) files. Fix it....somehow.
;  * Add different (default?) repost_prefixes for different world types.

/loaded sketch_repost.tf
/require vworld.tf
/require stack-q.tf
/require textencode.tf

/eval /set repost_queue_size=%{repost_queue_size-10}
/eval /set repost_queue_length=%{repost_queue_length-0}
/eval /set repost_prefix=%{repost_prefix-@emit/noeval }

; Keep track of recent logfiles
/def -iF -h"LOG" repost_log_hook=\
  /let filename=$[textencode({1})]%;\
  /if (strstr({repost_queue},{filename}) == -1)\
    /enqueue %{filename} repost_queue%;\
    /test ++repost_queue_length%;\
    /if ({repost_queue_length} > {repost_queue_size})\
      /test $(/dequeue repost_queue)%;\
      /test --repost_queue_length%;\
    /endif%;\
  /endif

; List recent logfiles
/def -i _repost_list=\
  /let i=%{repost_queue_length}%;\
  /_echo %% List of recent logs:%;\
  /while (i > 0)\
    /let filename=$(/dequeue repost_queue)%;\
    /_echo %% $[textdecode({filename})]%;\
    /enqueue %{filename} repost_queue%;\
    /test --i%;\
  /done

; Master command.
; /repost           - Call _repost_list to print a list of recent logs.
; /repost <logfile> - Open virtual world with line numbered from bottom.
;
; _repost_file line checks if var _repost_filename_<CURRENT_WORLD> exists.
; If it does, we have a logfile/virtual world open for this world already.
/def -i repost=\
  /if ({#} == 0)\
    /_repost_list%;\
    /return%;\
  /endif%;\
  /eval /set _repost_file=%%{_repost_filename_$[textencode(${world_name})]}%;\
  /if ({_repost_file} =~ '') \
    /let file=$[filename({*})]%;\
    /if ($(/quote -S -decho !test -r %{file};echo \$?) == 0)\
      /_repost_open_vworld ${world_name} %{file}%;\
    /else \
      /if ($(/quote -S -decho !test -f %{file};echo \$?) == 0)\
        /echo -e File \"%{file}\" not readable.%;\
      /else \
        /echo -e No such file \"%{file}\".%;\
      /endif%;\
    /endif%;\
  /else \
    /echo -e This world already has a repost world open!%;\
  /endif%;\
  /unset _repost_file

; Create virtual world for repostr, print out lines with linenumbers.
; {1} = world name
; {-1} = log file name
/def -i _repost_open_vworld=\
  /set _repost_filename_$[textencode({1})]=%{-1}%;\
  /vw_create -s/_repost_sender -tNoLog repost_%{1}%;\
  /fg repost_%{1}%;\
  /quote -S -decho -wrepost_%{1} !"nl -w1 -ba %{-1}"%;\
  /echo -p %% Lines will be pasted with "@{B}%{repost_prefix}@{n}" as a prefix.%;\
  /echo -p %% Foregrounded repost world. Type "@{B}.@{n}" to exit.

; Close the repostr virtual world.
; {1} is repost_<WORLDNAME>
/def -i _repost_close_vworld=\
  /let current=${world_name}%;\
  /let origin=$[substr({1},strchr({1},'_')+1)]%;\
  /unset _repost_filename_$[textencode({origin})]%;\
  /vw_delete %{1}%;\
  /if ({current} =~ {1}) /fg %{origin}%; /endif%;\

; The send-handler for the virtual repost world.
; {1} is repost_<WORLDNAME>
; {-1} is the text the user typed.
/def -i _repost_sender=\
  /let chosen=$[replace(' ',',',_repost_squish({-1}))]%;\
  /let origin=$[substr({1},strchr({1},'_')+1)]%;\
  /if (regmatch('^[-,0-9]+$',{chosen}) != 0)\
    /let delim=\0x1A%;\
    /eval /set _repost_file=%%{_repost_filename_$[textencode({origin})]}%;\
    /quote -0.1 -dsend -w%{1} >REROUTE> !"tr '\\\\n' '%{delim}' < %{_repost_file} | cut -d\'%{delim}\' --fields=%{chosen} | tr '%{delim}' '\\\\n'"%;\
    /unset _repost_file%;\
  /elseif ({-1} =/ ">REROUTE>*") \
;    /eval /set _world_repost_prefix=%%{_repost_prefix_$[textencode(${world_type})]}%;\
    /echo -w%{1} $[substr({-1},strlen(">REROUTE>"))]%;\
    /send -w%{origin} $[strcat({repost_prefix},substr({-1},strlen(">REROUTE>")))]%;\
;    /unset _world_repost_prefix;\
  /elseif ({chosen} =~ '.') \
    /_repost_close_vworld %{1}%;\
  /endif

;; INLINED: https://raw.github.com/Sketch/tinyfugue-scripts/HEAD/squish.tf
;;  _repost_squish(s1)
;;  _repost_squish(s1, s2)
;;          (str) Returns <s1> with runs of <s2> (default space) compressed
;;          into one occurrence.
/def -i _repost_squish=\
  /let squishstring=%{1}%;\
  /let squishchar=$[({#} > 1) ? {2} : " "]%;\
  /while (strstr({squishstring}, strrep({squishchar}, 2)) > -1) \
    /test squishstring := replace(strrep({squishchar}, 2), \
                                  {squishchar}, \
                                  {squishstring}) %;\
  /done%;\
  /return {squishstring}
