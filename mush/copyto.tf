; copyto.tf
;
; Original author: Walker@M*U*S*H
;
; use /copyto <worldname> <object dbref> to copy objects across worlds.
;
; /copyto myothermush #123
;

/loaded copyto.tf

/def copyto= /set copy_world=%{1}%; /set copy_what=%{2}%; \
	/set copy_from=${world_name}%; \
	/send -w%{copy_from} think TF: Beginning copy: %{copy_what} to %{copy_world} ... %; \
 	/send -w%{copy_from} @decompile/prefix %{copy_what}=TFCopy >\%b %; \
	/send -w%{copy_from} think TFCopy:Decompile Finished %;

/def -p50 -ag -mglob -t"TFCopy:Decompile Finished" = \
	/unset copy_world %;

/def -p100 -ag -mglob -t"TFCopy > *" fuguecopy = \
	/if (copy_world !~ "") /send -w%{copy_world} %-2%; /endif

