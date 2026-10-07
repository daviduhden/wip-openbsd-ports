# Daemon de Codex suministrado por el paquete de OpenBSD

**ENABLED_WITH_SMALL_UPSTREAM_PATCH** — diseño implementado para Codex
0.160.1. La validación de esta tarea es exclusivamente estática: no acredita
una compilación ni una sesión real en OpenBSD.

## Alcance y situación encontrada

Fuente: tag `rust-v0.160.1`, commit
`d27764b82f7118f674371e6d6e76271d9d606edb` de openai/codex.
Se analizó una copia temporal, eliminada al finalizar.

El port encontrado **ya habilitaba el daemon** mediante cuatro parches de
`app-server-daemon` y `CODEX_SYSTEM_DAEMON_PATH=${LOCALBASE}/bin/codex`.
No había un parche que pusiera `daemon_auto_start=false` o excluyera OpenBSD.
La desactivación encontrada afectaba al **actualizador de ejecutables**, no al
proceso app-server. Esta tarea completa y refuerza esa integración: instala
metadatos, conserva un layout reconocido por upstream, valida versiones y
corrige las acciones ofrecidas por el menú de mantenimiento.

La modificación previa de `MAKE_JOBS` en el Makefile se conserva sin cambios.
`distinfo` y `crates.inc` tampoco se regeneran. El `distinfo` existente sigue
nombrando el tarball de 0.160.0: debe actualizarse antes de reconstruir 0.160.1
(véanse los comandos finales).

## Arquitectura upstream y flujo completo

Los enlaces siguientes fijan la versión analizada; los nombres de archivos
sin enlace son relativos al repositorio upstream.

1. **Ejecutable y despacho.** `codex-rs/cli/Cargo.toml` define el binario
   `codex` del package `codex-cli`; depende de `codex-app-server` y
   `codex-app-server-daemon`. `cli/src/main.rs::main` utiliza
   `codex_arg0::arg0_dispatch_or_else`, luego `cli_main`. El despacho por
   argumentos distingue la sesión TUI, `app-server` y `app-server daemon`.
   `AppServerDaemonSubcommand`, `LifecycleCommand`, `LifecycleOutput` y
   `BootstrapOutput` representan el mantenimiento del proceso.
2. **Habilitación.** `features/src/lib.rs` define
   `Feature::DaemonAutoStart`, key `daemon_auto_start`, `Stage::Stable`,
   `default_enabled: true`. La función `run_main` de `codex-tui` llega a la
   orquestación en `tui/src/startup_orchestration.rs`.
   `daemon_startup::exclusion` y `config_exclusion` conservan las restricciones
   upstream: por ejemplo `--no-daemon`, `--oss`, selección de executor,
   workload identity y overrides CLI no reproducibles. No se añade una
   exclusión por OpenBSD.
3. **Arranque interactivo.** El bloque `auto_start_daemon` llama a
   `codex_app_server_daemon::start_with_features`. En
   `app-server-daemon/src/launch.rs`, esta función toma el lock de operación,
   conserva overrides y llama a `Daemon::start`.
4. **Resolución central.** `Daemon::from_environment`,
   `current_installation` y `current_managed_codex_bin` utilizan
   `managed_install::managed_codex_bin`. Upstream selecciona
   `packages/app-server-daemon/current/bin/codex`; `package_root` conserva
   `packages/standalone/current` si identifica un daemon antiguo mediante
   PID/logs. `managed_codex_file_name` selecciona `codex` o `codex.exe`.
5. **Preparación inicial.** `prepare_install::prepare` usa
   `InstallContext::current().package_layout` y `prepare_from_package`.
   No descarga necesariamente en el primer arranque: normalmente **copia el
   paquete completo de la CLI** al home. `validate_package` exige manifest,
   ejecutable, code-mode host y ripgrep; Linux añade bwrap y Windows sus
   auxiliares. `package_tree` copia y calcula un digest BLAKE3 del árbol.
   Se usa un staging bajo `releases/`, locks y selección atómica de `current`.
   `update_from_cli` permite reemplazarlo explícitamente con `--from-cli`.
