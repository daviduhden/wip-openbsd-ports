VeraCrypt 1.26.29: validacion OpenBSD amd64

NOTAS PARA REDACTAR LA PROPUESTA DE ACTUALIZACION DE VERACRYPT
Fecha: 14 de octubre de 2026

OBJETIVO Y ESTADO

Proponer security/veracrypt de 1.25.9p1 (base CVS del arbol local) a 1.26.29,
con soporte de elevacion mediante doas y creacion de FFS en OpenBSD.
La actualizacion esta compilada, empaquetada e instalada en OpenBSD 8.0 amd64.
Los cambios estan sincronizados con /root/wip-openbsd-ports/security/veracrypt.
No se ha hecho commit, enviado correo ni integrado el cambio en CVS oficial.

Hay un solo port existente. No hay ports nuevos que entregar en tar.gz.
Los archivos nuevos de este port se incluyen en el diff como adiciones desde
/dev/null, aunque aun no esten dados de alta en CVS. El diff no contiene
lineas de diagnostico que empiecen por '? '. Los nombres usan un solo guion.

FUENTES Y DEPENDENCIAS

Fuente usada:
https://launchpad.net/veracrypt/trunk/1.26.29/+download/VeraCrypt_1.26.29_Source.tar.bz2

Version concreta propuesta: 1.26.29. No afirmar que sea la ultima version
al enviar el correo sin comprobarlo de nuevo.
Se regeneraron distinfo y PLIST. No se cambio el maintainer del port.

Dependencias instaladas con pkg_add:
- wxWidgets-gtk3 3.2.12 y sus bibliotecas graficas transitivas.
- pcsc-lite 2.5.0.
- yasm 1.3.0p1.
- desktop-file-utils 0.28p0.
- gmake 4.4.1p0 y los prerrequisitos disponibles en el sistema.

Se retiro security/sudo de RUN_DEPENDS: doas forma parte del sistema base.
Se anadio pcsc-lite para las cabeceras y el soporte de tokens de la version
nueva. No se iniciaron servicios de smartcard ni se probaron dispositivos.
Se retiro la dependencia de coreutils. El helper de fecha reproducible se
adapto al awk del sistema base. Se mantiene la compilacion con C++14 y las
bibliotecas wxWidgets/FUSE del sistema.

CAMBIOS DEL PORT

1. Actualizacion general
- Version 1.26.29; desaparece la revision de la version anterior.
- Parches de Makefile actualizados, sin optimizacion -O2 impuesta por upstream;
  se inyectan CFLAGS/CXXFLAGS del framework de ports y se conserva LFLAGS.
- Se corrige TC_STR_RELEASE_DATE a June 9, 2026 para concordar con los campos
  numericos de la fuente. El helper source_date_epoch comprueba esa igualdad.
- Se anaden continuaciones explicitas a la expresion ternaria de mes del
  helper source_date_epoch.sh para que funcione con awk de OpenBSD.
- El lanzador desktop usa TRUEPREFIX/bin/veracrypt.
- El icono instalado pasa de XPM a PNG, correspondiente a la fuente nueva.
- Se anade pkg/README con configuracion de doas y uso de FFS.
- Se retira el parche que eliminaba vnconfig -c: upstream ya lo incorpora.
- Se elimina NO_TEST y se implementa do-test mediante veracrypt --text --test.
- Ningun parche incluye SPDX-License-Identifier.

2. Elevacion mediante doas
- En OpenBSD el servicio usa doas en lugar de sudo.
- Se elimina para OpenBSD el preflight heredado 'sudo/doas -n true'. Una regla
  restringida a veracrypt --core-service no tiene por que permitir true.
- Primero se intenta elevar el servicio real con doas -n. Si hace falta
  contrasena, la interfaz solicita la de la cuenta que ejecuta VeraCrypt.
- Para autenticar se crea una pseudoterminal privada y se establece como
  terminal de control. Los canales stdin/stdout del protocolo se conservan.
- El slave se mantiene en stderr durante doas: doas hace closefrom(3) antes
  de autenticar, y cerrar el ultimo descriptor del slave hacia perder /dev/tty.
- Se desactiva el eco y se espera al prompt de readpassphrase antes de enviar
  una unica respuesta. No se usa un retardo fijo como sincronizacion.
- Se distinguen los mensajes de la terminal y las excepciones serializadas
  del servicio. La contrasena no pasa por argv ni por el entorno y se borra
  de los buffers temporales.
- Tras autenticarse, el worker elevado se separa de la sesion de la terminal
  antes de liberar stderr; evita que la liberacion de la terminal lo termine.
