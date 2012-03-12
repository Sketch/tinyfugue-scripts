;;;; Handle 'virtual' worlds.
;;;; This is a light API around connectionless sockets for adding, removing
;;;; and making sure they're connected, and have something to handle
;;;; 'sending' text to the world.
;;;;
;;;; By Cheetah@M*U*S*H

/loaded vworld.tf
/require textutil.tf
/require textencode.tf

;;; /vw_create [-s<send_handler>] [-t<subtype>] <World Name>
; Creates a virtual world and ensures it's connected.
; Automatically defines a SEND hook that will call the given send handler
; when typing text to this world, or default to /vw_default_send_handler
; if not specified. The handler is called with the world name as its first
; argument, and the text typed to the world in the subsequent arguments.
; All virtal worlds have a type virtual.*, use -t to specify a subtype.
; For example -tspawn. will make the complete type virtual.spawn.
/def -i vw_create=\
  /if (!getopts("s:t:", "")) /return 0%; /endif%; \
  /addworld -T'virtual.%{opt_t}' %{*}%;\
  /let vw_mname=_vw_shook_$(/textencode %{*})%;\
  /def -T'virtual.*' -w'%{*}' -h'SEND *' %{vw_mname}=\
    %{opt_s-/vw_default_send_handler} %{*} %%{*}%;\
  /vw_ensure %{*}

;;; /vw_delete <World name>
; Deletes a virtual world, making sure to clean up after itself.
/def -i vw_delete=\
  /if (!vw_exists({1})) \
    /echo -A %% No virtual world named %{1}.%;\
    /return 0%;\
  /endif%;\
  /if ( vw_isconnected({1}) ) \
    /dc %{1}%;\
  /endif%;\
  /if (morepaused({1})) \
    /fg %{1}%;\
    /dokey flush%;\
  /endif%;\
  /if (world_info("name") =~ {1}) \
    /bg%;\
  /endif%;\
  /repeat -0 1 /unworld %{1}%;\
  /let vw_mname=_vw_shook_$(/textencode %{*})%;\
  /undef %{vw_mname}

;;; /vw_write <world>=<text>
; Writes text to a virtual world, making sure it exists and is connected,
; connecting to it if necessary.
/def -i vw_write=\
  /split %{*}%;\
  /let vw_world=%{P1}%;\
  /let vw_text=%{P2}%;\
  /if (!vw_exists({vw_world})) \
    /echo -A %% No virtual world named %{vw_world}.%;\
    /return 0%;\
  /endif%;\
  /vw_ensure %{vw_world}%;\
  /echo -w%{vw_world} %{vw_text}

;;; /vw_redirect [-k] [-m<matching>] <from>=<to>=<pattern>
; Redirects lines from world from matching pattern to virtual world to.
; Returns the number of the macro used to handle those lines.
; With -k it keeps those lines in the original world. Without (the default)
; it will gag them.
/def -i vw_redirect=\
  /if (!getopts("km:", "")) /return 0%; /endif%; \
  /let vw_attrs=%;\
  /if (!{opt_k}) \
    /test vw_attrs := strcat(vw_attrs, "g")%;\
  /endif%;\
  /let vw_matching=%{opt_m-%{matching}}%;\
  /split %{*}%;\
  /let vw_from=%{P1}%;\
  /split %{P2}%;\
  /let vw_to=%{P1}%;\
  /let vw_pattern=%{P2}%;\
  /if (!vw_exists({vw_to})) \
    /echo -A %% No virtual world named %{vw_to}.%;\
    /return 0%;\
  /endif%;\
  /let vw_mname=$[strcat("_vw_", \
                  $(/textencode %{vw_to}), \
                  "_", \
                  $(/textencode %{vw_from}), \
                  "_", \
                  $(/textencode %{vw_pattern}))]%;\
  /def -a%{vw_attrs} -m%{vw_matching} -t'$[escape("'", {vw_pattern})]' -w'%{vw_from}' -q %{vw_mname}=\
    /vw_write %{vw_to}=%%{*}%;\
  /return %?

;;; vw_isconnected(<world>)
; Returns whether or not the virtual world specified is connected.
; Required because is_connected always returns 0 for connectionless worlds.
/def -i vw_isconnected=\
  /if (strlen($(/listsockets -s -Tvirtual.* %{1}))) \
    /let retval=$[substr($(/listsockets -Tvirtual.* %{1} %|\
                           /grep -v *LINES IDLE*),1,1) =~ "O"]%;\
    /return {retval}%;\
  /else \
    /return 0%;\
  /endif

;;; vw_exists(<world>)
; Returns whether world exists as a virtual world.
/def -i vw_exists=\
  /let retval=$(/listworlds -s -Tvirtual.* %{1})%;\
  /return !!strlen({retval})

;;; /vw_ensure <world>
; Ensure world is connected, connecting to it immediately if necessary.
/def -i vw_ensure=\
  /if (!vw_exists({1})) \
    /echo -A %% No virtual world named %{1}.%;\
    /return 0%;\
  /endif%;\
  /if ( !vw_isconnected({1}) ) \
    /connect -b %{1}%;\
  /endif

;;; /vw_default_send_handler <args>
; Called if no specific handler is set for a virtual world.
/def -i vw_default_send_handler=\
  /echo %{*}
