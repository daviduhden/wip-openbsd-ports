//! Candidate PF rules, NOT a kernel firewall implementation.
//!
//! A dedicated anchor preserves unrelated rules, but cannot by itself ensure
//! evaluation before earlier quick rules, undo `set skip`, or revoke existing
//! floating states. No load function is exposed until those invariants have
//! a verified implementation. Never equate rendering with applying a policy.

use crate::InterfaceName;
use std::{fmt::Write, io, net::SocketAddr};

#[derive(Clone, Copy, Debug)]
pub enum Protocol {
    Tcp,
    Udp,
}

#[derive(Clone, Debug)]
pub struct Endpoint {
    pub address: SocketAddr,
    pub protocol: Protocol,
}

/// Deliberately only the strict blocked/connecting subset is represented.
/// Connected policy needs DNS restrictions, AllowedTunnelTraffic, interface
/// ownership, LAN exceptions and state revocation before it can be supported.
pub fn blocked_candidate(endpoints: &[Endpoint]) -> io::Result<String> {
    let mut out = String::from("# Candidate only: not sufficient to enforce a kill switch.\n");
    out.push_str("pass quick on lo0 all no state\n");
    // Explicit IPv4 and IPv6 base exceptions from docs/security.md.
    out.push_str(
        "pass out quick inet proto udp from any port 68 to 255.255.255.255 port 67 no state\n",
    );
    out.push_str("pass in quick inet proto udp from any port 67 to any port 68 no state\n");
    out.push_str("pass out quick inet6 proto udp from fe80::/10 port 546 to { ff02::1:2, ff05::1:3 } port 547 no state\n");
    out.push_str(
        "pass in quick inet6 proto udp from fe80::/10 port 547 to fe80::/10 port 546 no state\n",
    );
    out.push_str(
        "pass out quick inet6 proto icmp6 to ff02::2 icmp6-type routersol code 0 no state\n",
    );
    out.push_str(
        "pass in quick inet6 proto icmp6 from fe80::/10 icmp6-type routeradv code 0 no state\n",
    );
    out.push_str(
        "pass in quick inet6 proto icmp6 from fe80::/10 icmp6-type redir code 0 no state\n",
    );
    out.push_str("pass out quick inet6 proto icmp6 to { ff02::1:ff00:0/104, fe80::/10 } icmp6-type neighbrsol code 0 no state\n");
    out.push_str(
        "pass in quick inet6 proto icmp6 from fe80::/10 icmp6-type neighbrsol code 0 no state\n",
    );
    out.push_str(
        "pass out quick inet6 proto icmp6 to fe80::/10 icmp6-type neighbradv code 0 no state\n",
    );
    out.push_str("pass in quick inet6 proto icmp6 icmp6-type neighbradv code 0 no state\n");
    for endpoint in endpoints {
        let ip = endpoint.address.ip();
        if endpoint.address.port() == 0
            || ip.is_unspecified()
            || ip.is_multicast()
            || ip.is_loopback()
            || matches!(endpoint.address, SocketAddr::V6(v6) if v6.scope_id() != 0 || v6.ip().is_unicast_link_local())
        {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "invalid peer endpoint",
            ));
        }
        let af = if ip.is_ipv4() { "inet" } else { "inet6" };
        let protocol = match endpoint.protocol {
            Protocol::Tcp => "tcp",
            Protocol::Udp => "udp",
        };
        // Root restriction matches the privileged userspace tunnel/API model.
        // It is not a per-process boundary; do not extend this to arbitrary UIDs.
        writeln!(out, "pass out quick {af} proto {protocol} to {ip} port {} user 0 keep state (if-bound) label \"mullvad-endpoint\"", endpoint.address.port()).unwrap();
    }
    out.push_str("block drop quick all\n");
    Ok(out)
}

/// There is intentionally no successful placeholder for installing PF rules.
pub fn require_verified_integration(_tunnel: &InterfaceName) -> io::Result<()> {
    Err(io::Error::new(
        io::ErrorKind::Unsupported,
        "PF anchor reachability, state revocation and DNS/IPv6 policy are not implemented",
    ))
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn strict_policy_covers_both_families_and_ends_in_block() {
        let policy = blocked_candidate(&[]).unwrap();
        assert!(policy.contains("inet proto"));
        assert!(policy.contains("inet6 proto"));
        assert!(policy.ends_with("block drop quick all\n"));
        assert!(!policy.contains("keep state"));
    }
    #[test]
    fn endpoint_rules_are_numeric_and_privileged() {
        let policy = blocked_candidate(&[Endpoint {
            address: "[2001:db8::1]:51820".parse().unwrap(),
            protocol: Protocol::Udp,
        }])
        .unwrap();
        assert!(policy.contains("inet6 proto udp to 2001:db8::1 port 51820 user 0"));
        assert!(policy.contains("keep state (if-bound)"));
        assert!(
            blocked_candidate(&[Endpoint {
                address: "0.0.0.0:0".parse().unwrap(),
                protocol: Protocol::Tcp,
            }])
            .is_err()
        );
    }
    #[test]
    fn incomplete_firewall_never_reports_success() {
        assert_eq!(
            require_verified_integration(&InterfaceName::new("tun0").unwrap())
                .unwrap_err()
                .kind(),
            io::ErrorKind::Unsupported
        );
    }
}
