#pragma once

// Won't build on Arch without this due to lack of IOV_MAX
#define _GNU_SOURCE

#include <event.h>  // for struct event
#include <net/if.h> // for IF_NAMESIZE

// This is just a noreturn macro that OpenBSD
// uses that doesn't exist elsewhere
#define __dead __attribute__((noreturn))

// This is a declaration macro that we don't need
// because this is not a library
#define DEF_WEAK(...)

// We patch out calls to pledge because it's
// not a thing on Linux
#define pledge(...) (0)

// libc has a bunch of wrapper names for internal use
// we patch them out
#define	WRAP(x)			(x)

// This is an unsupported TCP flag on Linux.
// We fatal when the user asks for this flag,
// but we still need it to be defined
#define TCP_SACK_ENABLE (-1)

// Pulled from src/include/limits.h
#define	_PASSWORD_LEN		128	/* max length, not counting NUL */

int getdtablecount(void);
int bufferevent_add(struct event *ev, int timeout);
void bufferevent_read_pressure_cb(struct evbuffer *buf, size_t old, size_t now, void *arg);
int crypt_checkpass(const char *pass, const char *goodhash);
int timingsafe_bcmp(const void *b1, const void *b2, size_t n);
int bcrypt_checkpass(const char *pass, const char *goodhash);
int bcrypt_newhash(const char *pass, int log_rounds, char *hash, size_t hashlen);

// This IFGROUP stuff is here to silence a compiler
// error that only affects dead code.
// In other words, none of the below code needs to work,
// it just needs to compile.
// All of this was copied from sys/net/if.h
#define SIOCGIFGROUP (-1)
#define IFNAMSIZ IF_NAMESIZE
struct ifg_req {
    union {
        char             ifgrqu_group[IFNAMSIZ];
        char             ifgrqu_member[IFNAMSIZ];
    } ifgrq_ifgrqu;
#define ifgrq_group ifgrq_ifgrqu.ifgrqu_group
#define ifgrq_member    ifgrq_ifgrqu.ifgrqu_member
};
struct ifg_attrib {
    int ifg_carp_demoted;
};
struct ifgroupreq {
    char    ifgr_name[IFNAMSIZ];
    u_int   ifgr_len;
    union {
        char             ifgru_group[IFNAMSIZ];
        struct  ifg_req     *ifgru_groups;
        struct  ifg_attrib   ifgru_attrib;
    } ifgr_ifgru;
#define ifgr_group  ifgr_ifgru.ifgru_group
#define ifgr_groups ifgr_ifgru.ifgru_groups
#define ifgr_attrib ifgr_ifgru.ifgru_attrib
};
