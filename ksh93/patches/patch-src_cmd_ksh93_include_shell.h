Index: src/cmd/ksh93/include/shell.h
--- src/cmd/ksh93/include/shell.h
+++ src/cmd/ksh93/include/shell.h
@@ -403,6 +403,9 @@
 #if SHOPT_REGRESS
 	struct Regress_s *regress;
 #endif /* SHOPT_REGRESS */
+#if SHOPT_SYSRC
+	char		*sysrc;		/* path to system-wide kshrc */
+#endif
 };
 
 /* used for builtins */
