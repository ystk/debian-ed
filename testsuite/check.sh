#! /bin/sh
# check script for GNU ed - The GNU line editor
# Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014
# Free Software Foundation, Inc.
#
# This script is free software; you have unlimited permission
# to copy, distribute and modify it.

LC_ALL=C
export LC_ALL
objdir=`pwd`
testdir=`cd "$1" ; pwd`
ED="${objdir}"/ed

if [ ! -x "${ED}" ] ; then
	echo "${ED}: cannot execute"
	exit 1
fi

if [ -d tmp ] ; then rm -rf tmp ; fi
mkdir tmp

# Generate ed test scripts, with extensions .ed and .red, from
# .t and .err files, respectively.
printf "building test scripts for ed-%s...\n" "$2"
cd "${testdir}"

for i in *.t ; do
	base=`echo "$i" | sed 's/\.t$//'`
	(
	echo H
	echo "r ${testdir}/${base}.d"
	cat "$i"
	echo "w ${base}.o"
	) > "${objdir}/tmp/${base}.ed"
done

for i in *.err ; do
	base=`echo "$i" | sed 's/\.err$//'`
	(
	echo H
	echo "r ${testdir}/${base}.err"
	cat "$i"
	echo "w ${base}.ro"
	) > "${objdir}/tmp/${base}.red"
done


cd "${objdir}"/tmp
fail=0

printf "testing ed-%s...\n" "$2"

# Run the .ed and .red scripts just generated
# and compare their output against the .r and .pr files, which contain
# the correct output.

# Run the *.red scripts first, since these don't generate output;
# they exit with non-zero status
for i in *.red ; do
	if "${ED}" -s < "$i" > /dev/null 2>&1 ; then
		echo "*** The script $i exited abnormally ***"
		fail=127
	fi
done

# Run error scripts again as pipes - these should generate output and
# exit with error (>0) status.
for i in *.red ; do
	base=`echo "$i" | sed 's/\.red$//'`
	if cat ${base}.red | "${ED}" -s > /dev/null 2>&1 ; then
		echo "*** The piped script $i exited abnormally ***"
		fail=127
	else
		if cmp -s ${base}.ro "${testdir}"/${base}.pr ; then
			true
		else
			echo "*** Output ${base}.ro of piped script $i is incorrect ***"
			fail=127
		fi
	fi
done

# Run the remaining scripts; they exit with zero status
for i in *.ed ; do
	base=`echo "$i" | sed 's/\.ed$//'`
	if "${ED}" -s < ${base}.ed > /dev/null 2>&1 ; then
		if cmp -s ${base}.o "${testdir}"/${base}.r ; then
			true
		else
			echo "*** Output ${base}.o of script $i is incorrect ***"
			fail=127
		fi
	else
		echo "*** The script $i exited abnormally ***"
		fail=127
	fi
done

if [ ${fail} = 0 ] ; then
	echo "tests completed successfully."
	cd "${objdir}" && rm -r tmp
else
	echo "tests failed."
fi
exit ${fail}
