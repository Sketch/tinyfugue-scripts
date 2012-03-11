; rwhen.tf
;
; Adds a /rwhen command. '/rwhen *foo*' will display the full time when a
; matching line was seen from the current world in the 'alert' area.
;
; This is useful for quickly finding a timestamp for something without
; having to use /recall -t directly, and without leaving a line you
; probably don't need repeated echo'd to your screen.
;
; By Cheetah@M*U*S*H

/def -i rwhen=\
  /let time=$(/recall -t"\%T \(\%a \%d \%b\)|" /1 %{*})%;\
  /if ({time} =~ "") \
    /echo -A %% Not lately.%;\
  /else \
    /echo -A %% Seen at: $[substr({time},0,strstr({time},"|"))]%;\
  /endif

