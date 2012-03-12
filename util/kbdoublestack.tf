; kbdoublestack.tf
;
; Originally ganked from kbstack.tf
;
; kbstack.tf author: Ken Keyes (I think? It's in main TF.)
; Author: Greg Millam (Walker@M*U*S*H, captdeaf@gmail.com, github.com/captdeaf)
;
; Double Keyboard stack
;
; This is useful when you're in the middle of typing a long line,
; and want to execute another command without losing the current line,
; but then sometimes you want to look back at that line without losing
; your current line, or . . . etc. =)
;
; Press esc-down to push the current text (if any) onto the top stack,
; and pop one off the bottom stack, or an empty text entry if bototm
; stack is empty.
;
; Press esc-up to push current text onto the bottom stack and pop one off the
; top stack, if it has anything in it, or an empty text entry if top stack
; is empty.
;
; You can have any number of these stacks, they honor %{kbnum} -
; That is, <esc><num><esc><up or down>
;

/loaded kbdoublestack.tf

/purge -i key_esc_down
/purge -i key_esc_up
/def -i key_esc_down = /kb_push %; /kbd_pop
/def -i key_esc_up = /kbd_push %; /kb_pop

/def -i kb_push = \
    /let n=$[+kbnum]%; \
    /if (n < 0) \
	/echo -e %% %0: illegal stack number %n.%; \
	/return 0%; \
    /endif%; \
    /let _line=$(/recall -i 1)%;\
    /if ( _line !~ "" ) \
        /eval \
	    /set _kb_stack_%{n}_top=$$[_kb_stack_%{n}_top + 1]%%;\
	    /set _kb_stack_%{n}_%%{_kb_stack_%{n}_top}=%%{_line}%;\
    /endif%;\
    /dokey dline

/def -i kb_pop = \
    /let n=$[+kbnum]%; \
    /if /test %{n} >= 0 & _kb_stack_%{n}_top > 0%; /then \
        /dokey dline%;\
        /eval \
	    /@test input(_kb_stack_%{n}_%%{_kb_stack_%{n}_top})%%;\
	    /unset _kb_stack_%{n}_%%{_kb_stack_%{n}_top}%%;\
	    /set _kb_stack_%{n}_top=$$[_kb_stack_%{n}_top - 1]%;\
    /endif

/def -i kbd_push = \
    /let n=$[+kbnum]%; \
    /if (n < 0) \
	/echo -e %% %0: illegal stack number %n.%; \
	/return 0%; \
    /endif%; \
    /let _line=$(/recall -i 1)%;\
    /if ( _line !~ "" ) \
        /eval \
	    /set _kbd_stack_%{n}_top=$$[_kbd_stack_%{n}_top + 1]%%;\
	    /set _kbd_stack_%{n}_%%{_kbd_stack_%{n}_top}=%%{_line}%;\
    /endif%;\
    /dokey dline

/def -i kbd_pop = \
    /let n=$[+kbnum]%; \
    /if /test %{n} >= 0 & _kbd_stack_%{n}_top > 0%; /then \
        /dokey dline%;\
        /eval \
	    /@test input(_kbd_stack_%{n}_%%{_kbd_stack_%{n}_top})%%;\
	    /unset _kbd_stack_%{n}_%%{_kbd_stack_%{n}_top}%%;\
	    /set _kbd_stack_%{n}_top=$$[_kbd_stack_%{n}_top - 1]%;\
    /endif

