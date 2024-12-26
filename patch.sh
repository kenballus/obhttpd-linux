#!/bin/bash

set -euo pipefail

[[ -v OPENBSD_SRC_VERSION ]] || OPENBSD_SRC_VERSION='76b1f2ebe5106c591f5eafcb9d7b05643509a2c4'

[[ -v OPENBSD_SRC_BRANCH ]] || OPENBSD_SRC_BRANCH='master'

[[ -v OPENBSD_SRC_REPO ]] || OPENBSD_SRC_REPO='https://github.com/openbsd/src'

# All .c files except compat.c
C_SRC="control.c server_fcgi.c httpd.c imsg-buffer.c log.c proc.c server_file.c config.c imsg.c logger.c patterns.c server.c server_http.c fmt_scaled.c timingsafe_bcmp.c blowfish.c bcrypt.c"

# All .h files except compat.h
H_SRC="http.h imsg.h patterns.h httpd.h util.h blf.h"

C_AND_H_SRC="$C_SRC $H_SRC"

# All src files except compat.c and compat.h
ALL_SRC="$C_AND_H_SRC parse.y"

rm -f $ALL_SRC

[ -d src ] || git clone "$OPENBSD_SRC_REPO"

pushd src
echo "source branch: $OPENBSD_SRC_BRANCH"
echo "source version: $OPENBSD_SRC_VERSION"
git pull origin "$OPENBSD_SRC_BRANCH"
git checkout "$OPENBSD_SRC_VERSION"
popd

cp src/usr.sbin/httpd/* .
cp src/lib/libutil/imsg-buffer.c src/lib/libutil/imsg.c src/lib/libutil/imsg.h .
cp src/lib/libutil/fmt_scaled.c src/lib/libutil/util.h .
cp src/lib/libc/string/timingsafe_bcmp.c .
cp ./src/lib/libc/crypt/blowfish.c .
cp src/lib/libc/crypt/bcrypt.c .
cp src/include/blf.h .

# Use libbsd tree.h (not provided on Linux)
sed -i 's/#include <sys\/tree.h>/#include <bsd\/sys\/tree.h>/' $ALL_SRC

# Use libbsd vis.h (not provided on Linux)
sed -i 's/#include <vis.h>/#include <bsd\/vis.h>/' $ALL_SRC

# Use libbsd queue.h (for TAILQ_FOREACH_SAFE, which isn't provided on Linux)
sed -i 's/#include <sys\/queue.h>/#include <bsd\/sys\/queue.h>/' $ALL_SRC

# Patch out references to sys/sockio.h
sed -i 's/\(#include <sys\/sockio.h>\)/\/\/ \1/' parse.y

# Include stdlib.h in parse.y
sed -i 's/%{/%{\n#define _GNU_SOURCE\n#include <bsd\/stdlib.h>/' parse.y

# Get rid of references to sockaddr len fields
sed -i 's/\(.*->sin6_len =.*;\)/\/\/ \1/' $ALL_SRC
sed -i 's/\(.*->sin_len =.*;\)/\/\/ \1/' $ALL_SRC
sed -i 's/\(.*->sun_len =.*;\)/\/\/ \1/' $ALL_SRC
sed -i 's/\(.*->ss_len =.*;\)/\/\/ \1/' $ALL_SRC
sed -i 's/\(.*\.ss_len =[^;]*$\)/\/\/ \1 \\/' $ALL_SRC
sed -i 's/\(.*->sin_len =[^;]*$\)/\/\/ \1 \\/' $ALL_SRC
sed -i 's/\(.*->sin6_len =[^;]*$\)/\/\/ \1 \\/' $ALL_SRC
sed -i 's/\([^ ]*\)->ss_len/sizeof(*(\1))/' $ALL_SRC
sed -i 's/\([^ ]*\)\.ss_len/sizeof(\1)/' $ALL_SRC

# Patch out is_if_in_group, since ifgroups don't exist on Linux
sed -i 's/\(is_if_in_group(const char \*ifname, const char \*groupname)\)/\1 {\n    return 0;\n}\nstatic int unused(const char *ifname, const char *groupname)/' parse.y

# Add compat.h to everything
sed -i '1i #include "compat.h"' $C_AND_H_SRC
sed -i 's/\(#include "http.h"\)/\1\n#include "compat.h"/' parse.y

# Use libbsd stdlib.h where necessary
sed -i 's/#include <stdlib.h>/#include <bsd\/stdlib.h>/' httpd.c server.c server_http.c server_file.c server_fcgi.c imsg-buffer.c

# Use libbsd unistd.h where necessary
sed -i 's/#include <unistd.h>/#include <bsd\/unistd.h>/' proc.c httpd.c

# Include grp.h in proc.c (for setgroups)
sed -i 's/\(#include <imsg.h>\)/\1\n#include <grp.h>/' proc.c

# Patch around bufferevent_add taking struct timeval on OpenBSD
sed -i 's/\(.server_bufferevent_add(.*\))/\1.tv_sec)/' $C_SRC

# Patch around unimplemented TCP flags
sed -i 's/\(if (srv_conf->tcpflags & (TCPFLAG_SACK|TCPFLAG_NSACK)) {\)/\1\n\t\tfatal("Linux does not support these TCP flags.");/' server.c

# Use libbsd sys/time.h (for timespeccmp)
sed -i 's/#include <sys\/time.h>/#include <bsd\/sys\/time.h>/' server_file.c

# Add libbsd and libresolv to the Makefile
sed -i 's/\(LDADD=.*\)/\1\nLDADD+=\t\t-lbsd -lresolv/' Makefile

# Add the new source files to the Makefile
sed -i 's/\(SRCS=.*\)/\1\nSRCS+=\t\tcompat.c imsg.c imsg-buffer.c fmt_scaled.c timingsafe_bcmp.c blowfish.c bcrypt.c/' Makefile

# Silence some warnings in the Makefile
sed -i 's/\(CFLAGS+=[ \t]*-Wsign-compare -Wcast-qual\)/\1 -Wno-format -Wno-cpp -Wno-comment/' Makefile

# Remove declaration that conflicts with libbsd
sed -i 's/\(char *\*fparseln.*\)/\/\/ \1/' util.h

# Fix UB caused by invalid lshift
sed -i 's/1 << (i - 1)/1u << (i - 1)/' httpd.c

# Add envp to main for use in setproctitle_init
sed -i 's/main(int argc, char \*argv\[\])/main(int argc, char *argv[], char *envp[])/' httpd.c

# Use setproctitle_init
sed -i 's/\(int[ \t]*argc0 = argc;\)/\1\n\n\tsetproctitle_init(argc, argv, envp);/' httpd.c

# Increase MAX_IMSG_SIZE
sed -i 's/#define MAX_IMSGSIZE[ \t].*/#define MAX_IMSGSIZE 32768/' imsg.h

# Patch around differences between OpenBSD's event_del and upstream libevent's
sed -i 's/event_del(\&clt->clt_ev);/if (clt->clt_ev.ev_base != NULL) event_del(\&clt->clt_ev);/' server.c
