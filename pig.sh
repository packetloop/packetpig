#!/bin/bash

if [ "$PREFIX" = "" ]; then
	prefix=packetpig
else
	prefix=$PREFIX
fi

SCP=$(which scp)

abs_path()
{
	perl -MCwd -e "print Cwd::abs_path('$1');"
}

hdfs()
{
	file=file://$(abs_path $1)
	dest=hdfs://$HDFS_MASTER/$prefix/$(basename $1)

	echo $file -\> $dest

	cmd="hadoop fs -cp $file $dest"
	$($cmd 2>/dev/null)

	if [ $? -ne 0 ]; then
		echo "error: $cmd"
	fi
}

