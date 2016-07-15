"""
 Generate a longtail JSON dump of the Fathead output.txt
"""
import csv

from parse import FatWriter

JSON = """[
{results}
]"""

DOC = """
{{\"title\":\"{title} (JavaScript)\",
\"l2_sec\":\"{abstract}\",
\"paragraph\":\"{abstract} <a href=\'{source_url}\'>{source_url}</a>\",
\"p_count\":1,
\"source\":\"instant_answer_id\"
}},"""

def run(infname, outfname):
    infile = open(infname)
    reader = csv.DictReader(infile, FatWriter.FIELDS, dialect='excel-tab')
    with open(outfname, 'w') as outfile:
        rows = []
        for line in reader:
            rows.append(DOC.format(**line))
        results = '\n'.join(rows)
        outfile.write(JSON.format(results=results).replace('\\n', '\n'))

if __name__ == '__main__':
    infname = 'output.txt'
    outfname = 'output.json'
    run(infname, outfname)