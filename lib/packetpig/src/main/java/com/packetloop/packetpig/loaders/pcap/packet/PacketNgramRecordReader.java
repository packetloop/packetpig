package com.packetloop.packetpig.loaders.pcap.packet;

import com.packetloop.packetpig.loaders.pcap.PcapRecordReader;
import org.apache.axis.types.UnsignedByte;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.pig.data.TupleFactory;
import org.krakenapps.pcap.decoder.ethernet.EthernetFrame;
import org.krakenapps.pcap.decoder.ethernet.EthernetType;
import org.krakenapps.pcap.decoder.ip.InternetProtocol;
import org.krakenapps.pcap.decoder.ip.IpDecoder;
import org.krakenapps.pcap.decoder.ip.Ipv4Packet;
import org.krakenapps.pcap.decoder.tcp.TcpDecoder;
import org.krakenapps.pcap.decoder.tcp.TcpPacket;
import org.krakenapps.pcap.decoder.tcp.TcpPortProtocolMapper;
import org.krakenapps.pcap.decoder.udp.UdpDecoder;
import org.krakenapps.pcap.decoder.udp.UdpPacket;
import org.krakenapps.pcap.decoder.udp.UdpPortProtocolMapper;
import org.krakenapps.pcap.decoder.udp.UdpProcessor;
import org.krakenapps.pcap.packet.PcapPacket;
import org.krakenapps.pcap.util.Buffer;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;

public class PacketNgramRecordReader extends PcapRecordReader {
    private ArrayList<UnsignedByte> ipData, tcpData, udpData;
    private int n;
    private HashMap<ArrayList<UnsignedByte>, Integer> cache = new HashMap<ArrayList<UnsignedByte>, Integer>();
    private UnsignedByte[] byteKey;
    private PacketFilter filter;
    public Ipv4Packet ipPacket;
    private TcpPacket tcpPacket;
    private UdpPacket udpPacket;
    private boolean done;

    public PacketNgramRecordReader(String filter, int n) {
        this.filter = new PacketFilter(filter);
        this.n = n;
    }

    @Override
    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        super.initialize(split, context);

        IpDecoder ipDecoder = new IpDecoder() {

            @Override
            public void process(EthernetFrame frame) {
                ipPacket = Ipv4Packet.parse(frame.getBuffer());
                ipData = copyData(ipPacket.getData());
                super.process(frame);
            }
        };

        TcpDecoder tcpDecoder = new TcpDecoder(new TcpPortProtocolMapper()) {
            @Override
            public void process(Ipv4Packet packet) {
                tcpPacket = TcpPacket.parse(packet);
                tcpData = copyData(tcpPacket.getData());
            }
        };

        UdpProcessor udpProcessor = new UdpProcessor() {
            @Override
            public void process(UdpPacket p) {
                udpPacket = p;
                udpData = copyData(p.getData());
            }
        };

        UdpDecoder udpDecoder = new UdpDecoder(new UdpPortProtocolMapper()) {
            @Override
            public void process(Ipv4Packet packet) {
                // nothing really
                super.process(packet);
            }
        };

        udpDecoder.registerUdpProcessor(udpProcessor);

        eth.register(EthernetType.IPV4, ipDecoder);
        ipDecoder.register(InternetProtocol.TCP, tcpDecoder);
        ipDecoder.register(InternetProtocol.UDP, udpDecoder);

        byteKey = new UnsignedByte[n];
        for (int i = 0; i < n; i++)
            byteKey[i] = new UnsignedByte(0);
    }

    private ArrayList<UnsignedByte> copyData(Buffer buf) {
        if (buf == null)
            return null;

        ArrayList<UnsignedByte> data = new ArrayList<UnsignedByte>();

        for (byte[] ary : buf.getBuffers())
            for (short b : ary) {
                if (b < 0)
                    b += 256;
                data.add(new UnsignedByte(b));
            }

        return data;
    }

    @Override
    public boolean nextKeyValue() throws IOException, InterruptedException {
        try {
            while (true) {
                ipData = tcpData = udpData = null;
                ipPacket = null;
                tcpPacket = null;
                udpPacket = null;

                PcapPacket packet = is.getPacket();
                eth.decode(packet);

                if (filter.matches(packet, ipPacket, tcpPacket, udpPacket)) {
                    switch (filter.getProto()) {
                        case InternetProtocol.TCP:
                            //System.err.println("ngram: " + ipPacket.getSourceAddress() + ":" + tcpPacket.getSourcePort() + " -> " + ipPacket.getDestinationAddress() + ":" + tcpPacket.getDestinationPort());
                            updateNgram(tcpData, n);
                            break;

                        case InternetProtocol.UDP:
                            //System.err.println("ngram: " + ipPacket.getSourceAddress() + ":" + udpPacket.getSourcePort() + " -> " + ipPacket.getDestinationAddress() + ":" + udpPacket.getDestinationPort());
                            updateNgram(udpData, n);
                            break;

                        default:
                            //System.err.println("ngram: " + ipPacket.getSourceAddress() + " -> " + ipPacket.getDestinationAddress());
                            updateNgram(ipData, n);
                            break;
                    }
                }
            }
        } catch (IOException ignored) {
            is.close();
        }

        key = 0;
        tuple = TupleFactory.getInstance().newTuple();

        ArrayList<UnsignedByte> k = new ArrayList<UnsignedByte>();
        Collections.addAll(k, byteKey);
        int value = cache.containsKey(k) ? cache.get(k) : 0;

        tuple.append(filter.getFilterString());
        tuple.append(intValue(byteKey));
        tuple.append(value);

        if (done)
            return false;

        if (!canIncrementByteKey())
            done = true;
        else
            incrementByteKey();

        return true;
    }

    private int intValue(UnsignedByte[] byteKey) {
        int v = 0;
        for (int i = 0; i < n; i++)
            v += byteKey[i].intValue() << 8 * (n - i - 1);

        return v;
    }

    private boolean canIncrementByteKey() {
        boolean incrementable = false;
        for (int i = 0; i < n; i++)
            if (!byteKey[i].equals(new UnsignedByte(255)))
                incrementable = true;
        return incrementable;
    }

    private void incrementByteKey() {
        if (n > 2) {
            incrementByteKeyIndex(n - 1);
        } else if (n == 2) {
            if (byteKey[n - 1].equals(new UnsignedByte(255))) {
                byteKey[n - 2] = new UnsignedByte(byteKey[0].intValue() + 1);
                byteKey[n - 1] = new UnsignedByte(0);
            } else {
                byteKey[1] = new UnsignedByte(byteKey[1].intValue() + 1);
            }
        } else {
            byteKey[0] = new UnsignedByte(byteKey[0].intValue() + 1);
        }
    }

    private void incrementByteKeyIndex(int i) {
        if (byteKey[i].equals(new UnsignedByte(255))) {
            byteKey[i] = new UnsignedByte(0);

            if (i > 0)
                incrementByteKeyIndex(i - 1);
        } else {
            byteKey[i] = new UnsignedByte(byteKey[i].intValue() + 1);
        }
    }

    private void updateNgram(ArrayList<UnsignedByte> data, int n) {
        if (data != null && !data.isEmpty()) {
            int i = 0;
            while (i + n < data.size()) {
                int _v = 1;

                ArrayList<UnsignedByte> buf = new ArrayList<UnsignedByte>();

                for (int j = 0; j < n; j++)
                    buf.add(data.get(i + j));

                if (cache.containsKey(buf))
                    _v += cache.get(buf);

                cache.put(buf, _v);

                i += 1;
            }
        }
    }
}
