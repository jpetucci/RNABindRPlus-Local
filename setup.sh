#!/bin/bash

#extract dependencies
echo "Extracting dependencies..."
tar -xf rnabindrplus.tar.gz

#create required directories
echo "Creating directories..."
mkdir tomcat_work
mkdir tomcat_logs
mkdir rnabindrplus_output
mkdir tomcat_conf_runtime

echo "Done!"
