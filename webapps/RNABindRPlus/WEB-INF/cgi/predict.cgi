#!/usr/bin/perl -w
$|=1;
#author: Li Xue, R. Walia
#date: February 2012
#This script is part of the script for RNABindR Plus prediction webserver. It is called by predict.cgi
##To predict protein-RNA binding residues for the query protein sequence using  a combination of sequence homology and machine learning methods

use strict;
use File::Path;
use diagnostics;
use CGI ":standard ";
use CGI qw(:standard escapeHTML);
use CGI::Carp "fatalsToBrowser";

use lib "/opt/data/perl5";
use lib "/usr/local/tomcat/webapps/RNABindRPlus/WEB-INF/cgi";
use myfunc;
#-
our $SERVER_name = 'RNABindRPlus';
our $serverDIR         = "/usr/local/tomcat/webapps/$SERVER_name";
our $JavahomeDIR = "/opt/java/jre1.8.0_321/bin";
our $BaseailabDIR = "/opt/data";

#global variables
#our $SERVER  = 'smtp.psu.edu';#'mailhub.iastate.edu';
our $FROM    = 'rnabindr_plus@psu.edu';
our $mailprog = "/usr/sbin/sendmail";    # Location of sendmail; may vary on your system
our $ENVpath = '';

our $HomeDIR = '/home/lixue';
our $PPIDB_DIR             = "$BaseailabDIR/ppidev";      #PPIDB data directory
our $s2cDIR                = "$BaseailabDIR/S2C";
our $pdb_chain_taxonomyLst = "$BaseailabDIR/2019_3_30/pdb_chain_taxonomy.lst";
our $FullRPIDB ="$BaseailabDIR/PRIDB/resiDis";# "$HomeDIR/HOMRPI/PRIDB/resiDis";

our $cgiDIR  = "$serverDIR/WEB-INF/cgi";
our $wekaDIR = "$cgiDIR/ML";#weka.jar is here
our $dataDIR = "$serverDIR/uploadData";   #store all the user-uploaded data for RNABindRPlus
our $logDIR  = "$dataDIR/LOGs";

our $safe_filename_characters = "a-zA-Z0-9_\-";
our $BlastDIR                 = "$BaseailabDIR/ncbi-blast-2.2.29+";#'/home/ppidev/tools/ncbi-blast-2.2.22+'; #changed from 25+
our $BlastDataset = "$BlastDIR/data/nr_RNAprot_s2c/nr_RNAprot_s2c";#"/home/ppidev/tools/ncbi-blast-2.2.22+/data/nr_RNAprot_s2c/nr_RNAprot_s2c";

#--
our $genARFFjarDIR = "$cgiDIR/ML";
our $psiblast      = "$BlastDIR/bin/psiblast";    #'C:\blast-2.2.25-ia32-win32\bin\blastpgp.exe';
our $nrDB     = "$BlastDIR/data/nr/nr";
our $searchNewPPIDBDIR = "$BaseailabDIR/searchNewPPIDB";    #change this diretory according to where searchNewPPIDB is extracted.

my $rmSimilarProtFlag = param('rmSimilarProt') || 'No'; #User may choose to remove highly similar proteins. If user checked this option, the value will be 'yes'
our $protSimilarityThr=param('protSimilarityThr')||100;#the sequence identity threshold that is used to remove highly similar proteins
my $time = localtime();
my $email    = param('email')    || 'No input';
my $jobtitle = param('JobTitle') || "no_input";
my $QrySeq   = param('QuerySeq') || 'No input';   #fasta file pasted by the user
my $querySeqFL = param('querySeqFL') || 'No input';    #fasta file uploaded by the user

my $protein;
my $jobID;    #each submission is assigned an unique $jobID

#-------- check the number of input ---------#
my $flag_paste           = 0;
my $flag_QrySeqFL        = 0;

if ( $QrySeq ne 'No input' && substr($QrySeq,0,1) eq '>' ) {
	$flag_paste = 1;
}
if ( $querySeqFL ne 'No input' ) {
	$flag_QrySeqFL = 1;
}

my $sum = $flag_paste + $flag_QrySeqFL;
if ( $sum == 0 ) {

#if no input, or the user both pasted and uploaded files, then exit the program!
	print header, start_html('warning'),
'<font size="5">Warning: <font color="red">No input</font>. Please paste query sequences OR upload a query file. And try again.</font>',
	  p, end_html();

	exit 1;
}
elsif ( $sum > 1 ) {

	#if user input more than one files, exit the program
	print header, start_html('warning'),
'<font size="5">Warning: Please choose <font color="red">one</font> of two input ways. And try again.</font>',
	  p, end_html();

	exit 1;
}

