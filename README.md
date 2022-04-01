# RNABindRPlus-Local

## Table of contents
* [General info](#general-info)
* [Installation](#installation)
* [Usage](#usage)

## General Info
This repo contains code to run a local instance of RNABindRPlus as described in the publication "RNABindRPlus: A Predictor that Combines Machine Learning and Sequence Homology-Based Methods to Improve the Reliability of Predicted RNA-Binding Residues in Proteins", available here https://doi.org/10.1371/journal.pone.0097725

## Installation
Singularity is required (see https://sylabs.io/guides/latest/admin-guide/installation.html for installation instructions.) and a web browser (Firefox and Chrome tested)
1. Clone this repo and enter the top level directory
```bash
$ git clone git@github.com:jpetucci/RNABindRPlus-Local.git
$ cd ./RNABindRPlus-Local
$ export RNABINDRPLUS_HOME=$PWD
```
2. Download the Singularity container under the release menu assests (rnabindrplus-local.sif) into $RNABINDRPLUS_HOME
3. Download the dependencies and data (~50 GB uncompressed) from here http://ailab-projects2.ist.psu.edu/RNABindRPlus/local_data/rnabindrplus.tar.gz or https://drive.google.com/drive/folders/1yyVYhvxUu7Xu5G-6GSF5Selvo4kUWHWK?usp=sharing into $RNABINDRPLUS_HOME. Note this archive contains an older version of blast and the nr database.
4. Run the setup script:
```bash
$ ./setup.sh
```

## Usage
RNABindRPlus-Local utilizes a local tomcat webserver as the GUI front end
1. In $RNABINDRPLUS_HOME start the server (leave the shell open with tomcat running)
```bash
$ ./start-server.sh
```
2. Open a web-browser and navigate to http://localhost:8080/RNABindRPlus
3. From here, usage is the same as the public server. Upon job submission, a simple html site will be presented summarizing access to output and log files.
