package com.packetloop.packetpig.loaders.pcap.packet;

// http://en.wikipedia.org/wiki/IPv4_header#Header
// version, headerLength, dscp, ecn, total_length, id, flags, fragment_offset, ttl, proto, checksum, src, dst

// http://en.wikipedia.org/wiki/Transmission_Control_Protocol#TCP_segment_structure
// sport, dport, seq, ack, offset, ns, cwr, ece, urg, ack, psh, rst, syn, fin, window, checksum, urg_pointer

import org.apache.pig.data.Tuple;
import org.apache.pig.data.TupleFactory;
import org.krakenapps.pcap.decoder.ip.Ipv4Packet;
import org.krakenapps.pcap.decoder.tcp.TcpPacket;
import org.krakenapps.pcap.decoder.udp.UdpPacket;
import org.krakenapps.pcap.packet.PcapPacket;

public class PacketTuple {
    public Class packetType;
    public PcapPacket packet;

    // ipv4 fields
    private int version;
    private int headerLength;
    private int tos;
    private int totalLen;
    private int id;
    private int flags;
    private int fragOffset;
    private int ttl;
    private int proto;
    private int headerChecksum;
    private String src;
    private String dst;

    // tcp fields
    private int sport;
    private int dport;
    private long seqId;
    private long ackId;
    private int offset;
    private int ns;
    private int cwr;
    private int ece;
    private int urg;
    private int psh;
    private int rst;
    private int syn;
    private int fin;
    private int window;
    private int tcpSize;
    private int ack;

    // udp fields
    private int udpSport;
    private int udpDport;
    private int udpLength;
    private int udpChecksum;
    private String tcpData;

    public void setIpv4PacketFields(Ipv4Packet p) {
        version = p.getVersion();
        headerLength = p.getIhl();
        tos = p.getTos();
        totalLen = p.getTotalLength();
        id = p.getId();
        flags = p.getFlags();
        fragOffset = p.getFragmentOffset();
        ttl = p.getTtl();
        proto = p.getProtocol();
        headerChecksum = p.getHeaderChecksum();
        src = ipToString(p.getSource());
        dst = ipToString(p.getDestination());
        packetType = Ipv4Packet.class;
    }

    public void setTcpFields(TcpPacket p) {
        sport = p.getSourcePort();
        dport = p.getDestinationPort();
        seqId = p.getSeq();
        ackId = p.getAck();
        offset = p.getDataOffset();

        int f = p.getFlags();
        ns  = (f & 256) == 0 ? 0 : 1;
        cwr = (f & 128) == 0 ? 0 : 1;
        ece = (f &  64) == 0 ? 0 : 1;
        urg = (f &  32) == 0 ? 0 : 1;
        ack = (f &  16) == 0 ? 0 : 1;
        psh = (f &   8) == 0 ? 0 : 1;
        rst = (f &   4) == 0 ? 0 : 1;
        syn = (f &   2) == 0 ? 0 : 1;
        fin = (f &   1) == 0 ? 0 : 1;

        window = p.getWindow();
        tcpSize = p.getDataLength();

        if (p.getData() != null) {
            byte[] buf = new byte[p.getDataLength()];
            p.getData().gets(buf);
            tcpData = new String(buf);
        } else {
            tcpData = null;
        }
    }

    public void setUdpFields(UdpPacket p) {
        udpSport = p.getSourcePort();
        udpDport = p.getDestinationPort();
        udpLength = p.getLength();
        udpChecksum = p.getChecksum();
    }

    public Tuple getValue() {
        Tuple t = TupleFactory.getInstance().newTuple();

        t.append(version);
        t.append(headerLength);
        t.append(tos);
        t.append(totalLen);
        t.append(id);
        t.append(flags);
        t.append(fragOffset);
        t.append(ttl);
        t.append(proto);
        t.append(headerChecksum);
        t.append(src);
        t.append(dst);

        t.append(sport);
        t.append(dport);
        t.append(seqId);
        t.append(ackId);
        t.append(offset);
        t.append(ns);
        t.append(cwr);
        t.append(ece);
        t.append(urg);
        t.append(ack);
        t.append(psh);
        t.append(rst);
        t.append(syn);
        t.append(fin);
        t.append(window);
        t.append(tcpSize);

        t.append(udpSport);
        t.append(udpDport);
        t.append(udpLength);
        t.append(udpChecksum);

        t.append(tcpData);

        return t;
    }

    private String ipToString(int addr) {
        return (addr >> 24 & 0xFF) + "." +
                (addr >> 16 & 0xFF) + "." +
                (addr >> 8 & 0xFF) + "." +
                (addr & 0xFF);
    }
}
