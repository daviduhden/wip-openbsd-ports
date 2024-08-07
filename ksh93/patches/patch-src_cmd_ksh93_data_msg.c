Index: src/cmd/ksh93/data/msg.c
--- src/cmd/ksh93/data/msg.c
+++ src/cmd/ksh93/data/msg.c
@@ -181,6 +181,7 @@
 #endif
 #if SHOPT_SYSRC
 const char e_sysrc[]		= "/etc/ksh.kshrc";
+const char e_sysrc93[]		= "/etc/ksh93.kshrc";
 #endif
 #if !SHOPT_SCRIPTONLY
 const char hist_fname[]		= "/.sh_history";
