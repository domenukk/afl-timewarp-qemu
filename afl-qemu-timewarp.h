//
// Created by domenukk on 3/14/18.
//

#ifndef FUZZWARP_TIMEWARP_QEMU_H
#define FUZZWARP_TIMEWARP_QEMU_H

/* The stage we're in right now
 * 0 deactivated
 * 1 -> stdio
 * 2 -> timewarp
 * 3 -> fuzz
 * 99 -> I'm the child.
 */

typedef enum _timewarp_stages {
  TW_DEACTIVATED = 0,
  TW_STDIO = 1,
  TW_TIMEWARP = 2,
  TW_FUZZ = 3,
  TW_CHILD = 99
} timewarp_stage;

/* Hijack a signal for AF1. Targets using SIGUSR2 are not supported right now. */
#define TW_SIGNAL TARGET_SIGUSR2

extern timewarp_stage tw_stage;
extern char tw_in_syscall;
// TODO: Where is target_ulong defined?
extern unsigned long long tw_pos;
extern char tw_exec;

//TODO: Enter stuff here :)


#endif //FUZZWARP_TIMEWARP_QEMU_H
