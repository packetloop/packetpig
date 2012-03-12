package com.packetloop.packetpig.loaders.pcap;

import org.apache.hadoop.fs.FSDataInputStream;
import org.krakenapps.pcap.PcapInputStream;
import org.krakenapps.pcap.file.GlobalHeader;
import org.krakenapps.pcap.packet.PacketHeader;
import org.krakenapps.pcap.packet.PcapPacket;
import org.krakenapps.pcap.util.Buffer;
import org.krakenapps.pcap.util.ByteOrderConverter;
import org.krakenapps.pcap.util.ChainBuffer;

import java.io.IOException;
import java.nio.ByteBuffer;

public class PcapFSDataInputStream implements PcapInputStream {
    private GlobalHeader globalHeader;
    private FSDataInputStream is;
    private long length;
    private int offset;

    public PcapFSDataInputStream(FSDataInputStream data, long length) throws IOException {
        is = new FSDataInputStream(data);
        globalHeader = readGlobalHeader();
        this.length = length;
        this.offset = 0;
    }

    @Override
    public PcapPacket getPacket() throws IOException {
        return readPacket(globalHeader.getMagicNumber());
    }

    public final GlobalHeader readGlobalHeader() throws IOException {
        int bytesToRead = 4 + 2 + 2 + 4 + 4 + 4 + 4;
        byte[] buffer = new byte[bytesToRead];
        is.readFully(buffer);
        offset += bytesToRead;
        ByteBuffer buf = ByteBuffer.wrap(buffer);

        int magic = buf.getInt();
        short major = buf.getShort();
        short minor = buf.getShort();
        int tz = buf.getInt();
        int sigfigs = buf.getInt();
        int snaplen = buf.getInt();
        int network = buf.getInt();

        globalHeader = new GlobalHeader(magic, major, minor, tz, sigfigs, snaplen, network);

        if (globalHeader.getMagicNumber() == 0xD4C3B2A1)
            globalHeader.swapByteOrder();

        return globalHeader;
    }

    public GlobalHeader getGlobalHeader() {
        return globalHeader;
    }

    private PcapPacket readPacket(int magicNumber) throws IOException {
        PacketHeader packetHeader = readPacketHeader(magicNumber);
        Buffer packetData = readPacketData(packetHeader.getInclLen());
        return new PcapPacket(packetHeader, packetData);
    }

    private PacketHeader readPacketHeader(int magicNumber) throws IOException {
        int bytesToRead = 4 + 4 + 4 + 4;
        byte[] buffer = new byte[bytesToRead];
        is.readFully(buffer);
        offset += bytesToRead;
        ByteBuffer buf = ByteBuffer.wrap(buffer);

        int tsSec = buf.getInt();
        int tsUsec = buf.getInt();
        int inclLen = buf.getInt();
        int origLen = buf.getInt();

        if (magicNumber == 0xD4C3B2A1) {
            tsSec = ByteOrderConverter.swap(tsSec);
            tsUsec = ByteOrderConverter.swap(tsUsec);
            inclLen = ByteOrderConverter.swap(inclLen);
            origLen = ByteOrderConverter.swap(origLen);
        }

        return new PacketHeader(tsSec, tsUsec, inclLen, origLen);
    }

    private Buffer readPacketData(int packetLength) throws IOException {
        byte[] packets = new byte[packetLength];
        is.readFully(packets);
        offset += packetLength;

        Buffer payload = new ChainBuffer();
        payload.addLast(packets);
        return payload;
    }

    @Override
    public void close() throws IOException {
        is.close();
    }

    public long getOffset() {
        return offset;
    }

    public long getLength() {
        return length;
    }
}
