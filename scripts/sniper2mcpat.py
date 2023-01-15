#!/usr/bin/python3

# -*- coding: utf-8 -*-

import sys
import os
import sqlite3
import re
import subprocess

import xml_parser
from mcpat_input_xml import McPAT_InputXML
from config import Config
from sniper_result_xml import SniperResultXML
from mcpat_output_parser import McPAT_OutputParser
from matrix import Matrix


class Error(Exception):
    """ An exeception class """
    pass

def exit_on_error(err):
    print(err)
    sys.exit(1)

def setup_mcpat(sniper_output_xml, mcpat_template, mcpat_output_xml, config):
    mcpat_input_xml = McPAT_InputXML(
        sniper_output_xml, mcpat_template, config
    )
    mcpat_input_xml.Save(mcpat_output_xml)


def run_mcpat(config, mcpat_input_xml, mcpat_output_raw):

    # Run a McPAT process.
    command = [
        config.mcpatBinaryPath,
        "-infile",
        mcpat_input_xml,

    ] + config.commandlineOption    # commandlineOption is a list
    #print(command)

    process = subprocess.Popen(
        command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
    )

    # Extract result strings.
    result = ""
    for line in iter(process.stdout.readline, b''):
        strLine = str(line.decode("utf8"))
        #print(strLine)
        result += strLine
    process.wait()

    file = open(mcpat_output_raw, mode="w")
    file.write(result)
    file.close()

def parse_mcpat_result(config, mcpat_output_raw, mcpat_output_csv):
    mcpatOutputParser = McPAT_OutputParser()
    parsed = mcpatOutputParser.ParseFile(mcpat_output_raw)

    # Raw results from a parser are flatten to a "module-attribute: value" form.
    indexMap = {}
    result = {}
    for moduleName, module in parsed.items():
        for valueName, value in module.items():
            key = "%s-%s" % (moduleName, valueName)
            result[key] = value
            if not key in indexMap:
                indexMap[key] = len(indexMap)

    # Output a csv file.
    sessionResult = {mcpat_output_raw: result}
    colHeaders = sorted(indexMap.keys())
    rowHeaders = [mcpat_output_raw] #sorted(sessionResult.keys())
    csv = Matrix()
    csv.set_col_header(colHeaders)
    csv.set_row_header(rowHeaders)

    for row, rowValue in enumerate(rowHeaders):
        for col, colValue in enumerate(colHeaders):
            if (rowValue in sessionResult) and (colValue in sessionResult[rowValue]):
                value = sessionResult[rowValue][colValue]
                csv.put(row, col, value)
    csv.write(mcpat_output_csv)


def generate_sniper_output_xml(src_file, dst_file):

    if not os.path.exists(src_file):
        raise Error("File not found: '%s'" % src_file)

    cursor = sqlite3.connect(src_file)

    # create map from nameid
    # each of raws of nams are (nameid, objectname, metricname)
    # convert format as nameid -> {objectname, metricname}
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

    # create map to get name from prefixid
    prefixes = cursor.execute("SELECT * FROM 'prefixes'").fetchall()
    prefix_map = {}
    for p in prefixes:
        if p[0] in prefix_map:
            raise Error("prefixid '%d' exists in the prefix map" % p[0])
        prefix_map[p[0]] = {
            "prefixname": p[1]
        }

    # covret value table into XML tree
    # each of raws are (prefixid, nameid, core, value)
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
        prefixname = "@" + prefix_map[v[0]]["prefixname"]   # @ is spec of xml_parser

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

    # When 0
    zero_list = [
        "uop_fp_addsub",
        "uop_fp_muldiv",

        "uops_total_ra",
        "uops_total_cc_ino",
        "uops_total_ra_ino",

        "uop_cc_ino_load",
        "uop_cc_ino_store",
        "uop_cc_ino_generic",
        "uop_cc_ino_branch",

        "uop_ra_inv_load",
        "uop_ra_inv_store",
        "uop_ra_inv_generic",
        "uop_ra_inv_branch",
        "uop_ra_inv_fp_addsub",
        "uop_ra_inv_fp_muldiv",

        "uop_ra_ino_generic",
        "uop_ra_ino_load",
        "uop_ra_ino_store",
        "uop_ra_ino_branch",
    ]
    for core in value_map.values():
        obj = core["rob_timer"]
        for metric_name in zero_list:
            if metric_name not in obj:
                obj[metric_name] = {"@roi-length": "0"}

    tree = {
        "stats": value_map
    }
    xml_parser.save_file(dst_file, tree)


def main():
    try:
        if sys.version_info.major < 3:
            exit_on_error("This script can be executed only by Python 3.x or later. " + "Use python3.")


        if True:
            if len(sys.argv) != 3:
                exit_on_error("Invalid input. Usage: python3 sniper2mcpat.py <path_to_sim_stats_sqlite3> <path_to_template_xml>")
            stats_sqlite_file = sys.argv[1]
            template_xml_file = sys.argv[2]
        else: # debug
            stats_sqlite_file = "work/spec2017-results_3configs/605.mcf_s/ooo/sim.stats.sqlite3"
            template_xml_file = "mcpat.template.cc-ra.xml"
            #stats_sqlite_file = "work/sim.stats.sqlite3"
            #template_xml_file = "mcpat.template.base.xml"

        base_stats_path = os.path.splitext(stats_sqlite_file)[0]
        stats_xml_file = base_stats_path + ".xml"
        mcpat_xml_file = base_stats_path + ".mcpat.input.xml"
        mcpat_txt_file = base_stats_path + ".mcpat.output.txt"
        mcpat_csv_file = base_stats_path + ".mcpat.output.csv"


        # Get information of McPAT binary from cfg.xml
        config = Config("cfg.xml")

        # Extend stats from sqlite into xml
        if (True):
            print("generate_sniper_output_xml ...\t")
            generate_sniper_output_xml(stats_sqlite_file, stats_xml_file)
            print("[OK]")

        # Embed XML information into McPAT template
        if (True):
            print("setup_mcpat ...\t")
            setup_mcpat(stats_xml_file, template_xml_file, mcpat_xml_file, config)
            print("[OK]")

        # execute mcpat
        if (True):
            print("run_mcpat ...\t")
            run_mcpat(config, mcpat_xml_file, mcpat_txt_file)
            print("[OK]")

        # Parse result of McPAT and generate csv
        print("parse_mcpat_result ...\t")
        parse_mcpat_result(config, mcpat_txt_file, mcpat_csv_file)
        print("[OK]")


    except Error as err:
        exit_on_error(err)
    # except xml_parser.Error as err:
    #     exit_on_error(err)
    # except SniperResultXML.Error as err:
    #     exit_on_error(err)
    # except McPAT_InputXML.Error as err:
    #     exit_on_error(err)

main()
