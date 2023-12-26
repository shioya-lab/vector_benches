# -*- coding: utf-8 -*-

import sys
import os
import sqlite3
import xml_parser
import re

def generate_sniper_output_xml(src_file, dst_file):

    if not os.path.exists(src_file):
        raise Exception("File not found: '%s'" % src_file)

    cursor = sqlite3.connect(src_file)

    # nameid から名前を得るマップを作成
    # names テーブルの各行は (nameid, objectname, metricname) となっている
    # nameid -> {objectname, metricname} に
    names = cursor.execute("SELECT * FROM 'names'").fetchall()
    name_map = {}
    for n in names:
        if n[0] in name_map:
            raise Error("nameid '%d' exists in the name map" % n[0])
        objectname = n[1]
        metricname = n[2]

        metricname = re.sub(r"\[(\d+)\]", r"-\1", metricname)

        name_map[n[0]] = {
            "objectname": objectname,
            "metricname": metricname
        }

    # prefixid から名前を得るマップを作成
    prefixes = cursor.execute("SELECT * FROM 'prefixes'").fetchall()
    prefix_map = {}
    for p in prefixes:
        if p[0] in prefix_map:
            raise Error("prefixid '%d' exists in the prefix map" % p[0])
        prefix_map[p[0]] = {
            "prefixname": p[1]
        }

    # values テーブルを XML 用のツリーに変換
    # 各行は (prefixid, nameid, core, value)
    values = cursor.execute("SELECT * FROM 'values'").fetchall()
    value_map = {}
    for v in values:
        if v[0] not in prefix_map:
            raise Error("prefixid '%d' is not found in the prefix map" % v[0])

        if v[1] not in name_map:
            raise Error("nameid %d is not found in the name map" % v[1])

        name = name_map[v[1]]
        objectname = name["objectname"]
        metricname = name["metricname"]
        corename = "core-%d" % v[2]
        prefixname = "@" + prefix_map[v[0]]["prefixname"]

        value = v[3]
        if corename not in value_map:
            value_map[corename] = {}
        if objectname not in value_map[corename]:
            value_map[corename][objectname] = {}
        if metricname not in value_map[corename][objectname]:
            value_map[corename][objectname][metricname] = {}

        if prefixname in value_map[corename][objectname][metricname]:
            raise Error("prefix '%s' in name '%s' exists in the value map" % (prefixname, name))

        value_map[corename][objectname][metricname][prefixname] = str(value)

    for core in value_map.values():
        for obj in core.values():
            for metric in obj.values():
                if "@roi-end" not in metric:
                    continue
                if "@roi-begin" in metric:
                    metric["@roi-length"] = str(int(metric["@roi-end"]) - int(metric["@roi-begin"]))
                else:
                    metric["@roi-length"] = str(int(metric["@roi-end"]) - 0)

    tree = {
        "stats": value_map
    }
    xml_parser.save_file(dst_file, tree)



def main ():
    if len(sys.argv) != 2:
        exit_on_error("Invalid input. Usage: python3 dump_sqlite3.py <path_to_sim_stats_sqlite3>")

    stats_sqlite_file = sys.argv[1]
    base_stats_path = os.path.splitext(stats_sqlite_file)[0]
    stats_xml_file = base_stats_path + ".xml"

    print("generate_sniper_output_xml ...\t", end="")
    generate_sniper_output_xml(stats_sqlite_file, stats_xml_file)
    print("[OK]")

main()
