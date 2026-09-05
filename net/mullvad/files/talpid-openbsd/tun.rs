//! OpenBSD tun(4) packet framing, independent of the tunnel engine.
//! Unlike Linux IFF_NO_PI, OpenBSD always supplies a four-byte network-order
//! address family. The values below are OpenBSD values, not the build host's.

use std::io;

const AF_INET_OPENBSD: u32 = 2;
const AF_INET6_OPENBSD: u32 = 24;

fn family(packet: &[u8]) -> io::Result<u32> {
    match packet.first().map(|byte| byte >> 4) {
        Some(4) if packet.len() >= 20 => Ok(AF_INET_OPENBSD),
        Some(6) if packet.len() >= 40 => Ok(AF_INET6_OPENBSD),
        _ => Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "not a complete IPv4/IPv6 header",
        )),
    }
}

pub fn encode(packet: &[u8]) -> io::Result<Vec<u8>> {
    let mut frame = family(packet)?.to_be_bytes().to_vec();
    frame.extend_from_slice(packet);
    Ok(frame)
}

pub fn decode(frame: &[u8]) -> io::Result<&[u8]> {
    let (header, packet) = frame
        .split_at_checked(4)
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "short tun frame"))?;
    let header = u32::from_be_bytes(header.try_into().unwrap());
    if header != family(packet)? {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "tun family/header mismatch",
        ));
    }
    Ok(packet)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn framing_roundtrips_v4_v6() {
        for (version, length, family) in [(4, 20, 2), (6, 40, 24)] {
            let mut packet = vec![0; length];
            packet[0] = version << 4;
            let frame = encode(&packet).unwrap();
            assert_eq!(&frame[..4], &[0, 0, 0, family]);
            assert_eq!(decode(&frame).unwrap(), packet);
        }
    }
    #[test]
    fn rejects_mismatch_truncation_and_non_ip() {
        for packet in [vec![], vec![0x45], vec![0x60; 39], vec![0x70; 40]] {
            assert!(encode(&packet).is_err());
        }
        let mut packet = vec![0x45; 20];
        let mut frame = encode(&packet).unwrap();
        frame[3] = 24;
        assert!(decode(&frame).is_err());
        packet[0] = 0;
        assert!(encode(&packet).is_err());
        assert!(decode(&[0, 0, 0]).is_err());
    }
}
