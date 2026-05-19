/*
 * Instruction Histogram Plugin
 *
 * Generate instruction histograms for specific instruction intervals.
 * Shows PC, instruction encoding, and execution count.
 * Usage: -plugin insnhist.so,interval=N,start_points=A,B,C
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <qemu-plugin.h>

QEMU_PLUGIN_EXPORT int qemu_plugin_version = QEMU_PLUGIN_VERSION;

static uint64_t interval = 1000000;
static uint64_t *start_points;
static int num_start_points;
static const char *output_prefix = "hist";
static char *dynamic_prefix;

typedef struct {
    uint64_t count;
    uint64_t pc;
    uint32_t insn_opcode;
} InsnInfo;

typedef struct {
    InsnInfo *data;
    int size;
    int capacity;
} InsnInfoArray;

typedef struct {
    uint64_t total_insns;
    InsnInfoArray insn_infos;
    FILE *output_file;
    bool active;
    uint64_t interval_start;
    uint64_t interval_end;
    int current_interval_index;
} VcpuData;

typedef struct {
    uint64_t pc;
    uint32_t insn_opcode;
} InsnExecData;

static struct qemu_plugin_scoreboard *vcpu_data;

static void insn_info_array_init(InsnInfoArray *array)
{
    array->capacity = 100;
    array->size = 0;
    array->data = malloc((size_t)array->capacity * sizeof(InsnInfo));
    if (!array->data) {
        fprintf(stderr, "Failed to allocate memory for instruction info array\n");
        exit(1);
    }
}

static void insn_info_array_expand(InsnInfoArray *array)
{
    int new_capacity = array->capacity * 2;
    InsnInfo *new_data = realloc(array->data, (size_t)new_capacity * sizeof(InsnInfo));
    if (!new_data) {
        fprintf(stderr, "Failed to expand instruction info array\n");
        exit(1);
    }
    array->data = new_data;
    array->capacity = new_capacity;
}

static void insn_info_array_free(InsnInfoArray *array)
{
    free(array->data);
    array->data = NULL;
    array->size = 0;
    array->capacity = 0;
}

static void insn_info_array_reset(InsnInfoArray *array)
{
    array->size = 0;
}

static void vcpu_init(qemu_plugin_id_t id, unsigned int vcpu_index)
{
    (void)id;
    VcpuData *data = qemu_plugin_scoreboard_find(vcpu_data, vcpu_index);
    data->total_insns = 0;
    data->output_file = NULL;
    data->active = false;
    data->interval_start = 0;
    data->interval_end = 0;
    data->current_interval_index = 0;
    insn_info_array_init(&data->insn_infos);
}

static void update_insn_info(VcpuData *data, uint64_t pc, uint32_t insn_opcode)
{
    InsnInfoArray *array = &data->insn_infos;
    for (int i = 0; i < array->size; i++) {
        if (array->data[i].pc == pc && array->data[i].insn_opcode == insn_opcode) {
            array->data[i].count++;
            return;
        }
    }

    if (array->size >= array->capacity) {
        insn_info_array_expand(array);
    }

    array->data[array->size].pc = pc;
    array->data[array->size].insn_opcode = insn_opcode;
    array->data[array->size].count = 1;
    array->size++;
}

static void output_histogram(VcpuData *data, uint64_t start_point, uint64_t end_point)
{
    if (!data->output_file) {
        return;
    }

    InsnInfoArray *array = &data->insn_infos;

    fprintf(data->output_file, "=== Instruction Histogram ===\n");
    fprintf(data->output_file, "Interval: %" PRIu64 " - %" PRIu64 "\n", start_point * interval, end_point * interval);
    fprintf(data->output_file, "Total Instructions: %" PRIu64 "\n", data->total_insns);
    fprintf(data->output_file, "Unique Instructions: %d\n\n", array->size);

    fprintf(data->output_file, "PC\t\tEncoding\tCount\tPercentage\n");
    fprintf(data->output_file, "--------\t--------\t-----\t----------\n");

    for (int i = 0; i < array->size - 1; i++) {
        for (int j = 0; j < array->size - i - 1; j++) {
            if (array->data[j].count < array->data[j + 1].count) {
                InsnInfo temp = array->data[j];
                array->data[j] = array->data[j + 1];
                array->data[j + 1] = temp;
            }
        }
    }

    for (int i = 0; i < array->size; i++) {
        double percentage = (double)array->data[i].count / (double)interval * 100.0;
        fprintf(data->output_file,
                "0x%08" PRIx64 "\t%08" PRIx32 "\t%10" PRIu64 "\t%.2f%%\tDASM(0x%08" PRIx32 ")\n",
                array->data[i].pc, array->data[i].insn_opcode, array->data[i].count, percentage,
                array->data[i].insn_opcode);
    }
    fprintf(data->output_file, "\n");
}

static void start_interval(unsigned int vcpu_index, uint64_t start_point)
{
    VcpuData *data = qemu_plugin_scoreboard_find(vcpu_data, vcpu_index);
    char filename[256];

    const char *prefix = dynamic_prefix ? dynamic_prefix : output_prefix;
    snprintf(filename, sizeof(filename), "%s_%" PRIu64 ".log", prefix, start_point);
    data->output_file = fopen(filename, "w");

    if (data->output_file) {
        fprintf(data->output_file, "Starting instruction histogram collection\n");
        fprintf(data->output_file, "Start point: %" PRIu64 "\n", start_point * interval);
        fprintf(data->output_file, "Interval size: %" PRIu64 "\n\n", interval);
        data->active = true;
        data->interval_start = start_point * interval;
        data->interval_end = (start_point + 1) * interval - 1;
    }

    fprintf(stderr, "start_interval: %" PRIu64 " %s\n", start_point, filename);
}

static void end_interval(unsigned int vcpu_index, uint64_t start_point)
{
    VcpuData *data = qemu_plugin_scoreboard_find(vcpu_data, vcpu_index);
    if (data->active && data->output_file) {
        uint64_t end_point = start_point + 1;
        output_histogram(data, start_point, end_point);
        fprintf(data->output_file, "=== End of Interval ===\n");
        fclose(data->output_file);
        data->output_file = NULL;
        data->active = false;
        insn_info_array_reset(&data->insn_infos);
    }
}

static void vcpu_insn_exec(unsigned int vcpu_index, void *udata)
{
    VcpuData *data = qemu_plugin_scoreboard_find(vcpu_data, vcpu_index);
    data->total_insns++;

    if (!data->active) {
        while (data->current_interval_index < num_start_points) {
            uint64_t sp = start_points[data->current_interval_index];
            uint64_t interval_start = sp * interval;
            uint64_t interval_end = (sp + 1) * interval - 1;
            if (data->total_insns >= interval_start && data->total_insns <= interval_end) {
                start_interval(vcpu_index, sp);
                break;
            } else if (data->total_insns > interval_end) {
                data->current_interval_index++;
            } else {
                break;
            }
        }
    }

    if (!data->active) {
        return;
    }

    InsnExecData *exec_data = (InsnExecData *)udata;
    update_insn_info(data, exec_data->pc, exec_data->insn_opcode);

    if (data->total_insns > data->interval_end) {
        uint64_t current_start = data->interval_start / interval;
        end_interval(vcpu_index, current_start);
        data->current_interval_index++;
        if (data->current_interval_index < num_start_points) {
            uint64_t next_sp = start_points[data->current_interval_index];
            uint64_t next_start = next_sp * interval;
            uint64_t next_end = (next_sp + 1) * interval - 1;
            if (data->total_insns >= next_start && data->total_insns <= next_end) {
                start_interval(vcpu_index, next_sp);
            }
        }
    }
}

static void vcpu_tb_trans(qemu_plugin_id_t id, struct qemu_plugin_tb *tb)
{
    (void)id;
    uint64_t n_insns = qemu_plugin_tb_n_insns(tb);
    for (uint64_t i = 0; i < n_insns; i++) {
        struct qemu_plugin_insn *insn = qemu_plugin_tb_get_insn(tb, i);
        uint64_t pc = qemu_plugin_insn_vaddr(insn);

        uint32_t insn_opcode = 0;
        qemu_plugin_insn_data(insn, &insn_opcode, sizeof(insn_opcode));

        InsnExecData *exec_data = malloc(sizeof(InsnExecData));
        exec_data->pc = pc;
        exec_data->insn_opcode = insn_opcode;

        qemu_plugin_register_vcpu_insn_exec_cb(insn, vcpu_insn_exec, QEMU_PLUGIN_CB_NO_REGS, exec_data);
    }
}

static void plugin_exit(qemu_plugin_id_t id, void *p)
{
    (void)id;
    (void)p;

    for (int i = 0; i < qemu_plugin_num_vcpus(); i++) {
        VcpuData *data = qemu_plugin_scoreboard_find(vcpu_data, i);
        if (data->active && data->output_file) {
            fclose(data->output_file);
        }
        insn_info_array_free(&data->insn_infos);
    }

    free(start_points);
    free(dynamic_prefix);
    qemu_plugin_scoreboard_free(vcpu_data);
}

QEMU_PLUGIN_EXPORT int qemu_plugin_install(qemu_plugin_id_t id, const qemu_info_t *info, int argc, char **argv)
{
    (void)info;

    start_points = malloc(100 * sizeof(uint64_t));
    num_start_points = 0;

    for (int i = 0; i < argc; i++) {
        char *opt = argv[i];
        if (strncmp(opt, "interval=", 9) == 0) {
            interval = strtoull(opt + 9, NULL, 10);
        } else if (strncmp(opt, "start_points=", 13) == 0) {
            char *value_copy = strdup(opt + 13);
            char *token = strtok(value_copy, "/");
            while (token && num_start_points < 100) {
                start_points[num_start_points++] = strtoull(token, NULL, 10);
                token = strtok(NULL, "/");
            }
            free(value_copy);
        } else if (strncmp(opt, "prefix=", 7) == 0) {
            free(dynamic_prefix);
            dynamic_prefix = strdup(opt + 7);
        } else {
            fprintf(stderr, "Unknown option: %s\n", opt);
            return -1;
        }
    }

    if (num_start_points == 0) {
        fprintf(stderr, "No start points specified. Use start_points=A,B,C\n");
        return -1;
    }
    if (interval == 0) {
        fprintf(stderr, "Invalid interval size\n");
        return -1;
    }

    for (int i = 0; i < num_start_points - 1; i++) {
        for (int j = 0; j < num_start_points - i - 1; j++) {
            if (start_points[j] > start_points[j + 1]) {
                uint64_t tmp = start_points[j];
                start_points[j] = start_points[j + 1];
                start_points[j + 1] = tmp;
            }
        }
    }

    fprintf(stderr, "Instruction Histogram Plugin:\n");
    fprintf(stderr, "  Interval size: %" PRIu64 "\n", interval);
    fprintf(stderr, "  Start points: ");
    for (int i = 0; i < num_start_points; i++) {
        fprintf(stderr, "%" PRIu64 "%s", start_points[i], (i + 1 < num_start_points) ? ", " : "");
    }
    fprintf(stderr, "\n");
    fprintf(stderr, "  Output prefix: %s\n", dynamic_prefix ? dynamic_prefix : output_prefix);

    vcpu_data = qemu_plugin_scoreboard_new(sizeof(VcpuData));
    qemu_plugin_register_atexit_cb(id, plugin_exit, NULL);
    qemu_plugin_register_vcpu_init_cb(id, vcpu_init);
    qemu_plugin_register_vcpu_tb_trans_cb(id, vcpu_tb_trans);
    return 0;
}

