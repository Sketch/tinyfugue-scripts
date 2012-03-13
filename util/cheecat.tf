; cheecat.tf
;
; Two quick hacks of tf's /cat command.
; /newcat works like /cat, except instead of evaluating and then sending,
; it grabs the result to the input window for editing at your own leisure.
;
; /rcat works like /newcat, but the result is display-equivalent MUSHcode
; of what was pasted. It is not, however, very efficient so while it's
; suitable for snippets, larger amounts of text will quickly run into
; input buffer limits.
;
; By Cheetah@M*U*S*H

/loaded cheecat.tf

/def -i newcat = /echo -e %% Entering cat mode.  Type "." to end.%; /let _line=%; /let _all=%; /while ((tfread(_line) >= 0) & (_line !~ ".")) /if (_line =/ "/quit") /echo -e %% Type "." to end /cat.%; /endif%; /@test _all := strcat(_all, (({1} =~ "%%" & _all !~ "") ? "%%;" : ""), _line)%; /done%; /grab %_all
/def -i rcat = /echo -e %% Entering cat mode.  Type "." to end.%; /let _line=%; /let _all=%; /while ((tfread(_line) >= 0) & (_line !~ ".")) /if (_line =/ "/quit") /echo -e %% Type "." to end /cat.%; /endif%; /let _line=$[replace("%", "%%", {_line})] %;/@test _all := strcat(_all, (({1} =~ "%%" & _all !~ "") ? "%%;" : ""), {_line}, "%%r")%; /done%; /grab $[replace( "[", "%[", replace( "\\", "\\\\", replace("{", "%{", replace(" ", "%b", {_all}))))]
