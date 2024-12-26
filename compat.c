#include <stdio.h>  // for snprintf
#include <glob.h>   // for glob
#include <unistd.h> // for getpid
#include <stdlib.h> // for exit
#include <limits.h> // for PATH_MAX
#include <string.h> // for strlen

#include "compat.h"

static void fatal(const char *emsg) {
    printf("%s", emsg);
    exit(1);
}

// Pulled from tmux's compat/getdtablecount.c
int getdtablecount(void) {
    char path[PATH_MAX];
    glob_t g;
    int n = 0;

    if (snprintf(path, sizeof(path), "/proc/%ld/fd/*", (long)getpid()) < 0) {
        fatal("snprintf overflow");
    }
    if (glob(path, 0, NULL, &g) == 0) {
        n = g.gl_pathc;
    }
    globfree(&g);
    return n;
}

// Pulled from src/lib/libevent/evbuffer.c
int bufferevent_add(struct event *ev, int timeout) {
    struct timeval tv, *ptv = NULL;

    if (timeout) {
        timerclear(&tv);
        tv.tv_sec = timeout;
        ptv = &tv;
    }

    return (event_add(ev, ptv));
}

// Pulled from src/lib/libevent/evbuffer.c
void bufferevent_read_pressure_cb(struct evbuffer *buf, size_t old, size_t now, void *arg) {
    struct bufferevent *bufev = arg;
    /*
     * If we are below the watermark then reschedule reading if it's
     * still enabled.
     */
    if (bufev->wm_read.high == 0 || now < bufev->wm_read.high) {
        evbuffer_setcb(buf, NULL, NULL);

        if (bufev->enabled & EV_READ)
            bufferevent_add(&bufev->ev_read, bufev->timeout_read.tv_sec);
    }
}

// Pulled from src/lib/libc/crypt/cryptutil.c
int crypt_checkpass(const char *pass, const char *goodhash) {
    char dummy[_PASSWORD_LEN];

    if (goodhash == NULL) {
        /* fake it */
        goto fake;
    }

    /* empty password */
    if (strlen(goodhash) == 0 && strlen(pass) == 0)
        return 0;

    if (goodhash[0] == '$' && goodhash[1] == '2') {
        if (bcrypt_checkpass(pass, goodhash))
            goto fail;
        return 0;
    }

    /* unsupported. fake it. */
fake:
    bcrypt_newhash(pass, 8, dummy, sizeof(dummy));
fail:
    errno = EACCES;
    return -1;
}
