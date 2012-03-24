; cg.tf
;
; Adds a /cg command. '/cg foo' will attempt to switch to the first
; connected world that prefix-matches 'foo', or failing that, the
; first connected world with 'foo' anywhere in the name. If neither
; exists, it prints an error to that effect.


/def -i cg=\
  /let mylist=$(/listsockets -s)%;\
  /if (regmatch(strcat("(?:^| )(\\Q",{1},"\\E)(?:$| )"), mylist)) \
    /fg {1} %;\
  /else \
    /if (regmatch(strcat("(?:^| )(\\Q",{1},"\\E\\S*)(?:$| )"), mylist)) \
      /fg %{P1} %;\
    /else \
      /if (regmatch(strcat("(?:^| )(\\S+\\Q",{1},"\\E\\S*)(?:$| )"), mylist)) \
        /fg %{P1} %;\
      /else \
        /echo -A %% Not connected to any world matching %1 %;\
      /endif %;\
    /endif %;\
  /endif