6. **Versión y plataforma.** `CodexPackageManifest.version` es
   `semver::Version`; `stable_version` filtra versiones estables.
   `prepare_install::platform_target` enumera Darwin, Linux GNU/musl y
   Windows MSVC; compara `target` y `entrypoint` del JSON. La identidad del
   ejecutable se calcula con `managed_install::executable_identity`.
   `managed_codex_version` ejecuta el seleccionado con `--version` y
   `parse_codex_version` extrae el segundo término.
7. **Proceso.** `Daemon::start_managed_backend` construye `BackendPaths` y
   llama a `backend::pid_backend`, `PidBackend::start`, `start_inner` en
   `backend/pid_start.rs`. Canonicaliza el ejecutable, reserva un PID file,
   abre el log y construye `tokio::process::Command`.
   `PidBackend::command_args` produce:

   ```text
   codex app-server [--remote-control] --listen unix:// [-c features.X=Y]
   ```

   Se añade `--managed-daemon` cuando la CLI lo admite. El child recibe stdin
   y stdout nulos, stderr al log; en Unix ejecuta `setsid()` en `pre_exec`
   y después `Command::spawn()`, que termina ejecutando el binario nativo.
   El `codex` hijo vuelve a `cli_main`, rama `Subcommand::AppServer`, y llama
   a `codex_app_server::run_main_with_transport_options`.
8. **Publicación y disponibilidad.** `PidRecord` guarda PID, hora de inicio,
   identidad opcional de proceso y digest del ejecutable.
   `read_process_details` obtiene `stat` y `lstart` mediante `ps` en el
   fallback Unix. `wait_until_ready` usa `client::probe`, con polling y
   timeout de arranque de diez segundos.
9. **IPC.** `codex-app-server-transport`, `codex-uds`,
   `AppServerTransport::from_listen_url`, `start_control_socket_acceptor` y
   `codex-app-server-client::RemoteAppServerClient` implementan WebSocket
   sobre socket Unix y JSON-RPC. `initialize` / `initialized` intercambian
   `InitializeParams`, capabilities y `InitializeResponse.user_agent`.
   `client::parse_version_from_user_agent` lee la versión del servidor.
   La TUI selecciona `AppServerTarget::LocalDaemon`, y
   `daemon_startup::compatibility_warning` comprueba también features del
   servidor mediante RPC. No se encontró una negociación separada de
   versión de protocolo ni un build ID obligatorio para este lifecycle.
10. **Parada y reinicio.** `Daemon::stop` y `restart_with_settings` mantienen
    ownership mediante PID records y locks. `PidBackend::stop_with_grace`
    comprueba identidad, envía SIGTERM y finalmente SIGKILL si hace falta;
    upstream drena trabajo y conserva recovery con `--managed-daemon`.
    La CLI saliente no termina necesariamente el daemon: es un proceso
    por usuario desacoplado, compartido por clientes posteriores.
11. **Actualizaciones upstream.** `ensure_managed_updater` comprueba
    settings, `is_stable_standalone_release`, `auto-update-version` y
    `supports_daemon_update_loop`. El proceso `pid-update-loop` entra en
    `update_loop::run`, `run_with_http`; espera inicialmente cinco minutos,
    luego usa el intervalo configurado (sesenta minutos por defecto).
    `update`, `request_manual_update`, `manual_update::request/run` y
    `migration::run` cubren actualizaciones explícitas, incluyendo paquetes
    locales fijados y migraciones legacy.
12. **Descarga e instalación upstream.** `fetch_installer_script` obtiene
    `https://chatgpt.com/codex/install.sh` (PowerShell en Windows);
    `run_installer_script` lo ejecuta con flags `CODEX_INSTALL_DAEMON_ONLY`
    y guardas de selección. `scripts/install/install.sh` resuelve release
    metadata en releases.openai.com/GitHub, el asset
    `codex-package-<target>.tar.gz` y checksums; `download_file_with_fallback`
    y `install_package_release` descargan/descomprimen con `tar`, instalan
    un release y retargetean `current`. Hay fallback a un tarball npm de
    plataforma mediante `install_legacy_platform_npm_release`, no una
    dependencia necesaria de npm para un daemon Rust. Estos caminos quedan
    inaccesibles desde el modo suministrado por el sistema.

