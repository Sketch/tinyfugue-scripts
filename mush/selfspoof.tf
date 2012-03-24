; Name: SelfSpoof
; Lowest tested version: tf 5.0p7
; Source: https://raw.github.com/Sketch/tinyfugue-scripts/HEAD/rp/selfspoof.tf
; Author: Sketch@M*U*S*H
; REQUIRE: https://raw.github.com/Sketch/tinyfugue-scripts/HEAD/lib/squish.tf
;
; Purpose:
;  Displays your own nospoof info to yourself when using backslash-posing,
;  for clarity when roleplaying and reading logs.
;
; Usage:
;  /require selfspoof.tf. Use \ to emit your poses.
;
; Notes:
;  The script attempts to not interfere with nospoof info that OTHER players
;  see, and thusly does not simply replace the \ command with a pair of
;  @oemit and think. Instead, it generates a one-shot trigger every time you
;  type a \ command, using the text you inputted, which modifies the line
;  with that output to appear as though the server sent you back your own
;  nospoof information.
;
;  Todo:
;   Add different server nospoof prefixes.
;    PennMUSH: [NAME:] for emit, [NAME:] for say/pose.
;    Rhost: [NAME(#DBREF)] for emit, [NAME(#DBREF)] for say/pose.
;    TinyMUX: [NAME(#DBREF)] for emit, [NAME(#DBREF),saypose] for say/pose.
;    Hard to do because there's no good way to get the DBRef # of a world.
;   Make the script play nice with ]\, the no-eval variant of \.

/loaded selfspoof.tf
/require squish.tf
/def -h"SEND ^\\\\" -mregexp _self_spoof=\
  /let first_newline=strstr(tolower({PR}),'%')%;\
  /def -i -w'${world_name}' -n1 -mglob -t'$[escape('\'',squish(substr({PR},0,(({first_newline} > -1) ? {first_newline} : 20))))]*' _self_spoof_oneshot=\
    /substitute [$${world_character}:] %%{*} %; /send %{*}

/exit

@@ Tests
\Foo
\Foo bar
\Foo    bar
\Foo \  bar
@@ Test 4 Fails (uncompressed space)
\"Foo" bar
\'Foo' bar
\%rFoo bar
\Foo %r bar
\Foo %b %b bar
\Foo bar 
@@ Test 9 fails (trailing space)
