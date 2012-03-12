;;;; Association of key/value pairs.
;;;; Keys can contain any character. For the effect of several separate
;;;; hashes/dictionaries/whatever, it's best to use a prefix.
;;;; IE: /assoc users Cheetah=27  /assoc users Walker=5
;;;;
;;;; By Cheetah@M*U*S*H

/loaded assoc.tf

/require textencode.tf
/require lisp.tf

;;; Mostly for maintainability. Change outside this script not recommended.
/set __assoc_prefix=assoc_

;;; /assoc <key>=<value>
; Assign value to key.
/def -i assoc=\
  /split %{*}%;\
  /if (!strlen({P2})) \
    /_unassoc $(/textencode %{P1})%;\
  /else \
    /let rest=%{P2}%;\
    /_assoc $(/textencode %{P1}) %{rest} %;\
  /endif

;;; /rassoc <key>
; Echoes back value associated with key.
/def -i rassoc=\
  /let varname=$(/textencode %{*})%;\
  /eval /echo %%{%{__assoc_prefix}%{varname}}

;;; /lassoc [<prefix>]
; Lists keys starting with prefix. More or less informational only.
/def -i lassoc=\
  /let lassoc_pattern=%{__assoc_prefix}$(/textencode %{*})* %;\
  /let lassoc_list=$(/listvar -s %{lassoc_pattern}) %;\
  /echo $(/mapcar /_lassoc_decode %{lassoc_list})

;;; /mapassoc <prefix>=<cmd>
; Execute "<cmd> <key>=<value>" for each key=value pair matching <prefix>.
/def -i mapassoc=\
  /split %{*}%;\
  /let mapassoc_cmd=%{P2}%;\
  /let mapassoc_pattern=%{__assoc_prefix}$(/textencode %{P1})* %;\
  /let mapassoc_list=$(/listvar -s %{mapassoc_pattern}) %;\
  /mapcar /_mapassoc %{mapassoc_list}

;;; /llassoc [<prefix>]
; Lists key => value pairs starting with prefix. For informational use.
/def -i llassoc=\
  /mapassoc %{*}=/_llassoc
/def -i _llassoc=\
  /split %{*}%;\
  /echo %{P1}=>%{P2}

/def -i _mapassoc=\
  /let mapassoc_key=$(/_lassoc_decode %{1})%;\
  /let mapassoc_value=$(/rassoc %{mapassoc_key})%;\
  /let mapassoc_args=%{mapassoc_key}=%{mapassoc_value}%;\
  /eval %{mapassoc_cmd} %%{mapassoc_args}

/def -i _lassoc_decode=\
  /echo $(/textdecode $[substr({*},strlen({__assoc_prefix}))])

/def -i _unassoc=/unset %{__assoc_prefix}%{1}

/def -i _assoc=\
  /let varname=%{1}%;\
  /shift%;\
  /set %{__assoc_prefix}%{varname}=%{*}
