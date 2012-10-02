; chatlimits.tf
;
; Author: Greg Millam (Walker@M*U*S*H, captdeaf@gmail.com, github.com/captdeaf)
;
; MUSH-Specific /limit keybindings
;
; This adds three keybindings:
;
; 1) ^xx - /unlimit
; 2) ^xp - Limit to pages (incoming and outgoing) that match PennMUSH's default
;          page syntax.
; 3) ^xc - Channel limits. (Described below)
;
; Channel limits - Limit to only incoming text from a specific channel.
;
; This supports two channel types commonly seen on MUSHes:
;
; > +chan Hello
; <Channel> text
;
; > -chan Hello
; [Channel] Hello
;
; This will remember the last channel you spoke on, and pressing ^x-c
; (Ctrl+x, then c) will /limit to the last channel.
;
; If you have text in your input buffer, e.g: "+chan", then it will
; limit to that channel instead. Useful for seeing backlog of a channel
; before chatting on it.

/loaded chatlimits.tf

; ctrl+x x - /unlimit
/bind ^xx=/unlimit

; Pages(@M*U*S*H?)
; Original _page_re_ by Cheetah@M*U*S*H. Updated _page_re_ by Kevin.
/set _page_re_=([-\w ]{1,24} pages( ([-\w ]{1,24}(, (and )?)?)+)?: .*|You paged ([-\w]{1,24}(, (and )?)?)+ with '.*'(\.)?|Long distance to ([-\w ]{1,24}(, (and )?)?)+:[-\w ]{1,24}.*|From afar( \(to ([\w ]{1,24}(, (and )?)?)+\))?, [-\w ]{1,24}.*|(\(To: ([\w ]{1,24}(, (and )?)?)+\))? [-\w]{1,24} pages: .*|(\(To: ([\w ]{1,24}(, (and )?)?)+\))? From afar, [-\w]{1,24} .*)$

; And use ctrl+x, p to limit to pages.
/bind ^xp=/limit -mregexp %{_page_re_}

; The following code is intended to bind ^xc to cleverly limit
; to the current channel.

; First, the default channel.
/if ({_cur_chan_} =~ "") /set _cur_chan_=<Public%; /endif

; When I send "+foo" - Mark 'foo' as my current channel.
/def -F -h"send ^\\+(\\+?\\w+) .*$" -mregexp chanlimit= \
    /set _cur_chan_=<%{P1}%; \
    /send %P0
   
/def -F -h'send ^\\-(\\S+) .*' -mregexp minuschanlimit= \
    /set _cur_chan_=\\\\[%{P1}%; \
    /send - %P0

; First, test to see if we don't have anything in our input ubffer
; that looks like a channel chat. If we do, use that as our current
; channel.
/bind ^xc=\
    /let _input_=$(/recall -i 1)%; \
    /let _chan_={_cur_chan_}%; \
    /if /test regmatch('^\\\\+(\\\\+*\\\\w+)',"%{_input_}")%; /then \
       /let _chan_=<%P1%; \
     /elseif /test regmatch('^-(\\\\S+)',"%{_input_}")%; /then \
       /let _chan_=\\\\[%P1%; \
     /endif%; \
    /eval /limit %{_chan_}*
