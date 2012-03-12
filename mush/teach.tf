; teach.tf
;
; Author: Greg Millam (Walker@M*U*S*H, captdeaf@gmail.com, github.com/captdeaf)
;
; It's basically a tf version of teach to help teach other folks some fun
; points of tf!

/loaded teach.tf

/def teach= \
        /send -w${world_name} pose types into tf --> [ansi(h,lit(%{*}))]%; \
        /eval -s0 %{*} %;
