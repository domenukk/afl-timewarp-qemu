#!/bin/sh
#
# american fuzzy lop - QEMU build script
# --------------------------------------
#
# Written by Andrew Griffiths <agriffiths@google.com> and
#            Michal Zalewski <lcamtuf@google.com>
#
# Copyright 2015, 2016, 2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# This script downloads, patches, and builds a version of QEMU with
# minor tweaks to allow non-instrumented binaries to be run under
# afl-fuzz. 
#
# The modifications reside in patches/*. The standalone QEMU binary
# will be written to ../afl-qemu-trace.
#

echo "[*] Performing basic sanity checks..."

if [ ! "`uname -s`" = "Linux" ]; then

  echo "[-] Error: QEMU instrumentation is supported only on Linux."
  exit 1

fi

if [ ! -f "../config.h" ]; then

  echo "[-] Error: Can only compile as afl subdir"
  exit 1

fi

if [ ! -f "../afl-showmap" ]; then

  echo "[-] Error: ../afl-showmap not found - compile AFL first!"
  exit 1

fi


for i in libtool wget python automake autoconf sha384sum bison iconv; do

  T=`which "$i" 2>/dev/null`

  if [ "$T" = "" ]; then

    echo "[-] Error: '$i' not found, please install first."
    exit 1

  fi

done

if [ ! -d "/usr/include/glib-2.0/" -a ! -d "/usr/local/include/glib-2.0/" ]; then

  echo "[-] Error: devel version of 'glib2' not found, please install first."
  exit 1

fi

if echo "$CC" | grep -qF /afl-; then

  echo "[-] Error: do not use afl-gcc or afl-clang to compile this tool."
  exit 1

fi

echo "[+] All checks passed!"
echo "[*] Configuring QEMU for $CPU_TARGET..."

ORIG_CPU_TARGET="$CPU_TARGET"

test "$CPU_TARGET" = "" && CPU_TARGET="`uname -m`"
test "$CPU_TARGET" = "i686" && CPU_TARGET="i386"

cd qemu-$VERSION || exit 1

# --enable-pie seems to give a couple of exec's a second performance
# improvement, much to my surprise. Not sure how universal this is..

CFLAGS="-O3 -ggdb" ./configure --disable-system \
  --enable-linux-user --disable-gtk --disable-sdl --disable-vnc \
  --target-list="${CPU_TARGET}-linux-user" --python=$(which python2) --enable-pie --enable-kvm || exit 1

echo "[+] Configuration complete."

echo "[*] Attempting to build QEMU (fingers crossed!)..."

make || exit 1

echo "[+] Build process successful!"

echo "[*] Copying binary..."

#cp -f "${CPU_TARGET}-linux-user/qemu-${CPU_TARGET}" "../../afl-qemu-trace" || exit 1

cd ..
ls -l ../afl-qemu-trace || exit 1

echo "[+] Successfully created '../afl-qemu-trace'."

if [ "$ORIG_CPU_TARGET" = "" ]; then

  echo "[*] Testing the build..."

  cd ..

  make >/dev/null || exit 1

  gcc test-instr.c -o test-instr || exit 1

  unset AFL_INST_RATIO

  echo 0 | ./afl-showmap -m none -Q -q -o .test-instr0 ./test-instr || exit 1
  echo 1 | ./afl-showmap -m none -Q -q -o .test-instr1 ./test-instr || exit 1

  rm -f test-instr

  cmp -s .test-instr0 .test-instr1
  DR="$?"

  rm -f .test-instr0 .test-instr1

  if [ "$DR" = "0" ]; then

    echo "[-] Error: afl-qemu-trace instrumentation doesn't seem to work!"
    exit 1

  fi

  echo "[+] Instrumentation tests passed. "
  echo "[+] All set, you can now use the -Q mode in afl-fuzz!"

else

  echo "[!] Note: can't test instrumentation when CPU_TARGET set."
  echo "[+] All set, you can now (hopefully) use the -Q mode in afl-fuzz!"

fi

exit 0
