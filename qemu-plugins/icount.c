/*
 * RISC-V Instruction Monitor Plugin
 *
 * Monitors specific RISC-V instructions (0x00100013, 0x00200013)
 * Reports position of target instructions in overall instruction sequence
 * Usage: -plugin icount.so
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <qemu-plugin.h>

QEMU_PLUGIN_EXPORT int qemu_plugin_version = QEMU_PLUGIN_VERSION;

static uint64_t interval = 1000000; /* default interval size */

#define TARGET_INSN_1 0x00100013 /* addi x0, x0, 1 */
#define TARGET_INSN_2 0x00200013 /* addi x0, x0, 2 */

typedef struct {
    uint64_t total_insn_count;
    uint64_t target_insn_count;
} VcpuData;

static struct qemu_plugin_scoreboard *vcpu_data;

static void vcpu_init(qemu_plugin_id_t id, unsigned int vcpu_index)
{
    VcpuData *data = qemu_plugin_scoreboard_find(vcpu_data, vcpu_index);
    data->total_insn_count = 0;
    data->target_insn_count = 0;
}

static void count_instruction(unsigned int vcpu_index, void *udata)
{
    (void)udata;
    VcpuData *data = qemu_plugin_scoreboard_find(vcpu_data, vcpu_index);
    data->total_insn_count++;
}

static void check_target_instruction(unsigned int vcpu_index, void *udata)
{
    VcpuData *data = qemu_plugin_scoreboard_find(vcpu_data, vcpu_index);
    uint32_t insn_encoding = (uint32_t)(uintptr_t)udata;

    data->total_insn_count++;
    data->target_insn_count++;

    if (insn_encoding == TARGET_INSN_1) {
        fprintf(stderr,
                "\nVCPU %u: Target instruction 0x%08x (addi x0, x0, 1) detected at instruction count: %" PRIu64
                "\n",
                vcpu_index, insn_encoding, data->total_insn_count);
    } else if (insn_encoding == TARGET_INSN_2) {
        fprintf(stderr,
                "\nVCPU %u: Target instruction 0x%08x (addi x0, x0, 2) detected at instruction count: %" PRIu64
                "\n",
                vcpu_index, insn_encoding, data->total_insn_count);
    }
}

static void vcpu_tb_trans(qemu_plugin_id_t id, struct qemu_plugin_tb *tb)
{
    (void)id;
    uint64_t n_insns = qemu_plugin_tb_n_insns(tb);

    for (size_t i = 0; i < n_insns; i++) {
        struct qemu_plugin_insn *insn = qemu_plugin_tb_get_insn(tb, i);
        if (!insn) {
            continue;
        }

        uint32_t insn_data;
        qemu_plugin_insn_data(insn, &insn_data, sizeof(insn_data));
        size_t insn_size = qemu_plugin_insn_size(insn);

        if (insn_size == 0) {
            continue;
        }

        uint32_t insn_encoding = insn_data;

        if (insn_encoding == TARGET_INSN_1 || insn_encoding == TARGET_INSN_2) {
            void *encoding_ptr = (void *)(uintptr_t)insn_encoding;
            qemu_plugin_register_vcpu_insn_exec_cb(insn, check_target_instruction, QEMU_PLUGIN_CB_NO_REGS,
                                                  encoding_ptr);
        } else {
            qemu_plugin_register_vcpu_insn_exec_cb(insn, count_instruction, QEMU_PLUGIN_CB_NO_REGS, NULL);
        }
    }
}

static void plugin_exit(qemu_plugin_id_t id, void *p)
{
    (void)id;
    (void)p;

    for (int i = 0; i < qemu_plugin_num_vcpus(); i++) {
        VcpuData *data = qemu_plugin_scoreboard_find(vcpu_data, i);
        fprintf(stderr, "VCPU %d: Total instructions executed: %" PRIu64 "\n", i, data->total_insn_count);
        fprintf(stderr, "VCPU %d: Target instructions executed: %" PRIu64 "\n", i, data->target_insn_count);
    }

    qemu_plugin_scoreboard_free(vcpu_data);
}

QEMU_PLUGIN_EXPORT int qemu_plugin_install(qemu_plugin_id_t id, const qemu_info_t *info, int argc, char **argv)
{
    (void)info;

    for (int i = 0; i < argc; i++) {
        char *opt = argv[i];

        if (strncmp(opt, "interval=", 9) == 0) {
            interval = strtoull(opt + 9, NULL, 10);
        } else {
            fprintf(stderr, "Unknown option: %s\n", opt);
            return -1;
        }
    }

    if (interval == 0) {
        fprintf(stderr, "Invalid interval size\n");
        return -1;
    }

    fprintf(stderr, "RISC-V Instruction Monitor Plugin:\n");
    fprintf(stderr, "  Monitoring RISC-V instructions: 0x%08x, 0x%08x\n", TARGET_INSN_1, TARGET_INSN_2);
    fprintf(stderr, "  Tracking total instruction count for position reporting\n");

    vcpu_data = qemu_plugin_scoreboard_new(sizeof(VcpuData));

    qemu_plugin_register_atexit_cb(id, plugin_exit, NULL);
    qemu_plugin_register_vcpu_init_cb(id, vcpu_init);
    qemu_plugin_register_vcpu_tb_trans_cb(id, vcpu_tb_trans);

    return 0;
}

