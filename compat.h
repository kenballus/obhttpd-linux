#pragma once

#include <event.h>
#include <net/if.h>
#include <glob.h>
#include <stdlib.h>
#include <unistd.h>

#define __dead __attribute__((noreturn))

int getdtablecount(void);

int bufferevent_add(struct event *ev, int timeout);

void bufferevent_read_pressure_cb(struct evbuffer *buf, size_t old, size_t now, void *arg);

int crypt_checkpass(const char *, const char *);

#define pledge(...) (0)

// This is an unsupported TCP flag on Linux.
// We fatal when the user asks for this flag,
// but we still need it to be defined
#define TCP_SACK_ENABLE (-1)

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