#-------- check email ---------#
use Email::Valid;

unless ( Email::Valid->address($email) ) {

	print header;
	print
	  '<font size="5">Warning: You supplied an invalid email address.</font>',
	  p, end_html();
	exit;
}

#--------making the JobTitle safe------------

$jobID = $jobtitle;

#$jobID=~tr/ /_/;
$jobID =~ s/[^$safe_filename_characters]/_/g;

if ( $jobID =~ /^([$safe_filename_characters]+)$/ ) {
	$jobID = $1;
}
else {
	die "Job title contains invalid characters.\n";
}

#--------generate unique jobID------------

use Time::localtime;
my $year=localtime->year() + 1900;
my $month=localtime->mon() ;
my $day=localtime->mday() ;
my $hour=localtime->hour();
my $min =localtime->min();
my $t=join('-',($year,$month, $day,$hour,$min));
my $random1 = int(rand(10));
my $random2 = int(rand(10));
$jobID = $t . "." . $random1.$random2. '.' . $jobID;

##--------generate unique jobID------------
#
#my $t = localtime();
#$t =~ s/[\s\t\:]/_/g;
#my $random_number = int(rand(10));
#$jobID = $t . "-" . $random_number . '-' . $jobID;

#Directories
my $result_html = $jobID . "_result.html";
our $jobDIR      = "$dataDIR/$jobID";

#chmod -R 755, $DIR;
rmtree($jobDIR) if ( -d $jobDIR );
mkdir( $jobDIR, 0757 ) || die("cannot makedir $jobDIR:$!");

#File variables

my $proteinFL =
  "$jobDIR/$jobID.fasta";    #save uploaded file or pasted seq as $proteinFL

#----------------------------------------------------------------#
#----------           Program begins                -------------#
#----------------------------------------------------------------#

#----------check the pasted sequences or the uploaded sequences------

my $FLAG = 0;                #flag the type of input file

if ( $QrySeq ne 'No input' && $querySeqFL eq 'No input' ) {
	$FLAG = 1;

	#print "$proteinFL\n";

	&saveFastaFile( $proteinFL, $QrySeq ); #save pasted fasta file as $proteinFL
}

elsif ( $QrySeq eq "No input" && $querySeqFL ne 'No input' ) {
	$FLAG = 2;

	#print "uploaded!\n";
	&uploadFile( $proteinFL, 'querySeqFL' )
	  ;    #save uploaded fasta file as $proteinFL;
}

#------check the pasted/uploaded file is in FASTA format---------
if ( $FLAG == 1 || $FLAG == 2 ) {

	#user input/uploaded a file of protein seqs

	&checkfasta($proteinFL);
}

my @params = ( $jobtitle, $email, $rmSimilarProtFlag);



#------ make predictions
#the batch function takes three parameters:
# (i) $FLAG - query sequences pasted in textbox (1) or file of query sequences (2)
# (ii) $proteinFL - file the contains query amino acid sequences in Fasta format
# (iii) @params - array containing jobtitle and email

sub sleepme{
sleep 10
}

print header;
print "<pre>\n";
print "Your job ($jobID) is now running\n";
print "View output files here: ";
print "<a href='/../RNABindRPlus/uploadData/$jobID' target='_blank' rel='noopener noreferrer'>Output</a>\n";
print "View the running log file (manually refresh that page for updates): ";
print "<a href='/../RNABindRPlus/uploadData/LOGs/$jobID.txt'i target='_blank' rel='noopener noreferrer'>Main Log file</a>\n";

print "When the job finishes, these main output files will be available:\n";
print "<a href='/../RNABindRPlus/uploadData/$jobID/finalpredictionsFor$jobID.txt' target='_blank' rel='noopener noreferrer'>Final Predictions</a>\n";
print "<a href='/../RNABindRPlus/uploadData/$jobID/homologsFor$jobID.txt' target='_blank' rel='noopener noreferrer'>Homologs</a>\n";
print "<a href='/../RNABindRPlus/uploadData/$jobID/statisticsFor$jobID.txt' target='_blank' rel='noopener noreferrer'>Statistics</a>\n";
print "</pre>\n";

# fork this process
my $pid = fork();
die "Fork failed: $!" if !defined $pid;

if ($pid == 0) {
 #save current STDOUT
 open STDIN, "</dev/null";
 open STDOUT, ">/dev/null";
 open STDERR, ">/dev/null";
# sleepme();
 &batch( $FLAG, $proteinFL, @params );
 exit;
}


exit 0;




