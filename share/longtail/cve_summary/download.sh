#/bin/sh                                                                                                                                                                                                  
URL=https://cve.mitre.org/data/downloads/allitems.xml.gz                                                                                                                                                  
SOURCE_FILE=allitems.xml                                                                                                                                                                                  
                                                                                                                                                                                                          
curl $URL | gzip -d > $SOURCE_FILE                                                                                                                                                                        
#TODO parse XML and extract summary   