Fuentes principales:
[orquestación TUI](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-rs/tui/src/startup_orchestration.rs),
[resolver](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-rs/app-server-daemon/src/managed_install.rs),
[preparación](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-rs/app-server-daemon/src/prepare_install.rs),
[lanzamiento PID](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-rs/app-server-daemon/src/backend/pid_start.rs),
[actualizador](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-rs/app-server-daemon/src/update_loop.rs).

## El error `can't start`: hechos y límites

Una búsqueda del literal `can't start`, su variante tipográfica y
`couldn't start` en todo el árbol 0.160.1 no encuentra un emisor de
`can't start` relacionado con el daemon. Los mensajes `couldn't start`
que sí existen pertenecen a `cli/src/state_db_recovery.rs`, recuperación
de bases de datos; no permiten atribuir el mensaje facilitado a esa ruta.
Sin el comando, la versión y el error completo no puede determinarse su
emisor ni el errno original. No se inventa una causa raíz de ese caso.

Sí puede reconstruirse el fallo de una **instalación upstream desnuda**:

- `managed_codex_bin` devuelve normalmente
  `~/.codex/packages/app-server-daemon/current/bin/codex`, aún inexistente.
- `prepare_from_package` encuentra `InstallContext.package_layout == None`
  si sólo se instaló `/usr/local/bin/codex` sin layout ni manifest, y falla
  con `this CLI has no complete local package; install a packaged Codex CLI
  or use the standalone installer`. No llega al spawn.
- Si se aporta un bundle upstream, `platform_target()` falla con
  `unsupported packaged daemon platform openbsd/x86_64` o
  `openbsd/aarch64`, antes de validar/copiar el paquete. El installer shell
  tampoco ofrece un artefacto OpenBSD. Añadir sólo el JSON no resuelve esto.
- Estos son bloqueos de **provisión de paquetes**, no ausencia del código
  del app-server: `ensure_supported_platform()` acepta `cfg(unix)`.

Con los parches previos, las dos primeras rutas se evitaban; por ello no
pueden presentarse como causa probada de un fallo del port ya parcheado.
Un fallo restante puede estar en ejecutabilidad, bibliotecas, limits,
identificación PID, estado previo o socket. Upstream ya informa:

- `failed to spawn detached app-server process using <ruta>`, desde
  `PidBackend::start_inner`, conservando el error de `spawn`/`setsid`;
- `failed to record pid-managed app-server process <pid> startup`, más
  tail del stderr cuando falla la identificación;
- `app server did not become ready on <socket>`, desde
  `wait_until_ready`/`app_server_not_ready_context`, con path, versión y
  tail de hasta 4096 bytes del log;
- la orquestación TUI formatea la cadena `anyhow` con `{err:#}`.

La implementación añade diagnósticos de paquete ausente, manifest inválido,
versiones incompatibles y timeout de consulta de versión, dirigidos a
`pkg_add`, sin proponer una descarga como reparación.

## Cómo se construye el daemon

El package `codex-app-server-daemon` es una **biblioteca de lifecycle**;
no define otro ejecutable de daemon. El servidor real es `codex-app-server`,
que publica tanto una biblioteca como el target independiente
`codex-app-server`. La CLI `codex` ya enlaza esa biblioteca y ofrece el
subcomando `app-server`.

Por eso el port construye el daemon al construir `codex-cli --bin codex`.
No es necesario compilar otra copia ni conseguir fuentes de otro
repositorio. Un `codex-app-server` aislado no sustituye directamente a
`codex` en `PidBackend`: el backend también espera `--version`,
`app-server ...` y comandos `app-server daemon ...` de la CLI multitool.
Se mantiene ese contrato reutilizando el ejecutable CLI.

## Manifest y Node/npm

