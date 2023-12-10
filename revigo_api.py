#!/usr/bin/python3
#
# Python script for programtic access to Revigo. Input is a list of GO terms, optionally with pvalue in the second column
#   separated by a comma. No header.
#
# API described at http://revigo.irb.hr/FAQ#q01 -> How do I integrate Revigo with my service or a programming language? ->
#    The advanced job submitting method -> (scroll down) Programming examples
#
# Make revigo python virtual env.
#python3 -m venv revigo
#source revigo/bin/activate
#pip install --upgrade pip
#pip install requests
# Install required R packages
#R
#install.packacges("treemap")
#

import requests
import time
import os
import argparse

argParser = argparse.ArgumentParser()
argParser.add_argument(
    "-i",
    "--input",
    help="Input GO summary file. No header. Two tab separated columns - first column is GO ID, second is confidence value (for example p-value)",
    required=True,
)
argParser.add_argument(
    "-t",
    "--taxon",
    help="NCBI taxon ID https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi. Default: 0 (no taxon)",
    default=0,
    required=False,
)
argParser.add_argument(
    "-o",
    "--output",
    help="Output file prefix. The script will generate several files with this prefix. Default: revigo.txt",
    default="revigo.txt",
    required=False,
)
args = argParser.parse_args()
print("args=%s" % args)

# Submit job to Revigo
with open(args.input, "r") as f:
    userData = f.read()
    payload = {
        "cutoff": "0.7",
        "valueType": "pvalue",
        "speciesTaxon": args.taxon,
        "measure": "SIMREL",
        "removeObsolete": "true",
        "goList": userData,
    }
r = requests.post("http://revigo.irb.hr/StartJob", data=payload)

jobid = r.json()["jobid"]

# Check job status
running = 1
while running != 0:
    type = "jstatus"
    r = requests.get(f"http://revigo.irb.hr/QueryJob?jobid={jobid}&type={type}")
    running = r.json()["running"]
    time.sleep(1)

# Fetch results
# "namespace" - [1, 2, 3] The namespace for which you are collecting results.
#   1 represents 'Biological process', 2 represents 'Cellular component', 3 represents 'Molecular function'.
namespace_explain = {
    "1": "biological_process",
    "2": "cellular_component",
    "3": "molecular_function",
}
# "type" - [jStatus, jInfo, jTable, Table, jScatterplot, Scatterplot, RScatterplot, jScatterplot3D, Scatterplot3D,
#   jCytoscape, Xgmml, jTreeMap, TreeMap, RTreeMap, jClouds, SimMat] The type of the output that you require.
type_suffix = {
    "Table": "tsv",
    "Scatterplot": "tsv",
    "RScatterplot": "R",
    "Scatterplot3D": "tsv",
    "Xgmml": "xgmml",
    "TreeMap": "tsv",
    "RTreeMap": "R",
    "jClouds": "json",
}
for namespace in namespace_explain.keys():
    namespace_translate = namespace_explain[namespace]
    for type in type_suffix.keys():
        suffix = type_suffix[type]
        r = requests.get(
            f"http://revigo.irb.hr/QueryJob?jobid={jobid}&namespace={namespace}&type={type}"
        )
        ofile_res = (
            f"{os.path.splitext(args.output)[0]}-{namespace_translate}-{type}.{suffix}"
        )
        with open(ofile_res, "w") as f:
            f.write(r.text.replace("\r\n", "\n"))

    # Plot R scripts
    scatterplot = f"Revigo-{namespace_translate}-RScatterplot"
    with open(f"{scatterplot}.R", "a") as f:
        f.write(f'ggsave("{scatterplot}.pdf", width=10)')

    with open(f"{scatterplot}.R", "r") as f:
        if "error: The namespace" not in f.readline():
            os.system(f"R CMD BATCH {scatterplot}.R")
            if os.path.exists(
                "Rplots.pdf"
            ):  # in case R failed (possibly no ggplot2 library)
                os.remove("Rplots.pdf")

    treemap = f"Revigo-{namespace_translate}-RTreeMap"
    with open(f"{treemap}.R", "r") as f:
        if "error: The namespace" not in f.readline():
            os.system(f"R CMD BATCH {treemap}.R")
            if os.path.exists(
                "revigo_treemap.pdf"
            ):  # in case R failed (possibly no treemap library)
                os.rename("revigo_treemap.pdf", f"{treemap}.pdf")
