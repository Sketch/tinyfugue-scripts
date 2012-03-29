; Name: Repost
; Lowest tested version: tf 5.0b8
; Source: https://raw.github.com/Sketch/tinyfugue-scripts/HEAD/rp/repost.tf
; Author: Sketch@M*U*S*H
; REQUIRE: vworld.tf https://raw.github.com/Sketch/tinyfugue-scripts/HEAD/lib/vworld.tf
; REQUIRE: squish.tf https://raw.github.com/Sketch/tinyfugue-scripts/HEAD/lib/squish.tf
; Notice: This script requires the 'cut' coreutil. (optionally 'ls')
;
; Purpose:
;  Assists the user in reposting lines from logs.
;
; Usage:
;  Typing /repost on its own displays a list of recently-opened log files.
;  Typing /repost with an argument does one of two things:
;  If the argument is not the name of a regular file, it is treated as a
;  pattern, and a list of matching filenames is displayed.
;  If the argument is the name of a regular file, a virtual world is opened
;  which contains every line in the file numbered from the beginning.
;  In a virtual world, type in line numbers to paste them back to the
;  originating world.
;  For example, typing "1-5 8 10" in the virtual world pastes lines
;  1, 2, 3, 4, 5, 8, and 10 back to origin world.
;
;  Lines chosen will be pasted back into the origin world with a prefix based
;  on worldtype. When in a virtual world, typing "PREFIX <newprefix>" will
;  change the paste prefix temporarily. To change a prefix permanently,
;  correctly set the worldtype for the given world when doing /addworld, and
;  "/set repost_prefix_<worldtype>=<prefix>", replacing full stops with
;  underscores. The code will progressively check for variables that are the
;  prefix of the given worldtype, falling back to repost_prefix.
;  Example:
;   For a worldtype 'madeup.worldtype.', the code checks for variables to use
;   as paste prefixes in this order: repost_prefix_madeup_worldtype_ ->
;   repost_prefix_madeup_worldtype -> repost_prefix_madeup -> repost_prefix.
;  A number of defaults are already defined below the line marked [PREFIXES].
;  Feel free to add your own, and please submit them to me for inclusion.
;
;  Default length of recent log file listing queue is 10. Change it with:
;  /set repost_queue_size=11
;
;
; Scripter's notes:
; 'repost_queue' is a list of uniquely-named recently opened logs.
; 'repost_queue_length' keeps track of its current length.
;
; The variables _repost_filename_<WORLDNAME> = <LOGFILE>
; keep track of what logfile is being used for each (virtual) world.

; To-Do:
;  * Give user tighter control of leading space when reposting.
;  * Add default directory option.
;  * Figure out how to /quote to virtual world without /fg it first, so that
;    a player's terminal isn't bombed by 300KB+ of logfile text at once.
;    ^ Maybe use tail -1000, with a /repost -a option to load the whole file?
;  * The core function, /_repost_sender, will NOT work with
;    alternate-encoding (including any Unicode) files. Fix it....somehow.

/loaded sketch_repost.tf
/require vworld.tf
/require squish.tf
/require stack-q.tf
/require textencode.tf

/eval /set repost_queue_size=%{repost_queue_size-10}
/eval /set repost_queue_length=%{repost_queue_length-0}
; [PREFIXES] Worldtype repost_prefix definitions. Feel free to add your own!
/set repost_prefix_tiny_penn=@emit/noeval
/set repost_prefix_tiny_tmux=@nemit
/set repost_prefix_tiny_rhost=]@emit
/set repost_prefix_tiny=@emit
/set repost_prefix=say

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
; /repost <pattern> - List all matching filenames.
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
    /if ($(/quote -S -decho !test -r %{file} && test -f %{file} ; echo \$?) =~ '0')\
      /_repost_open_vworld ${world_name} %{file}%;\
    /else \
      /if ($(/quote -S -decho !test -f %{file};echo \$?) =~ '0')\
        /echo -e File \"%{file}\" not readable.%;\
      /else \
        /if ($(/quote -S -decho !ls -dF %{file} > /dev/null;echo \$?) =~ '0')\
          /echo %% No such regular file \"%{file}\". Partial matches follow:%;\
          /quote -S -decho !"ls -dF %{file}"%;\
        /elseif ($(/quote -S -decho !ls -dF *%{file}* > /dev/null;echo \$?) =~ '0')\
          /echo %% No such regular file \"%{file}\". Partial matches follow:%;\
          /quote -S -decho !"ls -dF *%{file}*"%;\
        /else \
          /echo %% No such regular file \"%{file}\". No partial matches found.%;\
       /endif%;\
      /endif%;\
    /endif%;\
  /else \
    /echo -e This world already has a repost world open!%;\
  /endif%;\
  /unset _repost_file

