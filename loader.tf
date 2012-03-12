; loader.tf
;
; Sets up TFPATH to use the directory structure used by these scripts.
; Only useful if you plan to pull in the repository as a whole. If you
; are only interested in a few scripts you can grab those individually.
;
; Usage: /require loader.tf (or supply a full path)
;        /loader_setup <directory loader.tf is in>
;
; By Cheetah@M*U*S*H

;;; This should be modified to add new directories.
/def -i loader_setup=\
  /set _loader_dir=%{1}%;\
  /_loader_add lib%;\
  /_loader_add util%;\
  /_loader_add mush%;\
  /_loader_add rp%;\
  /echo %% loader.tf setup done.

/def _loader_add=\
  /let _loader_new=%{_loader_dir}/%{1}%;\
  /if ({_loader_list} !~ "") \
    /if (strstr({_loader_list}, {1}) != "-1") \
      /echo -A %% Already added to loader: %{1}%;\
      /return%;\
    /endif%;\
    /set _loader_list=%{_loader_list} %{1}%;\
    /set TFPATH=%{TFPATH} %{_loader_new}%;\
  /else \
    /if ({TFPATH} !~ "") \
      /set TFPATH=%{TFPATH} %{_loader_new}%;\
    /else \
      /set TFPATH=%{TFLIBDIR} %{_loader_new}%;\
    /endif %;\
    /set _loader_list=%{1}%;\
  /endif
