//! Native primitives for the prospective OpenBSD daemon backend.
//!
//! This is NOT an operational VPN backend. In particular a PF policy string
//! is not proof of leak protection. Installation is deliberately unavailable
//! until anchor ordering, skipped interfaces and existing states are checked.
//! The C bridge uses native headers, not guessed copies of kernel ABI structs.

pub mod pf;
pub mod tun;

use std::{io, net::IpAddr};

/// Validated kernel interface name, never a shell command or PF expression.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct InterfaceName(String);

impl InterfaceName {
    pub fn new(name: &str) -> io::Result<Self> {
        if name.is_empty()
            || name.len() >= 16
            || !name.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'_')
            || !name.as_bytes()[0].is_ascii_alphabetic()
        {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "invalid interface name",
            ));
        }
        Ok(Self(name.to_owned()))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

/// Proposal only: acceptance by the kernel is NOT an acknowledgement that
/// resolvd installed this policy, or that unwind/other DNS cannot bypass it.
#[derive(Clone, Debug)]
pub struct DnsProposal {
    pub interface: InterfaceName,
    servers: Vec<IpAddr>,
}

impl DnsProposal {
    pub fn new(interface: InterfaceName, servers: Vec<IpAddr>) -> io::Result<Self> {
        if servers.len() > 5
            || servers.iter().any(|ip| {
                ip.is_unspecified()
                    || ip.is_multicast()
                    || ip.is_loopback()
                    || matches!(ip, IpAddr::V6(v6) if v6.is_unicast_link_local())
            })
        {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "unsupported DNS address list",
            ));
        }
        Ok(Self { interface, servers })
    }

    /// Empty lists withdraw both address families. This never edits resolv.conf.
    #[cfg(target_os = "openbsd")]
    pub fn publish(&self) -> io::Result<()> {
        use std::ffi::CString;
        let name = CString::new(self.interface.as_str()).unwrap();
        let mut v4 = Vec::new();
        let mut v6 = Vec::new();
        for ip in &self.servers {
            match ip {
                IpAddr::V4(ip) => v4.extend(ip.octets()),
                IpAddr::V6(ip) => v6.extend(ip.octets()),
            }
        }
        // SAFETY: Valid nul-terminated name, lengths in address units and
        // live byte slices. native.c neither keeps nor modifies these pointers.
        let result = unsafe {
            mv_dns_propose(
                name.as_ptr(),
                v4.as_ptr(),
                v4.len() / 4,
                v6.as_ptr(),
                v6.len() / 16,
            )
        };
        cvt(result).map(|_| ())
    }

    pub fn servers(&self) -> &[IpAddr] {
        &self.servers
    }
}

/// Open an event-driven routing socket. Consumers must treat RTM_DESYNC or
/// read errors as loss of knowledge, block traffic and resnapshot both families.
#[cfg(target_os = "openbsd")]
pub fn route_monitor() -> io::Result<std::os::fd::OwnedFd> {
    use std::os::fd::FromRawFd;
    // SAFETY: This call transfers ownership of a new nonblocking descriptor.
    let fd = cvt(unsafe { mv_route_monitor() })?;
    Ok(unsafe { std::os::fd::OwnedFd::from_raw_fd(fd) })
}

/// Opaque native route messages; parsing and ownership-based mutation remain
/// work for talpid-routing. This is not a default-route selection algorithm.
#[cfg(target_os = "openbsd")]
pub fn route_snapshot() -> io::Result<Vec<u8>> {
    let mut data = std::ptr::null_mut();
    let mut length = 0;
    // SAFETY: Both out-pointers are valid; C returns an owned allocation.
    cvt(unsafe { mv_route_snapshot(&mut data, &mut length) })?;
    if length == 0 {
        return Ok(Vec::new());
    }
    // SAFETY: Successful native call guarantees length readable bytes.
    let bytes = unsafe { std::slice::from_raw_parts(data, length) }.to_vec();
    // SAFETY: Free exactly once with the allocator used by the C bridge.
    unsafe { mv_route_snapshot_free(data) };
    Ok(bytes)
}

#[cfg(target_os = "openbsd")]
fn cvt(value: i32) -> io::Result<i32> {
    if value == -1 {
        Err(io::Error::last_os_error())
    } else {
        Ok(value)
    }
}

#[cfg(target_os = "openbsd")]
unsafe extern "C" {
    fn mv_dns_propose(
        name: *const std::ffi::c_char,
        v4: *const u8,
        n4: usize,
        v6: *const u8,
        n6: usize,
    ) -> i32;
    fn mv_route_monitor() -> i32;
    fn mv_route_snapshot(data: *mut *mut u8, length: *mut usize) -> i32;
    fn mv_route_snapshot_free(data: *mut u8);
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn interface_names_reject_injection_and_overflow() {
        for name in [
            "",
            "-a",
            "tun0\npass all",
            "tun0;id",
            "(egress)",
            "0123",
            "abcdefghijklmnop",
        ] {
            assert!(InterfaceName::new(name).is_err(), "{name}");
        }
        assert!(InterfaceName::new("tun0").is_ok());
    }
    #[test]
    fn dns_validates_both_families_and_limit() {
        let iface = InterfaceName::new("tun0").unwrap();
        let servers = vec!["10.64.0.1".parse().unwrap(), "fc00::1".parse().unwrap()];
        assert_eq!(
            DnsProposal::new(iface.clone(), servers.clone())
                .unwrap()
                .servers(),
            servers
        );
        for ip in [
            "0.0.0.0",
            "::",
            "::1",
            "127.0.0.1",
            "fe80::1",
            "ff02::1",
            "224.0.0.1",
        ] {
            assert!(DnsProposal::new(iface.clone(), vec![ip.parse().unwrap()]).is_err());
        }
        assert!(DnsProposal::new(iface.clone(), vec!["10.64.0.1".parse().unwrap(); 6]).is_err());
        assert!(
            DnsProposal::new(iface, vec![])
                .unwrap()
                .servers()
                .is_empty()
        );
    }
}
