; cg.tf
;
; Adds a /cg command. '/cg foo' will attempt to switch to the first
; connected world that prefix-matches 'foo', or failing that, the
; first connected world with 'foo' anywhere in the name. If neither
; exists, it prints an error to that effect.
;
; By Cheetah@M*U*S*H

/def -i cg=\
  /let mylist=$(/listsockets -s)%;\
  /if (regmatch(strcat("\\b(\\Q",{1},"\\E\\S*)\\b"), mylist)) \
    /fg %{P1} %;\
  /else \
    /if (regmatch(strcat("\\b(\\S+\\Q",{1},"\\E\\S*)\\b"), mylist)) \
      /fg %{P1} %;\
    /else \
      /echo -A %% Not connected to any world matching %1 %;\
    /endif %;\
  /endif
