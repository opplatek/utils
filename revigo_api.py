#!/usr/bin/python3
#
# Python script for programtic access to Revigo. Run it with (last output file name is optional):
# python3 revigo.py example.csv 9606
# http://revigo.irb.hr/FAQ.aspx -> How do I integrate Revigo with my service or a programming language? -> The advanced job submitting method
#
# Make revigo python virtual env.
#python3 -m venv revigo
#source revigo/bin/activate
#pip install --upgrade pip
#pip install requests
#
#R # install required R packages
#install.packacges("treemap")
#

import requests
import time
import sys
import os

# Read enrichments file
userData = open(sys.argv[1],'r').read()

taxon = sys.argv[2]
#taxon = '9606' # human
#taxon = '10090' # mouse
#taxon = '4932' # yeast

# Submit job to Revigo
payload = {'cutoff':'0.7', 'valueType':'pvalue', 'speciesTaxon':taxon, 'measure':'SIMREL', 'goList':userData}
r = requests.post("http://revigo.irb.hr/StartJob.aspx", data=payload)

jobid = r.json()['jobid']

# Check job status
running = 1
while (running!=0):
    r = requests.post("http://revigo.irb.hr/QueryJobStatus.aspx", data={'jobid':jobid})
    running = r.json()['running']
    time.sleep(1)

print(jobid)

# Fetch results
#    "jobid" - Job ID that you collected in the first step.
#    "namespace" - [1, 2, 3] The namespace for which you are collecting results. 1 represents BIOLOGICAL_PROCESS, 2 represents CELLULAR_COMPONENT, 3 represents MOLECULAR_FUNCTION.
#    "type" - [csvtable, rtable, xgmml, csvtree, rtree] The type of the output that you require. CSVTable gets the resulting table with Scatterplot data. RTable gets the R script for Scatterplot. Xgmml gets the xgmml for Cytoscape. CSVTree gets the Tree Map data in a comma separated values format. RTree gets the R script for Tree Map.

namespace = [1, 2, 3]
for i in namespace:
    if i == 1:
        name = "bp"
    elif i == 2:
        name = "cc"
    elif i == 3:
        name = "mf"

    print(i)
    print(name)

    # CSV
    r = requests.post("http://revigo.irb.hr/ExportJob.aspx", data={'jobid':jobid, 'namespace':i, 'type':'csvtable'})
    with open('Revigo-' + name + '.csv', 'w') as f:
        f.write(r.text)

    # scatterplot R
    r = requests.post("http://revigo.irb.hr/ExportJob.aspx", data={'jobid':jobid, 'namespace':i, 'type':'rtable'})
    with open('RevigoScatterplot-' + name + '.R', 'w') as f:
        f.write(r.text)
    with open('RevigoScatterplot-' + name + '.R', 'a') as f:
        # Downloaded scatter script doesn't save PDF, so add this line
        f.write('ggsave("' + 'RevigoScatterplot-' + name + '.pdf"' + ', width=10)')

    # cytoscape
    r = requests.post("http://revigo.irb.hr/ExportJob.aspx", data={'jobid':jobid, 'namespace':i, 'type':'xgmml'})
    with open('RevigoCytoscape-' + name + '.xgmml', 'w') as f:
        f.write(r.text)

    # tree
    r = requests.post("http://revigo.irb.hr/ExportJob.aspx", data={'jobid':jobid, 'namespace':i, 'type':'csvtree'})
    with open('RevigoTree-' + name + '.csv', 'w') as f:
        f.write(r.text)

    # tree R
    r = requests.post("http://revigo.irb.hr/ExportJob.aspx", data={'jobid':jobid, 'namespace':i, 'type':'rtree'})
    # Write results to a file - if file name is not provided the default is result.csv
    with open('RevigoTree-' + name + '.R', 'w') as f:
        f.write(r.text)

    # Run R scripts and make figures
    with open('RevigoScatterplot-' + name + '.R') as f:
        if "Error: The namespace" not in f.readline():
            os.system('R CMD BATCH ' + 'RevigoScatterplot-' + name + '.R')
            if os.path.exists('Rplots.pdf'): # in case R failed (possibly no ggplot2 library
                os.remove('Rplots.pdf') # remove default figure

    with open('RevigoTree-' + name + '.R') as f:
        if "Error: The namespace" not in f.readline():
            os.system('R CMD BATCH ' + 'RevigoTree-' + name + '.R')
            if os.path.exists('revigo_treemap.pdf'): # in case R failed (possibly no treemap library
                os.rename('revigo_treemap.pdf', 'RevigoTree-' + name + '.pdf')