- El fallo de autenticacion devuelve el control al frontend para reintentar,
  sin dejar a doas esperando otra respuesta en una terminal privada.
- Los errores de elevacion de OpenBSD hacen referencia a doas y doas.conf.

Regla recomendada en el README (ejecucion normal como usuario):
    permit :wheel cmd /usr/local/bin/veracrypt args --core-service

La regla autoriza el servicio privilegiado de VeraCrypt. No hace falta permitir
true ni elevar la invocacion normal de la CLI. La variante nopass se probo
solo como regla temporal del banco de pruebas; no se deja instalada.

3. FFS
- Se anade FFS al enum de filesystems, como tipo nativo en OpenBSD, al parser
  de --filesystem y a los selectores de CLI/GUI.
- La creacion no interactiva sigue eligiendo FAT por defecto. FFS se solicita
  expresamente con --filesystem=FFS.
- Se anade una peticion serializada especifica al servicio privilegiado para
  ejecutar /sbin/newfs sobre el dispositivo raw correspondiente al volumen.
- El servicio valida /dev/vnd[0-3]c y que corresponda a un volumen VeraCrypt
  sin filesystem montado antes de convertirlo a /dev/rvndNc. No se anade una
  interfaz generica para ejecutar comandos ni se aceptan discos arbitrarios.
- CLI y GUI usan la misma peticion de formateo. No se cede temporalmente la
  propiedad del dispositivo al usuario: eso no basta para los ioctls de newfs.

FALLOS DETECTADOS Y CORREGIDOS DURANTE LA VALIDACION

El WIP inicial compilaba, pero la comprobacion doas true impedia usar una
regla limitada al servicio. La primera prueba FFS con usuario normal fallo
con 'newfs: ioctl (GDINFO): Operation not permitted': habia que formatear en
el servicio elevado, no solo cambiar el propietario del dispositivo raw.
La primera prueba con contrasena fallo con 'doas: a tty is required': habia
que mantener el slave en un descriptor que sobreviviera al closefrom de doas.
Estos casos se corrigieron y se repitieron con exito en el binario final.

VALIDACION QUE PUEDE CITAR EL CORREO

- Compilacion, checksum y comprobacion de bibliotecas compartidas: correctos.
- Autotests de todos los algoritmos: correctos, tambien como usuario normal.
- doas denegado, nopass restringido, autenticacion con contrasena y reintento
  tras contrasena incorrecta: comportamiento esperado.
- FFS: crear, montar, escribir/leer como usuario, desmontar y remontar con
  SHA256 identico. fsck_ffs -fn sin errores.
- FAT batch sigue funcionando sin elevacion para crear y se monta como msdos.
- Cuenta temporal eliminada, doas.conf restaurado y todos los vnd libres.

No convertir esto en una afirmacion de soporte probado en todas las
arquitecturas o de la GUI. No se probaron discos fisicos, volumenes ocultos
ni smartcards. No hay recuento numerico de tests criptograficos: upstream
informa 'Self-tests of all algorithms passed'. Hay avisos de compilacion
y el aviso esperado de --quick, que se uso solo en imagenes de prueba.

ENTREGA Y EVIDENCIA

/root/veracrypt-results/por-port/diffs/security-veracrypt.diff
/root/veracrypt-results/por-port/RESULTADOS-PRUEBAS.txt
/root/veracrypt-results/por-port/CAMBIOS-PARA-PROPUESTA.txt
/root/veracrypt-results/por-port/SHA256

Paquete listo para instalar/probar:
/usr/packages/amd64/all/veracrypt-1.26.29.tgz
Su tamano y SHA256 constan en /root/veracrypt-results/package.json.

Logs y evidencia JSON en /root/veracrypt-results:
- logs/build-doas-tty-final.log, package-tty-final.log, install-tty-final.log.
- logs/crypto-selftest-final.log y crypto-selftest-unprivileged.log.
- logs/ffs-*.log, ffs-payload.sha256 y fat-*.log.
- logs/doas-password-auth.log y doas-password-retry-auth.log.
- logs/doas-evidence.log, checks-final.log y patch-clean.log.
- cli-results.json, doas-password-result.json,
  doas-password-retry-result.json, extra-cli-results.json.
- test-account-cleanup.json y logs/vnd-final.log.

El diff se ha comprobado con git apply --numstat y los parches se aplicaron
sobre una extraccion limpia. No confundirlo con un commit o con una prueba
de aplicacion sobre un checkout CVS independiente.

