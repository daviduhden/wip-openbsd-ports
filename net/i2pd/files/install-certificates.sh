#!/bin/sh
# Install the family and reseed certificate directories under LOCALSTATEDIR.

set -eu

: "${WRKINST:?}" "${LOCALSTATEDIR:?}" "${WRKDIST:?}"
: "${INSTALL_DATA:?}" "${INSTALL_DATA_DIR:?}"

install_data() {
	# shellcheck disable=SC2086
	$INSTALL_DATA "$@"
}
install_data_dir() {
	# shellcheck disable=SC2086
	$INSTALL_DATA_DIR "$@"
}

for certificate_directory in family reseed; do
	destination="$WRKINST$LOCALSTATEDIR/i2pd/certificates/$certificate_directory"
	install_data_dir "$destination"
	install_data \
		"$WRKDIST/contrib/certificates/$certificate_directory/"* \
		"$destination/"
done