El nombre real es **`codex-package.json`**, constante
`PACKAGE_METADATA_FILENAME` en `codex-install-context`.
`scripts/codex_package/layout.py::build_package_dir` lo genera con:

| Campo upstream | Significado |
| --- | --- |
| `layoutVersion` | Versión del layout, actualmente 1 |
| `version` | Semver del paquete; por defecto workspace.package.version |
| `target` | Triple nativo de la distribución |
| `variant` | `codex` o `codex-app-server` |
| `entrypoint` | Ruta relativa, por ejemplo `bin/codex` |
| `resourcesDir` | Directorio `codex-resources` del bundle completo |
| `pathDir` | Directorio `codex-path` del bundle completo |

`CodexPackageLayout::from_exe` canonicaliza el ejecutable;
`from_package_bin_dir` reconoce `bin/` cuyo padre contiene el JSON.
`InstallContext::package_manifest` deserializa sólo `version` como semver.
`prepare_from_package` lee además `target` y `entrypoint` para la copia
upstream. La detección de layout no depende de npm ni de un árbol en el home.

El port instala los primeros cinco campos. No declara directories de
recursos o PATH que no instala. La implementación Rust ya trata esos
**directorios como opcionales**: `code_mode_host_program` busca el host
junto al binario y `rg_command` usa el ripgrep de RUN_DEPENDS.
No se presenta esta instalación como un bundle autocopiable completo:
el modo sistema evita `validate_package`/`package_tree` y toda copia.

`scripts/codex_package/targets.py` y `cargo.py` construyen los binarios del
bundle desde fuentes. `codex-cli/scripts/build_npm_package.py` monta el
metapaquete `@openai/codex` y variantes nativas con un vendor tree.
`codex-cli/bin/codex.js::findCodexExecutable` selecciona el triple según
`process.platform`/`process.arch`, busca la dependencia de plataforma vía
`require.resolve(<package>/package.json)` y arranca su binario Rust.
Su selector no incluye OpenBSD. El shim exporta
`CODEX_MANAGED_BY_NPM`/BUN/PNPM/VITE_PLUS y `CODEX_MANAGED_PACKAGE_ROOT` para
clasificación y diagnóstico. **`package.json` de npm no es
`codex-package.json` del runtime**. El fallback standalone a tarballs npm
extrae su vendor tree con tar; tampoco exige ejecutar Node.

El port invoca directamente el binario Rust. No instala el shim JS,
no añade Node/npm y no adapta su selector a un artefacto Linux.

Fuentes:
[contexto de instalación](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-rs/install-context/src/lib.rs),
[generador del manifest](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/scripts/codex_package/layout.py),
[shim npm](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-cli/bin/codex.js).

## Alternativas investigadas

| Alternativa | Resultado |
| --- | --- |
| 1. Path del daemon configurable | No hay override upstream para la provisión externa en el resolver; se conserva el parche previo central |
| 2. Variable de entorno | El port ya añadió `CODEX_SYSTEM_DAEMON_PATH`; es una variable **de compilación**, consumida con `option_env!`, no un override del usuario en runtime |
| 3. Constante en build | La variable anterior queda incrustada en los crates; ownership no puede alterarse por el entorno de la sesión |
| 4. Manifest generado por el port | Implementado con SUBST_CMD, versión `${V}` y target OpenBSD nativo |
| 5. Instalación bajo PREFIX | Implementada en libexec/codex con layout upstream bin/ y links públicos |
| 6. Bypass exclusivo download/update | Guardas de prepare, update_from_cli, update, pid-update-loop y ensure_managed_updater; no guardas que deshabiliten start/stop |
| 7. Reutilizar start/stop/IPC | Backend PID, setsid, señales, sockets, locks, probes y recovery existentes |
| 8. Modo system-provided pequeño | Resolver central, validación de versión y API pública system_daemon_path para el menú |
| 9. Resolver central de paquetes | managed_install::managed_codex_bin devuelve el path compilado antes de inspeccionar paquetes del usuario |
| 10. Mismo source tree/build | CLI y daemon son el mismo ELF; code-mode host se construye en el mismo workspace/version |

