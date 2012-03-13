; srec.tf
;
; This script will bind ^R to seek backwards through your input history for
; an occurrence of the string typed into the input window when you first
; pressed ^R. Subsequent presses will seek back further.
;
; Note: The heuristic used to indicate a fresh search isn't 100% accurate
; and in some cases may end up resuming a stale search. This may not be
; solvable, but improvements are welcome.
;
; By Cheetah@M*U*S*H

/loaded srec.tf

/def -i kb_all=/return strcat(kbhead(), kbtail())
/def -i str_from=/echo $[substr({-2},strchr({-2},{1},{2})+1)]
/def -i str_upto=/echo $[substr({-2},0,strchr({-2},{1},{2}))]
/def -i str_fromlast=/echo $[substr({-1},strrchr({-1},{1})+1)]
/def -i str_uptolast=/echo $[substr({-1},0,strrchr({-1},{1}))]
/def -i line_total=/return $[$(/str_upto : 0 $(/recall %{1} #1)) + 0]

/def -i -b'^R' srecall=\
  /if ( kb_all() =~ "") \
    /echo -A Can't search an empty string. %;\
    /return %;\
  /endif %;\
  /if ( line_total("-i") != {srecall_seen} | \
   strstr(kb_all(), {srecall_phrase}) == -1 | \
   {srecall_phrase} =~ "") \
    /set srecall_phrase $[kb_all()] %;\
    /set srecall_pos $[line_total("-i") - 1] %;\
  /endif %;\
  /set srecall_seen $[line_total("-i")] %;\
  /let srecall_fetch \
    $(/recall -t$[char(160)] -i #0-%{srecall_pos} *%{srecall_phrase}*) %;\
  /grab $(/str_fromlast $[char(160)] %{srecall_fetch}) %;\
  /set srecall_pos $[$(/str_upto : 0 $(/last $(/str_uptolast $[char(160)] %{srecall_fetch}))) - 1]
