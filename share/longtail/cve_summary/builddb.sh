#!/usr/bin/python
from xml.etree import ElementTree as ET

tree = ET.parse('allitems.xml')
root = tree.getroot()

print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
print "<add allowDups=\"false\">"
for item in root:
	print "<doc>"
	name = item.get('name')
	desc = ""
	for child in item.findall('{http://cve.mitre.org/cve/downloads}desc'):
		desc += child.text + " "
	print "<field name=\"title\">" + name + "</field>"
	print "<field name=\"paragraph\"><![CDATA[" + desc.encode('utf-8') + "]]</field>"
	print "<field name=\"source\">https://cve.mitre.org/cgi-bin/cvename.cgi?name=" + name + "</field>"
	print "</doc>"

