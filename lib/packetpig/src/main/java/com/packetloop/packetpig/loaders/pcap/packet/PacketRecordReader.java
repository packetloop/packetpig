package com.packetloop.packetpig.loaders.pcap.packet;

import com.packetloop.packetpig.loaders.pcap.PcapRecordReader;
import org.apache.hadoop.mapreduce.Counter;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.pig.tools.pigstats.PigStatusReporter;
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

import java.io.IOException;
import java.nio.BufferUnderflowException;
import java.util.Date;

public class PacketRecordReader extends PcapRecordReader {
    private PacketTuple packetTuple;
    private static final PigStatusReporter s_statusReporter = PigStatusReporter.getInstance();
    private TaskAttemptContext taskAttemptContext;

    @Override
    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        taskAttemptContext = context;
        super.initialize(split, context);

        IpDecoder ipDecoder = new IpDecoder() {
            @Override
            public void process(EthernetFrame frame) {
                packetTuple.setIpv4PacketFields(Ipv4Packet.parse(frame.dup().getData()));
                super.process(frame);
            }
        };

        TcpDecoder tcpDecoder = new TcpDecoder(new TcpPortProtocolMapper()) {
            @Override
            public void process(Ipv4Packet packet) {
                try {
                    packetTuple.setTcpFields(TcpPacket.parse(packet));
                } catch (BufferUnderflowException e) {
                    System.err.println("Ignoring error in setTcpFields: " + e);
                }
            }
        };

        UdpProcessor udpProcessor = new UdpProcessor() {
            @Override
            public void process(UdpPacket p) {
                packetTuple.setUdpFields(p);
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
    }

    @Override
    public boolean nextKeyValue() throws IOException, InterruptedException {
        try {
            // keep going until the decoder says it found a good one.
            packetTuple = nextPacket();

            if (packetTuple == null) {
                is.close();
                return false;
            }

            while (packetTuple.packetType != Ipv4Packet.class)
                packetTuple = nextPacket();

            long tv_sec = packetTuple.packet.getPacketHeader().getTsSec();
            long tv_usec = packetTuple.packet.getPacketHeader().getTsUsec();
            long ts = tv_sec * 1000 + tv_usec / 1000;

            key = new Date(ts).getTime() / 1000;
            tuple = packetTuple.getValue();

            return true;

        } catch (BufferUnderflowException ignored) {
            is.close();
            return false;
        } catch (NegativeArraySizeException ignored) {
            is.close();
            return false;
        } catch (IOException ignored) {
            is.close();
            return false;
        }
    }

    private PacketTuple nextPacket() throws IOException {
        try {
            Counter counter = s_statusReporter.getCounter("PacketPig", "nextPacket");
            counter.increment(1);
        } catch (NullPointerException ignored) {
            // oh, hadoop :(
        }

        taskAttemptContext.progress();

        PcapPacket packet;

        try {
            packet = is.getPacket();
        } catch (NegativeArraySizeException ignored) {
            return null;
        }

        packetTuple = new PacketTuple();
        packetTuple.packet = packet;
        eth.decode(packet);
        return packetTuple;
    }
}