La ruta externa no se infiere de un archivo `current` en el home y nunca
vuelve a download como fallback si falta el ejecutable del paquete.

## Layout, proceso y plataforma

```text
${PREFIX}/bin/codex -> ../libexec/codex/bin/codex
${PREFIX}/bin/codex-code-mode-host -> ../libexec/codex/bin/codex-code-mode-host
${PREFIX}/bin/codex-logs-client
${PREFIX}/libexec/codex/
    codex-package.json
    bin/
        codex                 # CLI y app-server, un único ejecutable
        codex-code-mode-host
${PREFIX}/share/doc/codex/     # documentación existente
```

`libexec/codex/bin` conserva la convención `bin/` que upstream reconoce:
no hace falta modificar `codex-install-context` ni instalar un manifest
global en `${PREFIX}/codex-package.json`. El enlace público `bin/codex`
es necesario para la CLI de usuario. El link del host conserva su ruta
preexistente, mientras el lookup interno usa la copia junto al ejecutable.
PLIST registra los ELF reales con `@bin`; los enlaces se registran como tales.

Los targets son `x86_64-unknown-openbsd` y `aarch64-unknown-openbsd`.
No se añade OpenBSD a listas de descargas sin artefactos, ni se hace alias
Linux. El lifecycle y transporte ya seleccionan `cfg(unix)` para OpenBSD:
setsid, flock/locks, SIGTERM/SIGKILL, sockets Unix, modos privados 0700 y
permisos de socket. Se conserva el parche de ps con `LC_ALL=C`, `TZ=UTC`
para la identidad basada en `lstart` entre diferentes terminales.
El socket real se publica bajo `/tmp/codex-daemon-<uid>/<hash>`; la ruta
anunciada de CODEX_HOME es un enlace, con locks y ownership upstream.

No hay rc.d, usuario de servicio, arranque de sistema ni updater periódico
del paquete. El daemon permanece disponible tras salir de una TUI y se
reinicia bajo demanda tras un reboot o una parada explícita.

## Inventario de ~/.codex/packages

En el flujo Rust investigado, las raíces reales son `standalone` y
`app-server-daemon`; no se encontró otro proveedor del daemon bajo esa raíz.

| Uso | Tratamiento |
| --- | --- |
| `standalone/releases`, `app-server-daemon/releases` | Paquetes con ejecutables CLI/daemon, code-mode host, rg y recursos de plataforma; el modo sistema no crea ni selecciona estos releases |
| `current`, `auto-update-version`, install locks/staging | Metadatos de selección y preparación de esos paquetes upstream; no se necesitan para el modo sistema |
| `~/.codex/app-server-daemon` | Estado: PID, settings, locks, stderr logs, loaded-threads.json; se conserva |
| `~/.codex/app-server-control` | Rendezvous/lock de IPC; se conserva, con socket real temporal protegido |
| Otras caches, historial, auth, plugins y metadatos de usuario | No son una instalación del daemon; no se eliminan ni se trasladan |
| Componentes opcionales | Recursos bundled de Linux/Windows no se requieren en OpenBSD; rg es RUN_DEPENDS y el host se instala desde el build. Plugins/MCP/otras descargas opcionales conservan sus políticas existentes |

No se borra `~/.codex/packages`: pueden existir instalaciones anteriores,
software gestionado por el usuario u otros usos que no corresponde migrar
con una eliminación indiscriminada.

## Parches y cambios del port

Los cinco archivos Rust relacionados con esta integración son:

