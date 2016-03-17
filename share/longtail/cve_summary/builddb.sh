#!/usr/bin/python
from xml.etree import ElementTree as ET

tree = ET.parse('allitems.xml')
root = tree.getroot()

with open("data.xml", "w") as f:
	f.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
	f.write("<add allowDups=\"false\">\n")
	for item in root:
		f.write("<doc>\n")
		name = item.get('name')
		desc = ""
		for child in item.findall('{http://cve.mitre.org/cve/downloads}desc'):
			desc += child.text + " "
		f.write("\t<field name=\"title\">" + name + "</field>\n")
		f.write("\t<field name=\"paragraph\"><![CDATA[" + desc.encode('utf-8') + "]]</field>\n")
		f.write("\t<field name=\"source\">https://cve.mitre.org/cgi-bin/cvename.cgi?name=" + name + "</field>\n")
		f.write("</doc>\n")
	f.close()