ORIENTACION PARA REDACTAR

Presentar una propuesta de actualizacion a 1.26.29 que anade la integracion
doas/FFS descrita, con validacion CLI en OpenBSD 8.0 amd64. Destacar que las
pruebas con usuario normal descubrieron fallos que no aparecian como root.
Pedir revision de los cambios de elevacion y pruebas en otras arquitecturas.
No inventar destinatario, firma, URL publica de adjuntos, resultados de GUI
o aceptacion del cambio. No enviar el correo sin una instruccion expresa.

RESULTADOS DE VALIDACION DE VERACRYPT
OpenBSD 8.0 amd64, 14 de octubre de 2026
Version instalada: VeraCrypt 1.26.29

COMPILACION Y PAQUETE
- Compilacion del port con clang/C++14 y wxWidgets: correcta.
- distinfo y PLIST generados a partir de las fuentes y del fake real.
- make checksum y make port-lib-depends-check: correctos.
- Paquete veracrypt-1.26.29.tgz generado e instalado.
- Todos los parches se aplican sobre una extraccion limpia. Las fuentes
  parcheadas coinciden con las usadas para construir el binario (salvo la
  sustitucion posterior de TRUEPREFIX en el lanzador desktop).

PRUEBAS CRIPTOGRAFICAS
- Target do-test del port: Self-tests of all algorithms passed.
- Binario instalado ejecutado como usuario temporal sin privilegios:
  Self-tests of all algorithms passed.
- veracrypt --text --version: VeraCrypt 1.26.29.

DOAS
- Cuenta temporal vctest, uid 1001, sin pertenencia a wheel.
- Regla de denegacion: la operacion privilegiada falla con exit 1, como se
  esperaba; no se configura ningun vnd ni queda un montaje.
- Regla nopass limitada a /usr/local/bin/veracrypt args --core-service:
  creacion FFS, montaje, listado y desmontaje sin terminal interactiva: OK.
- La misma regla sin nopass: montaje FFS desde la CLI con una sola peticion
  de la contrasena de la cuenta: OK.
- Contrasena incorrecta seguida de la correcta: dos peticiones, error de
  autenticacion esperado y recuperacion sin bloqueo; montaje final: OK.
- El registro de doas confirma que vctest ejecuto --core-service como root.
- La contrasena de administracion se transmite por una terminal privada;
  no se pasa como argumento del programa ni como variable de entorno.

FFS
- Contenedor normal de archivo, 64 MiB, AES, SHA-512 y PIM 0.
- Creacion con --filesystem=FFS como usuario sin privilegios: OK.
- newfs ejecutado como root sobre /dev/rvndNc mediante el servicio elevado.
- Montaje explicito con --filesystem=ffs: tipo ffs confirmado por mount.
- Escritura y lectura de un payload de 1.048.621 bytes como usuario normal.
- Desmontaje y remontaje automatico sin especificar el tipo: OK.
- Hash SHA256 del payload identico tras remontar.
- Montaje posterior con autenticacion doas y punto personalizado: datos intactos.
- Apertura sin montar filesystem y fsck_ffs -fn: exit 0; filesystem limpio,
  fases 1 a 5 completadas sin reparaciones.

REGRESION FAT
- Creacion no interactiva sin --filesystem, con doas denegado: OK.
- Montaje automatico posterior: tipo msdos confirmado.
- Desmontaje: OK. Se conserva FAT como valor por defecto de la creacion batch.

LIMPIEZA
- Todos los volumenes de prueba desmontados; vnd0, vnd1, vnd2 y vnd3 libres.
- Cuenta temporal y su directorio con las imagenes eliminados.
- /etc/doas.conf restaurado exactamente a sus bytes originales.
- Sin credenciales temporales persistentes en los archivos de entrega.

ALCANCE
Se probaron contenedores normales de archivo y la CLI en amd64. La GUI
compila y comparte el camino de formateo, pero no se probaron sus dialogos.
No se probaron otras arquitecturas, dispositivos fisicos, volumenes ocultos,
smartcards, autenticacion doas distinta de contrasena ni compatibilidad FFS
con otros sistemas operativos. Las pruebas no equivalen a una auditoria
completa del protocolo privilegiado o de criptografia.

Hay avisos de compilacion de upstream y el aviso esperado de --quick en
los contenedores desechables. La prueba de denegacion y la primera contrasena
incorrecta son casos negativos intencionales, no fallos pendientes.
Los logs historicos de los fallos corregidos se conservan para diagnostico;
los resultados anteriores corresponden al binario final.
