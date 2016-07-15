"""
 Generate a longtail XML dump of the Fathead output.txt
"""
import csv

from parse import FatWriter

XML = """<?xml version="1.0" encoding="UTF-8"?>
<add allowDups="true">
{results}
</add>
"""

DOC = """<doc>
	<field name="title"><![CDATA[{title}]]></field>
	<field name="paragraph"><![CDATA[{abstract} <a href="{source_url}">{source_url}</a>]]></field>
	<field name="p_count">1</field>
	<field name="source"><![CDATA[mdn_js]]></field>
</doc>"""

def run(infname, outfname):
    infile = open(infname)
    reader = csv.DictReader(infile, FatWriter.FIELDS, dialect='excel-tab')
    with open(outfname, 'w') as outfile:
        rows = []
        for line in reader:
            if line['type'] == "A":
                rows.append(DOC.format(**line))
        results = '\n'.join(rows)
        outfile.write(XML.format(results=results).replace('\\n', '\n'))

if __name__ == '__main__':
    infname = 'output.txt'
    outfname = 'output.xml'
    run(infname, outfname)