/def -i _repost_message_foregrounded=\
  /echo -p %% To change the output prefix, type "@{B}PREFIX <new prefix>@{n}".%;\
  /echo -p %% To exit, type "@{B}.@{n}".
/def -i _repost_message_prefix=\
  /echo -p %% Lines will be pasted with "@{B}%{*} @{n}" as a prefix.

; Create virtual world for reposter, print out lines with linenumbers.
; {1} = world name
; {-1} = log file name
/def -i _repost_open_vworld=\
  /let escaped_worldname=$[textencode({1})]%;\
  /let worldtype=$[squish(strcat('_',replace('.','_',world_info({1},'type'))),'_')]%;\
  /while ({_final_repost_prefix} =~ '')\
	  /eval /set _final_repost_prefix=%%{repost_prefix%{worldtype}}%;\
	  /let worldtype=$[substr({worldtype},0,strrchr({worldtype},'_'))]%;\
  /done%;\
  /set _repost_prefix_%{escaped_worldname}=%{_final_repost_prefix}%;\
  /set _repost_filename_%{escaped_worldname}=%{-1}%;\
  /vw_create -s/_repost_sender -tNoLog repost_%{1}%;\
  /fg repost_%{1}%;\
  /quote -S -decho -wrepost_%{1} !"nl -w1 -ba %{-1}"%;\
  /eval /_repost_message_prefix %%{_repost_prefix_%{escaped_worldname}}%;\
  /_repost_message_foregrounded%;\
  /unset _final_repost_prefix

; Close the reposter virtual world.
; {1} is repost_<WORLDNAME>
/def -i _repost_close_vworld=\
  /let current=${world_name}%;\
  /let origin=$[substr({1},strchr({1},'_')+1)]%;\
  /unset _repost_filename_$[textencode({origin})]%;\
  /unset _repost_prefix_$[textencode({origin})]%;\
  /vw_delete %{1}%;\
  /if ({current} =~ {1}) /fg %{origin}%; /endif

; The send-handler for the virtual repost world.
; {1} is repost_<WORLDNAME>
; {-1} is the text the user typed.
/def -i _repost_sender=\
  /let chosen=$[replace(' ',',',squish({-1}))]%;\
  /let origin=$[substr({1},strchr({1},'_')+1)]%;\
  /if (regmatch('^[-,0-9]+$',{chosen}) != 0)\
    /let delim=\0x1A%;\
    /eval /set _repost_file=%%{_repost_filename_$[textencode({origin})]}%;\
    /quote -0.1 -dsend -w%{1} >REROUTE> !"tr '\\\\n' '%{delim}' < %{_repost_file} | cut -d\'%{delim}\' --fields=%{chosen} | tr '%{delim}' '\\\\n'"%;\
    /unset _repost_file%;\
  /elseif ({-1} =/ ">REROUTE>*") \
    /eval /set _repost_prefix=%%{_repost_prefix_$[textencode({origin})]}%;\
    /echo -w%{1} $[substr({-1},strlen(">REROUTE>"))]%;\
    /send -w%{origin} $[strcat({_repost_prefix},substr({-1},strlen(">REROUTE>")))]%;\
    /unset _repost_prefix%;\
  /elseif ({-1} =/ "PREFIX *") \
    /let newprefix=$[substr({-1},strlen("PREFIX "))]%;\
    /set _repost_prefix_$[textencode({origin})]=%{newprefix}%;\
    /_repost_message_prefix %{newprefix}%;\
  /elseif ({chosen} =~ '.') \
    /_repost_close_vworld %{1}%;\
  /endif

