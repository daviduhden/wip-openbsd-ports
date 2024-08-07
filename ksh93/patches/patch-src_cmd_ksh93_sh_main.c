Index: src/cmd/ksh93/sh/main.c
--- src/cmd/ksh93/sh/main.c
+++ src/cmd/ksh93/sh/main.c
@@ -209,7 +209,7 @@
 					name = *name ? sh_strdup(name) : NULL;
 #if SHOPT_SYSRC
 				if(!strmatch(name, "?(.)/./*"))
-					sh_source(iop, e_sysrc);
+					sh_source(iop, sh.sysrc);
 #endif
 				if(name)
 				{
