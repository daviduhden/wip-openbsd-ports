Index: src/cmd/ksh93/sh/init.c
--- src/cmd/ksh93/sh/init.c
+++ src/cmd/ksh93/sh/init.c
@@ -1258,7 +1258,10 @@
 		s++;
 		t |= SH_TYPE_SH;
 		if ((t & SH_TYPE_KSH) && *s == '9' && *(s+1) == '3')
+		{
 			s += 2;
+			t |= SH_TYPE_KSH93;
+		}
 #if _WINIX
 		if (*s == '.' && *(s+1) == 'e' && *(s+2) == 'x' && *(s+3) == 'e')
 			s += 4;
@@ -1375,9 +1378,12 @@
 	}
 	/* read the environment */
 	env_init();
+#if SHOPT_SYSRC
+	sh.sysrc = type & SH_TYPE_KSH93 ? e_sysrc93 : e_sysrc;
+#endif
 	if(!ENVNOD->nvalue.cp)
 	{
-		sfprintf(sh.strbuf,"%s/.kshrc",nv_getval(HOME));
+		sfprintf(sh.strbuf, type & SH_TYPE_KSH93 ? "%s/.ksh93rc" : "%s/.kshrc", nv_getval(HOME));
 		nv_putval(ENVNOD,sfstruse(sh.strbuf),NV_RDONLY);
 	}
 	/* increase SHLVL */
