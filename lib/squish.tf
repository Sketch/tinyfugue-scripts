;;  squish(s1)
;;  squish(s1, s2)
;;          (str) Returns <s1> with runs of <s2> (default space) compressed
;;          into one occurrence.
;;
;; By Cheetah@M*U*S*H

/def -i squish=\
  /let squishstring=%{1}%;\
  /let squishchar=$[({#} > 1) ? {2} : " "]%;\
  /while (strstr({squishstring}, strrep({squishchar}, 2)) > -1) \
    /test squishstring := replace(strrep({squishchar}, 2), \
                                  {squishchar}, \
                                  {squishstring}) %;\
  /done%;\
  /return {squishstring}