| Parche | Propósito |
| --- | --- |
| `patch-codex-rs_app-server-daemon_src_managed_install_rs` | Existente: path compilado prioritario y exclusión de updater latest-channel |
| `patch-codex-rs_app-server-daemon_src_prepare_install_rs` | Ampliado: bypass de copia; valida manifest semver y versión del ELF con timeout; rechaza --from-cli |
| `patch-codex-rs_app-server-daemon_src_lib_rs` | Ampliado: API system_daemon_path, mantiene lifecycle, guardas de actualizaciones, diagnóstico pkg_add y rechazo de un daemon activo de otra versión |
| `patch-codex-rs_app-server-daemon_src_backend_pid_rs` | Existente: identidad ps estable bajo OpenBSD con locale/timezone fijados |
| `patch-codex-rs_tui_src_app_daemon_menu_rs` | Nuevo: sólo las acciones de instalar/reemplazar se deshabilitan; /daemon indica pkg_add y restart, el proceso sigue habilitado |

Otros parches del port, incluyendo Cargo, V8 y la política de actualización
al arrancar, no se modifican durante esta tarea.

Makefile: path compilado a libexec, generación del manifest, traslado de
los dos binarios y links durante post-install, `REVISION=0` para que
pkg_add reconozca el cambio respecto a 0.160.1 sin revisión.
PLIST: rutas reales de libexec, manifest y links.
`files/codex-package.json`: template pequeño con cinco campos.
`pkg/README`: uso, ownership, layout, reinicio, socket y migración.
No cambian MODULES, BUILD_DEPENDS, LIB_DEPENDS ni RUN_DEPENDS.
El override previo de MAKE_JOBS se conserva.

## Versionado, flujo resultante y actualización

```text
make -> codex-cli/codex + codex-code-mode-host + manifest de la misma ${V}
  |
pkg_add codex
  +-- instala ELF compartido CLI/daemon, host, manifest y links
         |
       codex
         +-- daemon_auto_start, política de elegibilidad upstream
         +-- resolver central -> ejecutable del sistema
         +-- manifest.version == CARGO_PKG_VERSION
         +-- ejecutable --version == CARGO_PKG_VERSION
         +-- start con setsid / backend PID
         +-- initialize / initialized / health check / JSON-RPC sobre UDS
         +-- running app_server_version == CARGO_PKG_VERSION al iniciar/reusar
         +-- stop / restart y recovery existentes
```

Upstream permite versiones distintas en algunas instalaciones/updates.
El modo sistema endurece el arranque: versión exacta de CLI, manifest y
nuevo ejecutable. Si se intenta reutilizar un daemon vivo de otra versión,
se informa y se pide `codex app-server daemon restart`; no se interrumpe
trabajo automáticamente ni se selecciona una copia autodownloaded.
El mismo ELF para CLI y servidor garantiza además identidad de build
instalado. Upstream registra digest BLAKE3 del proceso; no se inventa
otra versión de protocolo ni un build ID en el manifest.

`pkg_add -u` reemplaza simultáneamente los archivos pertenecientes al
paquete; el proceso que ya corre mantiene su imagen antigua. El usuario
reinicia explícitamente el daemon para recoger el nuevo build, también
cuando sólo cambia la revisión del port y la versión upstream es igual.
`update` devuelve UpdateStatus::Unsupported con indicación de pkg_add;
`--from-cli` y `pid-update-loop` se rechazan antes de copia/download.
Un settings.json previo con autoUpdateEnabled=true no habilita el updater
en modo sistema. Codex sólo modifica archivos de estado de usuario.

## Mantenibilidad y validación estática

El conjunto de cinco parches de integración añade 103 líneas Rust y reemplaza tres líneas, contando las guardas ya
existentes. La nueva extensión afecta a tres archivos Rust; los otros
dos parches de daemon se conservan. El layout no requiere parchear el
resolver de manifest, los shims JS, el protocolo ni el motor app-server.
La superficie de conflictos es moderada en `Daemon::start`, `prepare` y
el menú TUI, que upstream cambia con frecuencia; el resolver central es
pequeño y fácil de reaplicar.

Sería razonable proponer upstream un provider de daemon compilado por el
distribuidor, ownership público para la UI y validación de metadata/version,
con un mensaje configurable para el gestor de paquetes. La corrección de
locale/TZ de ps también es independiente de la distribución de binarios.

