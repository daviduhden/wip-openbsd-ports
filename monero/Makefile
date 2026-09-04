COMMENT = secure, private and untraceable digital currency

VERSION = 0.18.5.1
PKGNAME = monero-${VERSION}
DISTNAME = monero-source-v${VERSION}
SITES = https://downloads.getmonero.org/cli/
EXTRACT_SUFX = .tar.bz2

CATEGORIES = net
HOMEPAGE = https://getmonero.org
MAINTAINER = David Uhden Collado <daviduhden@gmail.com>

# BSD 3-Clause "New" or "Revised" License
PERMIT_PACKAGE = Yes
ONLY_FOR_ARCHS = amd64 i386 arm64 armv7 riscv64

WANTLIB += ${COMPILER_LIBCXX} boost_chrono-mt boost_date_time-mt
WANTLIB += boost_filesystem-mt boost_locale-mt boost_program_options-mt
WANTLIB += boost_serialization-mt boost_thread-mt c crypto curses
WANTLIB += ereadline execinfo hidapi-libusb m protobuf sodium ssl
WANTLIB += unbound usb-1.0 utf8_validity zmq
WANTLIB += absl_base absl_borrowed_fixup_buffer absl_city absl_civil_time
WANTLIB += absl_cord absl_cord_internal absl_cordz_functions absl_cordz_handle
WANTLIB += absl_cordz_info absl_crc32c absl_crc_cord_state absl_crc_cpu_detect
WANTLIB += absl_crc_internal absl_debugging_internal absl_decode_rust_punycode
WANTLIB += absl_demangle_internal absl_demangle_rust absl_die_if_null
WANTLIB += absl_examine_stack absl_exponential_biased
WANTLIB += absl_flags_commandlineflag absl_flags_commandlineflag_internal
WANTLIB += absl_flags_config absl_flags_internal absl_flags_marshalling
WANTLIB += absl_flags_private_handle_accessor absl_flags_program_name
WANTLIB += absl_flags_reflection absl_graphcycles_internal absl_hash
WANTLIB += absl_hashtablez_sampler absl_int128 absl_kernel_timeout_internal
WANTLIB += absl_leak_check absl_log_entry absl_log_globals absl_log_initialize
WANTLIB += absl_log_internal_check_op absl_log_internal_conditions
WANTLIB += absl_log_internal_fnmatch absl_log_internal_format
WANTLIB += absl_log_internal_globals absl_log_internal_log_sink_set
WANTLIB += absl_log_internal_message absl_log_internal_nullguard
WANTLIB += absl_log_internal_proto absl_log_internal_structured_proto
WANTLIB += absl_log_severity absl_log_sink absl_malloc_internal
WANTLIB += absl_random_distributions absl_random_internal_entropy_pool
WANTLIB += absl_random_internal_platform absl_random_internal_randen
WANTLIB += absl_random_internal_randen_hwaes
WANTLIB += absl_random_internal_randen_hwaes_impl
WANTLIB += absl_random_internal_randen_slow
WANTLIB += absl_random_internal_seed_material absl_random_seed_gen_exception
WANTLIB += absl_random_seed_sequences absl_raw_hash_set
WANTLIB += absl_raw_logging_internal absl_spinlock_wait absl_stacktrace
WANTLIB += absl_status absl_statusor absl_str_format_internal absl_strerror
WANTLIB += absl_strings absl_strings_internal absl_symbolize
WANTLIB += absl_synchronization absl_throw_delegate absl_time absl_time_zone
WANTLIB += absl_tracing_internal absl_utf8_for_code_point
WANTLIB += absl_vlog_config_internal

COMPILER = base-clang
MODULES = devel/cmake
BUILD_DEPENDS = devel/ninja \
		  devel/re2c

CONFIGURE_ARGS += -GNinja \
		  -Wno-dev \
		  -DDEPENDS=ON \
		  -DMANUAL_SUBMODULES=ON \
		  -DBUILD_DOCUMENTATION=OFF

LIB_DEPENDS = devel/abseil-cpp \
		devel/boost \
		devel/libusb1 \
		devel/protobuf \
		devel/readline \
		net/zeromq \
		net/libunbound \
		comms/libhidapi

TEST_DEPENDS = lang/python/3

do-install:
	${INSTALL_PROGRAM} ${WRKBUILD}/bin/* ${PREFIX}/bin/
	${INSTALL_DATA} ${WRKBUILD}/lib/* ${PREFIX}/lib/
	${INSTALL_DATA_DIR} ${PREFIX}/include/wallet
	${INSTALL_DATA_DIR} ${PREFIX}/include/wallet/api
	${INSTALL_DATA} ${WRKSRC}/src/wallet/api/wallet2_api.h ${PREFIX}/include/wallet/api/
	${INSTALL_DATA_DIR} ${SYSCONFDIR}/monero
	${INSTALL_DATA} ${WRKSRC}/utils/conf/monerod.conf ${SYSCONFDIR}/monero/
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/lib/monero
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/log/monero

.include <bsd.port.mk>
