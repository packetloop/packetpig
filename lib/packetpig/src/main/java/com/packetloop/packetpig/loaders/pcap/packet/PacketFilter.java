package com.packetloop.packetpig.loaders.pcap.packet;

import org.krakenapps.pcap.decoder.ip.InternetProtocol;
import org.krakenapps.pcap.decoder.ip.Ipv4Packet;
import org.krakenapps.pcap.decoder.tcp.TcpPacket;
import org.krakenapps.pcap.decoder.udp.UdpPacket;
import org.krakenapps.pcap.packet.PcapPacket;

public class PacketFilter {
    private int proto;
    private int port;
    private Object filterString;

    public PacketFilter(String filter) {
        filterString = filter;

        if (filter.isEmpty()) {
            proto = 0;
            port = 0;
            return;
        }

        // TODO only filters proto:dstport
        String[] parts = filter.split(":");
        proto = parseProto(parts[0]);
        port = Integer.parseInt(parsePort(parts[1]));
    }

    private int parseProto(String proto) {
        if (proto.toLowerCase().equals("tcp"))
            return InternetProtocol.TCP;

        if (proto.toLowerCase().equals("udp"))
            return InternetProtocol.UDP;

        return 0;
    }

    private String parsePort(String part) {
        return part;
    }

    public boolean matches(PcapPacket packet, Ipv4Packet ip, TcpPacket tcp, UdpPacket udp) {
        if (proto == 0)
            return true;

        switch (proto) {
            case InternetProtocol.TCP:
                if (tcp != null)
                    if (tcp.getSourcePort() == port || tcp.getDestinationPort() == port)
                        return true;
                break;

            case InternetProtocol.UDP:
                if (udp != null)
                    if (udp.getSourcePort() == port || udp.getDestinationPort() == port)
                        return true;
                break;
        }

        return false;
    }

    public int getProto() {
        return proto;
    }

    public int getPort() {
        return port;
    }


    public Object getFilterString() {
        return filterString;
    }
}