Comprobaciones realizadas: los 84 parches de Codex se aplicaron sobre las
fuentes exactas y las crates parcheadas, sin fuzz, offsets ni rechazos; los
checksums de estas crates se verificaron contra Cargo.lock. También se
comprobaron los dos parches de micro 2.0.15, sin fuzz ni offsets. Los tres
parches nuevos/ampliados se regeneraron y se reaplicaron sobre fuentes
pristine con resultado idéntico. rustfmt comprobó
la sintaxis/formato de los archivos modificados (no es un type-check).
Se comprobó mediante layout temporal de archivos/enlaces la canonicalización,
localización de JSON y host, y correspondencia de PLIST para ambas
arquitecturas. bmake expandió ambos triples; el JSON resultante es válido.
No se compiló, no se ejecutaron tests Rust, no se arrancó Codex, no se
instalaron paquetes ni se hizo push.

## Validación posterior: ejecutar en OpenBSD -current

Desde el checkout colocado en un árbol de ports compatible con -current:

```sh
cd devel/codex
make clean
make makesum                    # distinfo actual aún nombra 0.160.0
make build
make fake
make lib-depends-check
make update-plist
# Revisar el PLIST generado antes de crear el paquete.
make package
# Si había un daemon antiguo, detenerlo con la CLI antigua antes de actualizar.
codex app-server daemon stop
# Para primera instalación, omitir la parada anterior si codex no existe.
doas pkg_add -r "$(make show=PKGFILE)"
pkg_info -L codex
pkg_info -f codex
ldd /usr/local/libexec/codex/bin/codex
ldd /usr/local/libexec/codex/bin/codex-code-mode-host
ls -l /usr/local/bin/codex /usr/local/bin/codex-code-mode-host
cat /usr/local/libexec/codex/codex-package.json
/usr/local/libexec/codex/bin/codex --version
```

Para probar lifecycle y ausencia de copias sin tocar la configuración
habitual, elegir un CODEX_HOME nuevo. Este comando prueba primero el daemon,
luego la TUI (el usuario completará login si procede):

```sh
CODEX_HOME=$(mktemp -d /tmp/codex-daemon-check.XXXXXXXX)
export CODEX_HOME
codex app-server daemon start
codex app-server daemon version
ps -ax -o pid,ppid,command | grep '[c]odex.*app-server'
ls -l "$CODEX_HOME/app-server-control/"
cat "$CODEX_HOME/app-server-daemon/daemon.pid"
cat "$CODEX_HOME/app-server-daemon/daemon.stderr.log"
codex --enable daemon_auto_start
# Tras salir de la TUI: debe seguir vivo y ser reutilizable.
codex app-server daemon version
codex app-server daemon restart
codex app-server daemon update       # Unsupported + pkg_add; sin descarga
codex app-server daemon update --from-cli --yes  # rechazo antes de copiar
# Debe seguir funcionando tras rechazar las actualizaciones internas.
codex app-server daemon version
codex app-server daemon stop
test ! -e "$CODEX_HOME/packages/app-server-daemon"
test ! -e "$CODEX_HOME/packages/standalone"
find "$CODEX_HOME" -type f \( -perm -0100 -o -perm -0010 -o -perm -0001 \) -print
# No debe aparecer ningún codex/host autodownloaded.
```

`version` debe mostrar `managedCodexPath` en libexec y versiones compatibles;
el PID/IPC deben funcionar en start, reutilización, restart y stop. Un home
limpio permite comprobar que no se generó ninguna segunda copia sin
confundir archivos viejos. Para confirmar auto-start desde cero en la TUI,
volver a ejecutar `codex --enable daemon_auto_start` después de stop y
consultar `version` desde otro terminal con el mismo CODEX_HOME.

Para comprobar la actualización de paquetes en uso normal:

```sh
doas pkg_add -u codex
codex app-server daemon restart
codex app-server daemon version
```

Si falta un binario o el manifest, conservar el mensaje completo y el log:
la reparación esperada es reinstalar el paquete, no instalar un daemon en
el home. La prueba interactiva y el error histórico `can't start` permanecen
pendientes de verificación real y, para este último, del log original.
