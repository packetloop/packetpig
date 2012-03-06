SRCS=$(shell find lib/packetpig/src/main/java/com/packetloop/packetpig -name '*.java')

PIG_JAR=lib/packetpig.jar

all: $(PIG_JAR) spam_deletion

$(PIG_JAR): $(SRCS)
	cd lib/packetpig && mvn compile package && cp target/packetpig-*.jar ../../$(PIG_JAR)

spam_deletion:
	@rm -f pig_*.log

clean:
	rm -rf lib/packetpig/target $(PIG_JAR)

.PHONY: clean all spam_deletion
