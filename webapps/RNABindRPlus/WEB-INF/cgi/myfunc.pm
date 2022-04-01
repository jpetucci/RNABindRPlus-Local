#These are all the routines for the RNABindRv2.0 webserver
sub jobSubmitEmail {

    use strict;
    use warnings;

    #	use Mail::Mailer;
    use Email::Valid;
    use MIME::Lite;

    # use MIME::Lite::TT::HTML;

    our $SERVER;
    our $FROM;
    our $SERVER_name;
    our $protSimilarityThr;
    my $params_ref = shift @_;

    #	my $logFL      = shift @_;
    my $FLAG = shift @_;
    my $msg;
    my ( $jobtitle, $email, $rmSimilarProtFlag ) = @$params_ref;

    unless ( Email::Valid->address($email) ) {
        die "You supplied an invalid email address $email:$!";
        exit 1;
    }

    my $param = "<h3>Thank you for using $SERVER_name.</h3>
	Your job <i>$jobtitle</i> is currently running ...<p></p>
	You will be notified by email after the prediction is finished.<p></p>";
    if ( $rmSimilarProtFlag =~ /Yes/i ) {
        my $newLine =
"\n<TR> <TD><FONT COLOR=\"Blue\"> Sequence Identity threshold of proteins to be removed: </FONT></TD><TD> $protSimilarityThr %</TD></TR>";
        $param = $param . $newLine;
    }

    if ( $FLAG == 3 ) {

        $msg = MIME::Lite->new(
            Subject => "$SERVER_name Submission  Details for $jobtitle",
            From    => 'rnabindr_plus@iastate.edu',
            To      => $email,
            Type    => 'text/html',
            Data    => "$param.</TABLE>


<p></p><p></p>
If you have questions regarding $SERVER_name, please visit the corresponding web page(s) or write to $FROM."
        );
    }
    elsif ( $FLAG == 1 || $FLAG == 2 ) {
        $msg = MIME::Lite->new(
            Subject => "$SERVER_name Submission  Details for $jobtitle",
            From    => 'rnabindr_plus@iastate.edu',
            To      => $email,
            Type    => 'text/html',
            Data    => "$param.</TABLE>

<p></p><p></p>
If you have questions regarding $SERVER_name, please visit the corresponding web page(s) or write to $FROM."
        );
    }

    $msg->send( 'smtp', $SERVER, Timeout => 60 );

    print LOG "A submission confirmation email is sent to $email. \n";
}

#------------
sub errorEmail {
    use strict;
    use warnings;

    #	use Mail::Mailer;
    use Email::Valid;
    use MIME::Lite;

    # use MIME::Lite::TT::HTML;
    our $SERVER;
    our $SERVER_name;
    our $FROM;
    our $dataDIR;
    my $msg;
    my $params_ref = shift @_;
    my ( $jobtitle, $email ) = @$params_ref;

    my $jobID = shift @_;

    $msg = MIME::Lite->new(
        Subject => "$SERVER_name Error for $jobtitle",
        From    => 'rnabindr_plus@iastate.edu',
        To      => $email,
        Type    => 'text/html',
        Data =>
"There was an error in the input file. Please check and submit your job again."
    );
    $msg->send( 'smtp', $SERVER, Timeout => 120 );

    #$msg->send();
    print LOG "An error email is sent to $email. \n";

}

#-----------------------

sub resultEmail {

    use strict;
    use warnings;

    use Email::Valid;
    use MIME::Lite;

    # use MIME::Lite::TT::HTML;

    our $SERVER;
    our $SERVER_name;
    our $FROM;
    our $dataDIR;
    our $serverDIR;

    my $params_ref = shift @_;
    my $jobID      = shift @_;
    my $FLAG       = shift @_;

    my $msg;

    my $finalPredictionFL =
"http://ailab1.ist.psu.edu/$SERVER_name/uploadData/$jobID/finalpredictionsFor$jobID.txt";
    my $homologsFL =
"http://ailab1.ist.psu.edu/$SERVER_name/uploadData/$jobID/homologsFor$jobID.txt";
    my $statisticsFL =
"http://ailab1.ist.psu.edu/$SERVER_name/uploadData/$jobID/statistics_$jobID.txt";

    #my $jobDIR     = "$dataDIR/$jobID";
    my ( $jobtitle, $email ) = @$params_ref;

    unless ( Email::Valid->address($email) ) {
        die("You supplied an invalid email address $email:$!");

        #		print header;
        #		print "You supplied an invalid email address.\n";
        #		exit;
    }

    my $param = "<h3>Thank you for using $SERVER_name.</h3>
			The results for your job <i>$jobtitle</i> are now available.<p></p>
			The interface prediction results can be downloaded <a href = $finalPredictionFL> here</a>. <p></p>
			The homologs of your query protein(s) and their corresponding IC_scores can be downloaded <a href = $homologsFL> here</a>. <p></p>
			All potential homologs that exist in the Protein Data Bank (PDB) protein-RNA complexes and their sequence similarity to the query proteins can be downloaded <a href = $statisticsFL> here</a>. <p></p>";

    if ( $FLAG == 3 ) {

        $msg = MIME::Lite->new(
            Subject => "$SERVER_name Prediction Results for $jobtitle",
            From    => 'rnabindr_plus@iastate.edu',
            To      => $email,
            Type    => 'text/html',
            Data    => "$param.</TABLE>

<p></p><p></p>
If you have questions regarding $SERVER_name, please visit the corresponding web page(s) or write to $FROM."
        );
        $msg->attach(
            Type => 'text/plain',
            Data => $finalPredictionFL
        ) or print LOG "Error adding the text message part: $!\n";
    }
    elsif ( $FLAG == 1 || $FLAG == 2 ) {
        $msg = MIME::Lite->new(
            Subject => "$SERVER_name Prediction Results for $jobtitle",
            From    => 'rnabindr_plus@iastate.edu',
            To      => $email,
            Type    => 'text/html',
            Data    => "$param.</TABLE>

<p></p><p></p>
If you have questions regarding $SERVER_name, please visit the corresponding web page(s) or write to $FROM."
        );

    }

    $msg->send( 'smtp', $SERVER, Timeout => 60 );

    print LOG "\n\nA prediction result email is sent to $email. \n";


}

#-----------------
sub saveFastaFile {

#author: Xue, Li
#date: Apr., 2009
#This script is part of the script for the RNA-protein interface prediction webserver.
#
#To save user input sequences into fasta file to /uploadData/HOMPPI/$jobID/$taskID/$taskID.fasta.txt.
#$taskID is unique for each query
#
#Usage: perl ./saveFile1.pl $ProteinToBePredictedDIR/$fastaFL  $QrySeq
#e.g.: perl ./saveFile1.pl /uploadData_RPI/test/xue.txt 'UOOIENINIONONINONIONO'

    use strict;
    use diagnostics;

    use CGI ":standard";
    use CGI::Carp qw(fatalsToBrowser);
    use File::Basename;
    our $safe_filename_characters;

    #Variables
    my $proteinFL = shift @_;

    #$proteinFL =~ s/[^$safe_filename_characters]/_/g;
    #Directories
    my $jobDIR = dirname($proteinFL);
    my $qrySeq = shift @_;              #fasta file pasted by the user

    #File variables

#---------------------------------------------------------------------------------#
#
#              program begins
#

    #mkdir( $jobDIR, 0777 ) || die("cannot makedir $jobDIR\n");

    #--------save file---------
    open( INPUT, ">>$proteinFL" ) || fail();
    print INPUT "$qrySeq";
    close(INPUT);

    #---------

    sub fail {
        print "<title>Error</title>", "<p>Error: cannot open proteinFL!</p>";
        exit;
    }
}

#==========================================================================================================================
sub uploadFile {

    #save uploaded FASTA file as $proteinFL = $ProteinToBePredictedDIR/$fastaFL
    #Author: Xue, Li
    #date: May, 2009
    #
    #This script is part of RNA-protein interface predictioin
    #
    #This script is to upload FASTA query file into $ProteinToBePredictedDIR
    #The maximum upload filesize is 100K

    use strict;

    #use CGI ":standard";
    my $maxFLSize = 10;    # maximum upload filesize is 10K
    $CGI::POST_MAX = 1024 * $maxFLSize;    # maximum upload filesize is 10K

    my $query          = new CGI;
    my $proteinFL      = shift @_;
    my $uploadFLhandle = shift @_;
    my $jobDIR         = dirname($proteinFL);

    #----- Look for uploads that exceed $CGI::POST_MAX-------

    if ( !$query->param('querySeqFL') && $query->cgi_error() ) {
        print $query->cgi_error();
        print p,
"The file you are attempting to upload exceeds the maximum allowable file size $maxFLSize K.",
          p, 'Please refer to your system administrator', p;
        print $query->hr, $query->end_html;
        exit 0;
    }

    #----- Upload file-------

    my $upload_filehandle = $query->upload($uploadFLhandle);

    #mkdir( $jobDIR, 0777 ) || die("Cannot make dir\n");
    unlink $proteinFL if ( -e $proteinFL );

    open UPLOADFILE, ">$proteinFL" || die("Cannot open $proteinFL!");

    while (<$upload_filehandle>) {
        chomp;
        s/[\n\r]//mg;
        print UPLOADFILE "$_\n";
    }

    close UPLOADFILE;

}

#----------------------------------------------------------------------------------------------------------------------------

sub checkfasta {

    #Xue, Li
    #May 2009
    #check input file format is FASTA format or not

    my $FL     = shift @_;
    my $lineNo = 0;
    open( INPUT, "<$FL" ) || die("Cannot open $FL!\n");
    foreach my $line (<INPUT>) {
        $line =~ s/[\n\r]//mg;    #remove \r and \n
        $lineNo = $lineNo + 1;

        if ( $line =~ /^#/ ) {
            next;
        }
        elsif ($line =~ /^\>.+$/
            || $line =~ /^[a-zA-Z]+$/
            || $line =~ /^[\s\t]{0,}$/ )
        {

            next;
        }
        else    #this line is not in FASTA format
        {
            #print header, start_html('warning'),
            print LOG
"<font size=\"5\">Warning: Please check the input file format. Start from line $lineNo.</font>";

            #p, "<a href=\"seqexample.txt\"> Click here for an example<\/a>",
            #p, end_html();
            exit 1;
        }

    }
}

#---------------------------------------------------------------------------------------------------------------------------------------------------
sub convertFasta2onelineFormat {

    #perl convertFasta2onelineFormat.pl ../data/dockingTestSet.fasta
    use strict;

    my $inputFL = shift @_;
    our $dataDIR;
    my $tempFL = "$dataDIR/file.tmp";
    my $seq;

    unlink $tempFL if ( -e $tempFL );
    open( OUTPUT, ">>$tempFL" ) || die("Cannot open $tempFL\n");

    open( INPUT, "<$inputFL" ) || die("Cannot open $inputFL\n");

    foreach (<INPUT>) {
        s/[\n\r]+//mg;

        if (/>/) {
            if ($seq) {
                print OUTPUT "\n";
            }
            print OUTPUT "$_\n";
            next;
        }

        if (/^([a-zA-Z]+)$/) {
            $seq = $1;
            print OUTPUT $seq;

        }

    }
    close(INPUT);
    close(OUTPUT);

    unlink($inputFL);
    rename( $tempFL, $inputFL );

}

#------------------------------------------------------------------------------------------------------------------------------------
sub readTaskIDs {

    #	read task IDs from input fasta file
    use strict;

    my $inputFL = shift @_;
    my $FLAG    = shift @_;    #1 and 2: user input fasta file
    my @taskIDs;
    my $taskID;
    our $jobDIR;
    my $flag = 0;
    our $safe_filename_characters;

    if ( $FLAG == 1 || $FLAG == 2 ) {

        @taskIDs = &folderGen($inputFL);

    }
    foreach (@taskIDs) {
        $taskID = $_;

        #		open( LOG, ">>$logFL" ) || die("Cannot open $logFL!\n");
        print LOG
"\n\n-----------------------------------------------------------------------\n\n";

        #		close LOG;

        #---------- File variables
        my $ProteinToBePredictedDIR =
          "$jobDIR/$taskID";    #each query is given a specific directory
        my $predictionResultsDIR = "$ProteinToBePredictedDIR/predictionResults";

        my $fastaFL = "$taskID.fasta.txt";
        $fastaFL = "$ProteinToBePredictedDIR/$fastaFL";
    }
    return \@taskIDs;

}

#--------------------------------------------------------------------------------------------------------------------------------------------------------
sub folderGen {

    #author: Xue, Li
    #date: Dec, 2007
    #This script is part of the pipeline of HomoPPI
    # 1.  generate folders for each protein in user input file
    # 2.  return the name list of sequences in the input file
    # 3.  generate fasta file, eg, 1LUK_A.fasta.txt
    # todo:4.  automatically download pdb file for each $taskID
    #
    #perl ./foldersGen.pl  ../RB181BindingSites.txt

    use strict;
    use File::Basename;
    use File::Path;

    my $inputFL = shift @_;

    #	my $logFL   = shift @_;
    my $taskID;
    my $fastaFL;
    my $header;    #>(.)
    my $seq;
    my $num  = 0;    #number of protein folders
    my $flag = 0;    #flag a new sequence met
    our $safe_filename_characters;
    my $currentDIR = dirname($inputFL);
    my $taskIDDIR;
    my @seqNames = ();

    #	open( LOG, ">>$logFL" ) || die("Cannot open $logFL:$!");

    open( INPUTFL, "<$inputFL " ) || die(" Cannot open $inputFL:$!\n ");
    foreach my $line (<INPUTFL>) {

        $line =~ s/[\n\r]//mg;    #remove \r and \n

        if ( $line =~ /^>(.+)/ ) {
            $flag = 1;
            $num++;
            $header = $1;
            $taskID = $1;

#--------$taskID will be used as folder name, so we should make $taskID safe------------

            $taskID =~ s/[^$safe_filename_characters]/_/g;
            my $length_of_str = length($taskID);
            if ( $length_of_str > 15 ) {
                $taskID = substr( $taskID, 0, 15 );
            }

            #$taskID =~ s/[^$safe_filename_characters]/0/g;

            if ( $taskID =~ /^([$safe_filename_characters]+)$/ ) {
                $taskID = $1;

            }
            else {
                die " Input protein name contains invalid characters:$! \n ";
            }

            #----------------------------------
            print LOG " Generating a folder for $taskID. \n";

            $taskIDDIR = "$currentDIR/$taskID";
            $fastaFL   = "$taskIDDIR/$taskID.fasta.txt";
            rmtree($taskIDDIR) if ( -e $taskIDDIR );
            mkdir($taskIDDIR) || die(" Cannot make directory $taskIDDIR !\n ");

            #write the head of $homolog.fasta.txt
            unlink $fastaFL if ( -e $fastaFL );
            open( FASTA, ">>$fastaFL " );
            print FASTA ">$header\n";
            close FASTA;

            push( @seqNames, $taskID );

            next;
        }

        if ( $flag == 1 && $line =~ /^([A-Za-z]+)\s*$/ ) {
            $seq = uc($1);

            #write sequence part of $taskID.fasta.txt
            open( FASTA, ">>$fastaFL" );
            print FASTA "$seq";
            close FASTA;
            next;
        }
    }
    print LOG
      "$num folders are generated! In each folder, there is a fasta file.\n ";

    #	close LOG;

    return @seqNames;
}

#-----------------------------------------------------------------------------------------------------------------------------------------------
sub writeThankYouHtml {
    #insert input parameters to $basicISUhtml
    use strict;
    use CGI " : standard: html3 ";

    our $SERVER_name;
    our $protSimilarityThr;

    my $param_ref = shift @_;
    my $FLAG      = shift @_;

    my ( $jobtitle, $email, $rmSimilarProtFlag ) = @$param_ref;

    my $basicISUhtml = 'basicISU.html';

    open( INPUT, " < $basicISUhtml " )
      || die(" Cannot open $basicISUhtml . \n ");

    print header;

    foreach (<INPUT>) {
        if (/<!-- INSERT your content here -->/) {
            print "$_ ";
            print "<h3>Thank you for using $SERVER_name.</h3>";
            print " Your job <i>$jobtitle </i> is currently running ......";
            print '<p></p> ';
            print
' You will be notified by email after the prediction is finished . ';
            print ' <p> </p>';
            print "Please check <font color=\"red\">$email </font>is correct.";
            print ' <p> </p>';

            #if ( $rmSimilarProtFlag =~ /Yes/i ) {
            #print LOG "hello\n";

#print
#"<TR> <TD><FONT COLOR=\"Blue\"> Sequence Identity threshold for proteins to be removed: </FONT></TD><TD> $protSimilarityThr %</TD></TR>";
#}
        }
        else {
            print "$_";
        }
    }
    close(INPUT);
}

#----------------------------------------------------------------------------------------
# main function that calls other functions
sub batch {

## Please see file perltidy.ERR
    #!/usr/bin/perl -w
    # Rasna Walia
    # June, 2012
    use strict;
    use File::Basename;
    use File::Copy;
    use File::Path;

    our $HomeDIR;
    our $dataDIR;
    our $perlDIR;
    our $safe_filename_characters;
    our $logDIR;

    #----
    my $FLAG = shift @_; #1 or 2 : $inputFL is seqs; 3:$inputFL is PDB/chain IDs
    my $inputFL = shift @_;
    my @params  = @_;
    my ( $jobtitle, $email, $rmSimilarProtFlag ) = @params;
    my $jobID = basename( $inputFL, ( '.fasta', '.lst', '.txt' ) );

    my $jobDIR = "$dataDIR/$jobID";    #all the data for a submission job
    my $basename = basename( $inputFL, ( '.txt', '.lst', '.fasta' ) );

    #=================================================================================================
    # Variables specific to HomPRIP
    #=================================================================================================
    my $qryWithSafeZoneHomologFL = "$jobDIR/$jobID.qryWithSafeZoneHomolog";
    my $qryWithTwilightZoneHomologFL =
      "$jobDIR/$basename.qryWithTwilightZoneHomolog";
    my $qryWithTwiHomologFL1 = "$jobDIR/$jobID.qryWithTwilightZoneHomolog1";
    my $qryWithTwiHomologFL2 = "$jobDIR/$jobID.qryWithTwilightZoneHomolog2";
    my $qryWithTwiHomologFL3 = "$jobDIR/$basename.qryWithTwilightZoneHomolog3";
    my $qryWithDarkZoneHomologFL = "$jobDIR/$jobID.qryWithDarkZoneHomolog";
    my $FullStatFL;

    my $qryWoSafeHomFL      = "$jobDIR/$basename.qryWoSafeZoneHomolog";
    my $qryWoSafeTwiHomFL1  = "$jobDIR/$basename.qryWoSafeTwiHomolog1";
    my $qryWoSafeTwiHomFL2  = "$jobDIR/$basename.qryWoSafeTwiHomolog2";
    my $qryWoSafeTwiHomFL3  = "$jobDIR/$basename.qryWoSafeTwiHomolog3";
    my $qryWoSafeTwiDkHomFL = "$jobDIR/$basename.qryWoSafeTwiDkHomolog";

    unlink $qryWoSafeHomFL      if ( -e $qryWoSafeHomFL );
    unlink $qryWoSafeTwiHomFL1  if ( -e $qryWoSafeTwiHomFL1 );
    unlink $qryWoSafeTwiHomFL2  if ( -e $qryWoSafeTwiHomFL2 );
    unlink $qryWoSafeTwiDkHomFL if ( -e $qryWoSafeTwiDkHomFL );

    our $scoreThr = 0.5;
    my $maxEvalue    = 10;
    my $minPositiveS = 0;
    my $atomDistThr  = 5;
    my $k            = 5;

#===========================================================================================================

    my $logFL = "$logDIR/$jobID.txt";

    unlink($logFL) if ( -e $logFL );

    open LOG,    ">> $logFL";
    open STDERR, ">>$logFL";

    #----------send an email to the user-----
    #&jobSubmitEmail( \@params,  $FLAG );

    print LOG "\n\n****\tjobID: $jobID\t****\n\n";
    my $time = localtime();
    print LOG "This job started on $time.\n\n";
    print LOG " FLAG = $FLAG\n\n";

    #-------------------------
    my $taskIDs = &readTaskIDs( $inputFL, $FLAG );

    #write full list of input protein IDs
    my $fullLst = "$jobDIR/full_taskIDs.lst";
    &writeFullLst( $taskIDs, $fullLst );
    if ( !-e $fullLst ) {
        print LOG "$fullLst does not exist\n";
        die("$fullLst does not exist:$!");
        &errorEmail( \@params, $jobID );
        exit 10;
    }

    # ----- collect qrys to be predicted
    my @qrys4SVM = &getQrys4SVM($fullLst);    #$qryWoSafeTwiDkHomFL

    #===========================================================================================================
    #SVM  part
    #===========================================================================================================
	#	# ----- generate PSSM files to $jobDIR/pssm

    my $t1=time();
	my @newqrys4SVM = &genPSSM( \@qrys4SVM, $jobDIR);
    my $t2=time();
    my $diff_time = $t2 - $t1;
    print LOG "\n\ntime used in genPSSM:$diff_time\n\n";

	my $qryFL4SVM = "$jobDIR/qry4SVM.seq";
	&writeQry4SVM( \@newqrys4SVM, $qryFL4SVM, $jobDIR );

	# ----- generate arff files
	&genARFF( $qryFL4SVM, $jobDIR );

	# ----- use SVM to predict the qrys that cannot be predicted by NPS-HomPRIP
	my $arffDIR = "$jobDIR/arff_files";
	&callSVM( \@newqrys4SVM, $arffDIR );

	#-----
	#extract prediction from SVM and write predictionResults/qry.SVM.prediction
	&extractPredictWeka2( \@newqrys4SVM, $arffDIR, $jobDIR );

	# ----- collect all the prediction results for the queries into one file
	#	my @taskIDs = &readInputFL($inputFL);
	&collectPredictionFLsIntoOneFLSVM( $jobID, \@newqrys4SVM );

    #===========================================================================================================
    #HomPRIP part
    #===========================================================================================================
    if ( $rmSimilarProtFlag =~ /Yes/i ) {
        $FullStatFL = "$jobDIR/statistics\_$jobID\_wo_sameProteins.txt";
    }
    elsif ( $rmSimilarProtFlag =~ /No/i ) {
        $FullStatFL = "$jobDIR/statistics\_$jobID.txt";
    }
    my $workIDs =
      &conservAnalysis( $inputFL, $maxEvalue, $minPositiveS, $atomDistThr,
        $FLAG, \@qrys4SVM, $rmSimilarProtFlag );
    print LOG "\n\nfullStatFL: $FullStatFL\n\n";
    if ( !-e $FullStatFL ) {
        die("$FullStatFL does not exist. Check sub conservAnalysis():$!");
    }

# ---------------- Safe Zone---------------------------------------------------------------------------
    my $Mode = 'SafeMode';

    my ( $qryWithSafeZoneHomolog, $qryCannotbePredicted_inSafe ) =
      &mode( $jobDIR, $fullLst, $scoreThr, $FullStatFL, $Mode,
        $qryWithSafeZoneHomologFL, $qryWoSafeHomFL );
    my $num_qryWithSafeZoneHomolog = scalar @$qryWithSafeZoneHomolog;

    print LOG
"There are $num_qryWithSafeZoneHomolog qrys with Safe Zone Homologs. They are saved in $qryWithSafeZoneHomologFL. \n";

# ---------------------------Twilight Zone------------------------------------------------------------

    $Mode = 'TwilightMode1';

    if ($qryCannotbePredicted_inSafe) {

        my ( $qryWithTwiHomolog1, $qryCannotbePredicted_inTwi1 );
        my $num1 = scalar(@$qryCannotbePredicted_inSafe);
        if ( $num1 > 0 ) {
            ( $qryWithTwiHomolog1, $qryCannotbePredicted_inTwi1 ) =
              &mode( $jobDIR, $qryWoSafeHomFL, $scoreThr, $FullStatFL, $Mode,
                $qryWithTwiHomologFL1, $qryWoSafeTwiHomFL1 );
            my $num_qryWithTwiHom1 = scalar @$qryWithTwiHomolog1;
            print LOG
"There are $num_qryWithTwiHom1 qrys with only Twilight Zone Homologs. They are saved in $qryWithTwiHomologFL1.\n";
        }    #end num1

# -----twilight zone 2---------------------------------------------------------------------------------
        $Mode = 'TwilightMode2';
        if ($qryCannotbePredicted_inTwi1) {
            my ( $qryWithTwiHomolog2, $qryCannotbePredicted_inTwi2 );
            my $num2 = scalar(@$qryCannotbePredicted_inTwi1);
            if ( $num1 > 0 && $num2 > 0 ) {
                ( $qryWithTwiHomolog2, $qryCannotbePredicted_inTwi2 ) =
                  &mode( $jobDIR, $qryWoSafeTwiHomFL1, $scoreThr, $FullStatFL,
                    $Mode, $qryWithTwiHomologFL2, $qryWoSafeTwiHomFL2 );
                my $num_qryWithTwiHom2 = scalar @$qryWithTwiHomolog2;
                print LOG
"There are $num_qryWithTwiHom2 qrys with only Twilight Zone Homologs. They are saved in $qryWithTwiHomologFL2.\n";
            }    #end num1 && num2

# ----twilight zone 3----------------------------------------------------------------------------------
            $Mode = 'TwilightMode3';
            if ($qryCannotbePredicted_inTwi2) {
                my ( $qryWithTwiHomolog3, $qryCannotbePredicted_inTwi3 );
                my $num3 = scalar(@$qryCannotbePredicted_inTwi2);
                if ( $num1 > 0 && $num2 > 0 && $num3 > 0 ) {
                    ( $qryWithTwiHomolog3, $qryCannotbePredicted_inTwi3 ) =
                      &mode( $jobDIR, $qryWoSafeTwiHomFL2, $scoreThr,
                        $FullStatFL, $Mode, $qryWithTwiHomologFL3,
                        $qryWoSafeTwiHomFL3 );
                    my $num_qryWithTwiHom3 = scalar @$qryWithTwiHomolog3;
                    print LOG
"There are $num_qryWithTwiHom3 qrys with only Twilight Zone3 Homologs. They are saved in $qryWithTwiHomologFL3.\n";
                }    #end num1 && num2 && num3

                 # ----- Dark Zone----------------------------------------------------------------------------
                $Mode = 'DarkMode';
                if ($qryCannotbePredicted_inTwi3) {
                    my ( $qryWithDkZoneHomolog, $qryCannotbePredicted_inDk );
                    my $num4 = scalar(@$qryCannotbePredicted_inTwi3);

                    if ( $num1 > 0 && $num2 > 0 && $num3 > 0 && $num4 > 0 ) {

                        ( $qryWithDkZoneHomolog, $qryCannotbePredicted_inDk ) =
                          &mode(
                            $jobDIR,              $qryWoSafeTwiHomFL3,
                            $scoreThr,            $FullStatFL,
                            $Mode,                $qryWithDarkZoneHomologFL,
                            $qryWoSafeTwiDkHomFL, $k
                          );

                        my $num_qryWithDkZoneHomolog =
                          scalar @$qryWithDkZoneHomolog;

                        print LOG
"There are $num_qryWithDkZoneHomolog qrys with only Dark Zone Homologs. They are saved in $qryWithDarkZoneHomologFL .\n";
                    }    #end num1 num2 num3 num4
                    if ( -e $qryWoSafeTwiDkHomFL ) {
                        print LOG
"\n\nSome query proteins cannot be predicted by NPS-HomPRIP.\n\n";
                        my @qrys4Blank = &getQrys4Blank($qryWoSafeTwiDkHomFL)
                          ;    #$qryWoSafeTwiDkHomFL
                        &appendPrediction( \@qrys4Blank, $jobDIR );
                    }    #end qryWoSafeTwiDkHomFL
                }    #end qryCannotbePredicted_inTwi3
            }    #end qryCannotbePredicted_inTwi2
        }    #end qryCannotbePredicted_inTwi1
    }    #end qryCannotbePredicted_inSafe
    &collectPredictionFLsIntoOneFLKNN( $jobID, $workIDs );


    #=============================================================================================================
    #This is the RNABindRPlus Part
    #=============================================================================================================

	&createARFF($jobID);
	my $otherDIR = "$jobDIR/arff_files/HomPRIP_SVM";
	&callRNABindRPlus( \@newqrys4SVM, $otherDIR );
	&extractPredictions( \@newqrys4SVM, $otherDIR, $jobDIR );
	&collectPredictionFLsIntoOneFL( $jobID, \@newqrys4SVM );
    #=============================================================================================================
	#Collect predictions from the different methods
	&mergePredictions($jobID);
    #============================================================================================================
	#send prediction result email
	#&resultEmail( \@params, $jobID, $FLAG );

	$time = localtime();
	print LOG " \n \nPrediction is finished at $time. \n ";
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------ge
#Change made on 09/04/2012
sub mergePredictions{
    use strict;
	use File::Basename;

	my $jobID   = shift @_;
	our $dataDIR;
	my $jobDIR   = "$dataDIR/$jobID";
	my $knnFL = "$jobDIR/predictionsFor$jobID.KNN.txt ";
	my $svmFL = "$jobDIR/predictionsFor$jobID.SVM.txt ";
	my $RBPlusFL = "$jobDIR/predictionsFor$jobID.txt ";
	my $outputFL = "$jobDIR/finalpredictionsFor$jobID.txt ";

	open(F, $knnFL) or die " Can't open file : '".$knnFL."', Reason $!\n ";
	our @knn = <F>;
	close(F);

	open(F, $svmFL) or die " Can't open file : '".$svmFL."', Reason $!\n ";
	our @svm = <F>;
	close(F);

	open(F, $RBPlusFL) or die " Can't open file : '".$RBPlusFL."', Reason $!\n ";
	our @rbplus = <F>;
	close(F);

	unlink($outputFL) if ( -e $outputFL );
	open( OUTPUT, " >> $outputFL " );

	my $length = scalar(@rbplus);
	my $homlength = scalar(@knn);

	if ($length == $homlength){
		for(my $i = 0; $i < $length - 3; $i = $i+4){
			chomp($rbplus[$i+1]);
			my @temp = split(/\s+/,$rbplus[$i+1]);
			chomp(@temp);
			my @seq = split(//,$temp[1]);
			chomp(@seq);
			my $length = scalar(@seq);
			print OUTPUT "    #Input sequence length: $length\n";
          $knn[ $i + 3 ] =~ s/[\r\n\f\t]//g;
          $knn[ $i + 3 ] = substr( $knn[ $i + 3 ], 11 );
          my @pred = split( /,/, $knn[ $i + 3 ] );
          chomp(@pred);
          my @matches = grep { $_ eq "1" } @pred;
          my $one_length = scalar(@matches);
          print OUTPUT
          "#Number of binding residues predicted by HomPRIP: $one_length\n";
          $svm[ $i + 2 ] =~ s/[\r\n\f\t]//g;
          $svm[ $i + 2 ] = substr( $svm[ $i + 2 ], 11 );
          @pred = split( /,/, $svm[ $i + 2 ] );
          chomp(@pred);
          @matches = grep { $_ eq "1" } @pred;
          $one_length = scalar(@matches);
          print OUTPUT
          "#Number of binding residues predicted by SVM: $one_length\n";
          $rbplus[ $i + 2 ] =~ s/[\r\n\f\t]//g;
          $rbplus[ $i + 2 ] = substr( $rbplus[ $i + 2 ], 11 );
          @pred = split( /,/, $rbplus[ $i + 2 ] );
          chomp(@pred);
          @matches = grep { $_ eq "1" } @pred;
          $one_length = scalar(@matches);
          print OUTPUT
"#Number of binding residues predicted by RNABindRPlus: $one_length\n";
          chomp( $rbplus[$i] );
          $rbplus[$i] =~ s/[\r\s\n\f]//g;
          print OUTPUT "$rbplus[$i]\n";
          my $sequence = join( ',', @seq );
          print OUTPUT "sequence:\t\t\t\t\t\t\t$sequence\n";

          #$knn[$i+3] =~ s/[\r\n\f\t]//g;
          #$knn[$i+3] = substr($knn[$i+3],11);
          $knn[ $i + 2 ] =~ s/[\r\n\f\t]//g;
          $knn[ $i + 2 ] = substr( $knn[ $i + 2 ], 17 );
          print OUTPUT "Prediction from HomPRIP:\t\t\t$knn[$i+3]\n";
          print OUTPUT "Predicted score from HomPRIP:\t\t$knn[$i+2]\n";

          #$svm[$i+2] =~ s/[\r\n\f\t]//g;
          #$svm[$i+2] = substr($svm[$i+2],11);
          $svm[ $i + 3 ] =~ s/[\r\n\f\t]//g;
          $svm[ $i + 3 ] = substr( $svm[ $i + 3 ], 16 );
          print OUTPUT "Prediction from SVM:\t\t\t\t$svm[$i+2]\n";
          print OUTPUT "Predicted score from SVM:\t\t\t$svm[$i+3]\n";

          #$rbplus[$i+2] =~ s/[\r\n\f\t]//g;
          #$rbplus[$i+2] = substr($rbplus[$i+2],11);
          $rbplus[ $i + 3 ] =~ s/[\r\n\f\t]//g;
          $rbplus[ $i + 3 ] = substr( $rbplus[ $i + 3 ], 16 );
          print OUTPUT "Prediction from RNABindRPlus:\t\t$rbplus[$i+2]\n";
          print OUTPUT "Predicted score from RNABindRPlus:\t$rbplus[$i+3]\n";
    }
    close(OUTPUT);
}

if ( $length < $homlength ) {
    for ( my $i = 0 ; $i < $length - 3 ; $i = $i + 4 ) {

        #print OUTPUT "$rbplus[$i]";
        #print OUTPUT "$rbplus[$i+1]";
        chomp( $rbplus[ $i + 1 ] );
        my @temp = split( /\s+/, $rbplus[ $i + 1 ] );
        chomp(@temp);
        my @seq = split( //, $temp[1] );
        chomp(@seq);
        my $length = scalar(@seq);
        print OUTPUT "#Input sequence length: $length\n";
        chomp( $rbplus[$i] );
        $rbplus[$i] =~ s/[\r\s\n\f]//g;
        print OUTPUT "$rbplus[$i]\n";
        my $sequence = join( ',', @seq );
        print OUTPUT "sequence:\t\t\t\t\t\t\t$sequence\n";
        $svm[ $i + 2 ] =~ s/[\r\n\f\t]//g;
        $svm[ $i + 2 ] = substr( $svm[ $i + 2 ], 11 );
        $svm[ $i + 3 ] =~ s/[\r\n\f\t]//g;
        $svm[ $i + 3 ] = substr( $svm[ $i + 3 ], 16 );
        print OUTPUT "Prediction from SVM:\t\t\t\t$svm[$i+2]\n";
        print OUTPUT "Predicted score from SVM:\t\t\t$svm[$i+3]\n";
        $rbplus[ $i + 2 ] =~ s/[\r\n\f\t]//g;
        $rbplus[ $i + 2 ] = substr( $rbplus[ $i + 2 ], 11 );
        $rbplus[ $i + 3 ] =~ s/[\r\n\f\t]//g;
        $rbplus[ $i + 3 ] = substr( $rbplus[ $i + 3 ], 16 );
        print OUTPUT "Prediction from RNABindRPlus:\t\t$rbplus[$i+2]\n";
        print OUTPUT "Predicted score from RNABindRPlus:\t$rbplus[$i+3]\n";

    }
    for ( my $i = 0 ; $i < $homlength - 3 ; $i += 4 ) {
        print OUTPUT "$knn[$i]";
        $knn[ $i + 1 ] =~ s/[\r\n\f\t]//g;
        print OUTPUT "sequence:\t\t$knn[$i+1]\n";
        $knn[ $i + 3 ] =~ s/[\r\n\f\t]//g;
        $knn[ $i + 3 ] = substr( $knn[ $i + 3 ], 11 );
        $knn[ $i + 2 ] =~ s/[\r\n\f\t]//g;
        $knn[ $i + 2 ] = substr( $knn[ $i + 2 ], 17 );
        print OUTPUT "Prediction from HomPRIP:\t\t\t$knn[$i+3]\n";
        print OUTPUT "Predicted score from HomPRIP:\t\t$knn[$i+2]\n";

    }
}
print LOG
  "Final predictions $jobID have been generated and put into $outputFL.\n ";
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
sub createARFF {
    my $jobID = shift @_;
    our $dataDIR;
    my $jobDIR = "$dataDIR/$jobID";
    my $KNNFL  = "$jobDIR/predictionsFor$jobID.KNN.txt";
    my $SVMFL  = "$jobDIR/predictionsFor$jobID.SVM.txt";

    open( F, "<$KNNFL" )
      or die "Can't open file: '" . $KNNFL . "', Reason $!\n";
    my @homprip = <F>;
    close(F);

    open( F, "$SVMFL" ) or die "Can't open file: '" . $SVMFL . "', Reason $!\n";
    our @svm = <F>;
    close(F);

    my $pdbid;
    my $length        = scalar(@homprip);
    my @homprip_score = ();
    my @svm_score     = ();
    my @actual        = ();
    my $arffDIR       = "$jobDIR/arff_files/HomPRIP_SVM";
    mkdir $arffDIR || die("Cannot mkdir $arffDIR:$!");

    for ( my $i = 0 ; $i < ( $length - 3 ) ; $i = $i + 4 ) {
        $svm[$i] =~ s/[\r\n\f\t]//g;

        #$pdbid = substr($homprip[$i],1,6);
        $pdbid = substr( $svm[$i], 1 );
        open( OUT, ">" . $arffDIR . "/" . $pdbid . ".arff" );
        $homprip[ $i + 2 ] =~ s/[\r\n\f\t]//g;
        $homprip[ $i + 2 ] = substr( $homprip[ $i + 2 ], 17 );
        @homprip_score = split( /,/, $homprip[ $i + 2 ] );
        $svm[ $i + 3 ] =~ s/[\r\n\f\t]//g;
        $svm[ $i + 3 ] = substr( $svm[ $i + 3 ], 16 );
        @svm_score = split( /,/, $svm[ $i + 3 ] );
        @actual = ();

        for ( my $j = 0 ; $j < scalar(@homprip_score) ; $j++ ) {
            push( @actual, '?' );
        }
        print OUT "\@relation RB44dataset\n";
        print OUT "\@attribute HomPRIP numeric\n";
        print OUT "\@attribute SVMscore numeric\n";
        print OUT "\@attribute class {0,1}\n";
        print OUT "\@data\n";
        for ( my $k = 0 ; $k < scalar(@homprip_score) ; $k++ ) {
            print OUT "$homprip_score[$k],$svm_score[$k],$actual[$k]\n";
        }
        close(OUT);
    }
    print LOG "Arff file for RNABindRPlus prediction created\n";
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------
sub callRNABindRPlus {
    use strict;

    our $JavahomeDIR;
    our $cgiDIR;
    our $wekaDIR;    #Uses weka 3.5.8
    my @qrys4SVM = @{ shift @_ };
    my $arffDIR  = shift @_;

    my $model = "$wekaDIR/RNABindRPlus.model";

    my $classPath  = "$wekaDIR/weka_newer.jar";
    my $classifier = "weka.classifiers.functions.Logistic";

    #load model and predict
    foreach my $qryID (@qrys4SVM) {

        print LOG "\nPredicting $qryID using RNABindRPlus...\n";

        my $outputFL = "$arffDIR/$qryID.weka.RNABindRPlus.prediction";
        my $testFL   = "$arffDIR/$qryID.arff";
        my $command = "$JavahomeDIR/java -Xmx5000m -cp $classPath $classifier  -l $model -T $testFL -p 0 -distribution > $outputFL";
        print LOG "\nRNABindPlus part\n";
        print LOG "$command\n";
        #predict
        system(
"$command"
        )==0 or die ("FAILED: $command:$!");    #-cp: set up CLASSPATH for weka

        print LOG "$outputFL generated.\n";
    }
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
sub extractPredictions {

    #!/usr/bin/perl -w

    use strict;
    use File::Copy;
    use File::Basename;

    my @taskIDs = @{ shift @_ };
    my $arffDIR = shift @_;
    my $jobDIR  = shift @_;

    print LOG "\n\nExtracting weka prediction results for RNABindRPlus...\n\n";

    #	close LOG;

    #read weka result file
    my $p;
    foreach my $taskID (@taskIDs) {
        my $wekaOutputFL = "$arffDIR/$taskID.weka.RNABindRPlus.prediction";
        my $prediction = &readWekaOutputFL_again($wekaOutputFL);    #array ref
        $p->{$taskID} = $prediction;

    }

    foreach my $taskID (@taskIDs) {

        #write the orginal weka output file into $predictionFL
        my $predictionResultsDIR = "$jobDIR/$taskID/predictionResults";

        mkdir($predictionResultsDIR) if ( !-d $predictionResultsDIR );
        my ($seq);
        my $seqFL = "$jobDIR/$taskID/$taskID.fasta.txt";
        $seq = &readFastaFL($seqFL);
        my $predictionFL =
          "$jobDIR/$taskID/predictionResults/$taskID.RNABindRPlus.prediction";
        my $predictionScore = $p->{$taskID};

        &writePredictionFL_SVM( $taskID, $seq, $predictionScore,
            $predictionFL );

    }

}

#-------------------------------------------------------------------------------------------------------------------------------------------------------------
sub writeFullLst {

    my @taskIDs  = @{ shift @_ };
    my $outputFL = shift @_;

    unlink $outputFL if ( -e $outputFL );
    open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL:$!");

    foreach (@taskIDs) {
        print OUTPUT "$_\n";

    }
    close OUTPUT;

}

#---------------------------------------------------------------------------------
sub getQrys4SVM {

    #read qry IDs that cannot be predicted by NPS-HomPRIP
    #These qry will be predicted by SVM.
    use strict;
    our $safe_filename_characters;
    my $qryHomFL = shift @_;

    #	my $logFL =shift @_;

    #	open(LOG, ">>$logFL")||die("Cannot open $logFL:$!");
    print LOG "Extracting Qrys for SVM..\n";

    #	close LOG;

    my @qryProtIDs;
    open( INPUT, "<$qryHomFL" )
      || die("Cannot open $qryHomFL:$!");
    foreach (<INPUT>) {

        #1b23P
        #1di2A

        s/[\n\r]//mg;
        if (/^[$safe_filename_characters]+$/) {
            my $qryProtID = $_;

            #			print "$qryProtID\n";
            push @qryProtIDs, $qryProtID;
        }

    }
    close INPUT;

    return @qryProtIDs;

}

#-----------------------------------------
sub writeQry4SVM {
    use strict;

    #Output file format is required by Cornelia's code
    #format example :
    #1asy_A
    #EDTAKDNYGKLPLIQSRDSDRTGQKRVKFVDLDEAKDSDKEV
    #??????????????????????????????????????????

    our $safe_filename_characters;
    my @qryProtIDs = @{ shift @_ };
    my $qryFL4SVM  = shift @_;
    my $jobDIR     = shift @_;        #dirname($qryWoSafeTwiDkHomFL);

    #	my $logFL = shift @_;

    unlink $qryFL4SVM if ( -e $qryFL4SVM );

    #read fasta file of qry and write it to the file of $qryFL4SVM
    open( OUTPUT, ">>$qryFL4SVM" ) || die("Cannot open $qryFL4SVM:$!");
    foreach my $qryProtID (@qryProtIDs) {
        my $fastaFL = "$jobDIR/$qryProtID/$qryProtID.fasta.txt";
        open( INPUT, "<$fastaFL" ) || die("Cannot open $fastaFL:$!");
        my $count = 0;
        foreach (<INPUT>) {
            s/[\n\r]//mg;

            #if (/>([$safe_filename_characters]+)$/) {
            if (/>(.+)/) {

                #header line
                #s/[^$safe_filename_characters]/_/g;
                #print OUTPUT "$1\n";
                print OUTPUT "$qryProtID\n";
                next;
            }
            if (/^[a-zA-Z]+/) {
                my $seq = $_;
                $seq=~s/\s+//g;

                my $questionMrk = '?' x length($seq);
                print OUTPUT "$seq\n";
                print OUTPUT "$questionMrk\n";
            }
        }
        close INPUT;
    }
    close OUTPUT;

    #	open (LOG, ">$logFL")||die("Cannot open $logFL:$!");
    print LOG "Input file for SVM: $qryFL4SVM generated.\n";

    #	close LOG;
}

#-------------------------------------------------------------
sub genPSSM {
    use strict;
    use File::Path;

    my $evalue   = 0.001;
    my @qrys4SVM = @{ shift @_ };
    my $jobDIR   = shift @_;
    our $BlastDIR;
    our $nrDB;
    our $psiblast;

    #	my $BlastDIR = '/home/ppidev/tools/ncbi-blast-2.2.25+';
    #	my $psiblast = "$BlastDIR/bin/psiblast";
    #	my $nrDB = "$BlastDIR/db/nr";;    #="C:\blast-2.2.25-ia32-win32\db\nr";

    my $r       = rand(1);
    my $tmpFL   = "$r.psiblast.out";
    my $PSSMdir = "$jobDIR/pssms";
    rmtree($PSSMdir) if ( -d $PSSMdir );
    mkdir $PSSMdir || die("Cannot mkdir $PSSMdir:$!");

    my @qrywithPSSM;

    foreach my $qryID (@qrys4SVM) {
        print LOG "\nCalculating PSSM for $qryID...\n\n";
        my $fastaFL = "$jobDIR/$qryID/$qryID.fasta.txt";
        my $pssmFL  = "$PSSMdir/$qryID.pssm";

        unlink $pssmFL if ( -e $pssmFL );
        print LOG
"$psiblast -query $fastaFL -db $nrDB -out $tmpFL -evalue $evalue  -outfmt 10 -num_iterations 3 -out_ascii_pssm $pssmFL\n";

        my $command =
"$psiblast -query $fastaFL -db $nrDB -out $tmpFL -evalue $evalue -outfmt 10 -num_iterations 3 -out_ascii_pssm $pssmFL";

        system("$command") == 0 or die("FAILED: $command:$!");
        unlink $tmpFL;    #we do not need tmpFL.

        if ( -e $pssmFL && -s $pssmFL ) {
            print LOG "$pssmFL generated. \n";
            push @qrywithPSSM, $qryID;
        }
        else {
            print LOG "Error: $pssmFL NOT generated.\n";
        }
    }

    return @qrywithPSSM;

}

#--------------------------------------------------------------------------------
sub genARFF {
    use strict;
    use Cwd;
    use File::Path;
    our $genARFFjarDIR;
    our $JavahomeDIR;

    my $qryFL4SVM = shift @_;
    my $jobDIR    = shift @_;

    my $PSSMdir = "$jobDIR/pssms/";
    my $arffDIR = "$jobDIR/arff_files/";


    my $cwd = cwd;
    chdir $genARFFjarDIR;

    rmtree $arffDIR if ( -d $arffDIR );
    mkdir($arffDIR) || die("Cannot makedir $arffDIR:$!");

    my $r     = rand(1);
    my $tmpFL = "$jobDIR/genARFFjar.out";

    my $command ="$JavahomeDIR/java -jar getARFF_new.jar $PSSMdir $qryFL4SVM  $arffDIR >$tmpFL";

    system("$command") == 0 or die ("FAILED: $command :$!");

    print LOG "Arffs are put in $arffDIR. \n";

    chdir $cwd;

}

#------------------------------------------------------------------------------------------
sub callSVM {
    use strict;

    #Use trained SVM model to predict.
    #SVM model is trained using rb199 with PSSM profiles.

    our $cgiDIR;
    our $wekaDIR;
    our $JavahomeDIR;
    my @qrys4SVM = @{ shift @_ };
    my $arffDIR  = shift @_;

    my $SVMmodel = "$wekaDIR/svmrbf_new.model";

    #my $SVMmodel = "$wekaDIR/svmrbf_3.6.4.model";

    my $classPath  = "$wekaDIR/weka_new.jar";
    my $classifier = "weka.classifiers.functions.SMO";

    #load model and predict
    foreach my $qryID (@qrys4SVM) {

        print LOG "\nPredicting $qryID using SVM...\n";

        my $outputFL   = "$arffDIR/$qryID.weka.SVM.prediction";
        my $testFL     = "$arffDIR/$qryID.arff";
        my $testFL_new = "$arffDIR/$qryID.new.arff";

        if ( -e $testFL && -s $testFL ) {

            #remove the sequence ID from the test arff file
            system(
"$JavahomeDIR/java -Xmx2096m -cp $classPath weka.filters.unsupervised.attribute.Remove -R 1 -i $testFL -o $testFL_new"
            );

            #predict
            system(
"$JavahomeDIR/java -Xmx5000m -cp $classPath $classifier  -l $SVMmodel -T $testFL_new -p 0 -distribution > $outputFL"
            );    #-cp: set up CLASSPATH for weka

            print LOG "$outputFL generated.\n";
        }
        else {
            print LOG
"No arff file corresponding to $qryID. Most likely no PSSM file generated. $outputFL NOT generated\n";
        }

    }

    #	close LOG;

}

#-------------------------------------------------------------------------------------------------
sub extractPredictWeka2 {

    #!/usr/bin/perl -w

#Author: Xue, Li
#Date: Mar. 6th, 2007
#This script is part of Protein-Protein interface prediction using customized training dataset
#
#this script is used to extract the prediction score from the output of weka
#
#Input: a file that is generated by callWeka.pl, e.g., wekaResult_winsize9.out1
#Output file $predictionFL:
#                >1xdtT
#                GADDVVDSSKSFVMENFSSYHGTKPGYVDSIQKGIQKPKSGTQGNYDDDWKGFYSTDNKYDAAGYSVDNENPLSGKAGGVVKVTYPGLTKVLALKVDNAETIKKELGLSLTEPLMEQVGTEEFIKRFGDGASRVVLSLPFAEGSSSVEYINNWEQAKALSVELEINFETRGKRGQDAMYEYMAQACAGNRVRRSVGSSLSCINLDWDVIRDKTKT
#predicted:      ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.1,0,?,?,?,0.333333333333333,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.5,0,0,0.9,0,0.9,0.1,0.7,0,0,0.7,0.9,0.9,0.9,0
#
#Usage: ./extractPredictWeka.pl original_weka_outputfile.out1
#e.g., perl ./extractPredictWeka2.pl

    use strict;
    use File::Copy;
    use File::Basename;

    #	use myfun;

    my @taskIDs = @{ shift @_ };
    my $arffDIR = shift @_;
    my $jobDIR  = shift @_;

    print LOG "\n\nExtracting weka prediction results...\n\n";

    #	close LOG;

    #read weka result file
    my $p;
    foreach my $taskID (@taskIDs) {
        my $wekaOutputFL = "$arffDIR/$taskID.weka.SVM.prediction";
        my $prediction   = &readWekaOutputFL($wekaOutputFL);         #array ref
        $p->{$taskID} = $prediction;

    }

    foreach my $taskID (@taskIDs) {

        #write the orginal weka output file into $predictionFL
        my $predictionResultsDIR = "$jobDIR/$taskID/predictionResults";

        mkdir($predictionResultsDIR) if ( !-d $predictionResultsDIR );
        my ($seq);
        my $seqFL = "$jobDIR/$taskID/$taskID.fasta.txt";
        $seq = &readFastaFL($seqFL);
        my $predictionFL =
          "$jobDIR/$taskID/predictionResults/$taskID.SVM.prediction";
        my $predictionScore = $p->{$taskID};

        &writePredictionFL_SVM( $taskID, $seq, $predictionScore,
            $predictionFL );

    }

}

#-------------------------------------------------------------------------------
sub readWekaOutputFL {
    use strict;
    my $inputfile = shift @_;
    my @prediction;

    #program begin

 #extract the 2nd column of the input file, which is the weka prediction results
    open( INPUT, "<$inputfile" ) || die("Cannot open $inputfile:$!");
    foreach (<INPUT>) {
        s/[\n\r]//mg;
        if (/^[\s\t]+\d+/)    #find the 2nd column of the input file
        {
            #=== Predictions on test data ===
            #
            # inst#     actual  predicted error distribution
            #     1        1:?        2:0   +   0.002,*0.998
            #     2        1:?        2:0   +   0.003,*0.997
            #     3        1:?        2:0   +   0,*1
            #     4        1:?        2:0   +   0,*1
            #     5        1:?        2:0   +   0,*1

            my @a = split( /[\s\t]+/, $_ );
            my @b = split( /[,\*]+/,  $a[-1] );

            my ($predictionScore) =
              $a[-1] =~ /^\*{0,1}([\d\.\-]+),/;    #$a[-1]=0.002,*0.998

            #			my $actual          = $a[3];

            push( @prediction, $predictionScore );
        }
    }
    close(INPUT);
    return \@prediction;
}

#------------------------------------------------------------------------------------------------------------------------------------
sub readWekaOutputFL_again {
    use strict;
    my $inputfile = shift @_;
    my @prediction;

    #program begin

 #extract the 2nd column of the input file, which is the weka prediction results
    open( INPUT, "<$inputfile" ) || die("Cannot open $inputfile:$!");
    foreach (<INPUT>) {
        s/[\n\r]//mg;
        if (/^[\s\t]+\d+/)    #find the 2nd column of the input file
        {
            #=== Predictions on test data ===
            #
            # inst#     actual  predicted error distribution
            #     1        1:?        2:0   +   0.002,*0.998
            #     2        1:?        2:0   +   0.003,*0.997
            #     3        1:?        2:0   +   0,*1
            #     4        1:?        2:0   +   0,*1
            #     5        1:?        2:0   +   0,*1

            my @a = split( /[\s\t]+/, $_ );
            my @b = split( /[,\*]+/,  $a[-1] );

            my ($predictionScore) =
              $a[-1] =~ /^\*{0,1}([\d\.\-]+),/;    #$a[-1]=0.002,*0.998

            #			my $actual          = $a[3];

            push( @prediction, ( 1 - $predictionScore ) );
        }
    }
    close(INPUT);
    return \@prediction;
}

#-----------------------------------------------------------------------------------------------------------------------------------
sub writePredictionFL_SVM {
    use strict;
    my $taskID          = shift @_;
    my $seq             = shift @_;
    my @predictionScore = @{ shift @_ };
    my $outputFL        = shift @_;
    my $scoreCutOff     = 0.5;
    my @rounded;
    for ( my $i = 0 ; $i < scalar(@predictionScore) ; $i++ ) {
        my $temp = sprintf( "%.2f", $predictionScore[$i] );
        push( @rounded, $temp );
    }
    my $predictions = join( ',', @rounded );
    my $prediction = &getBinaryPrediction( $predictions, $scoreCutOff );

    unlink $outputFL if ( -e $outputFL );
    open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL:$!");
    print OUTPUT "\t\t\t>$taskID\n";
    print OUTPUT "sequence:\t\t$seq\n";
    print OUTPUT "prediction:\t\t$prediction\n";
    close OUTPUT;

    open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL:$!");
    print OUTPUT "predicted score:\t$predictions\n";
    close(OUTPUT);

    print LOG "$outputFL generated.\n";

}

#-------------------------------------------------------------------------------------------
sub readFastaFL {
    my $fastaFL = shift @_;
    my $seq     = '';

    open( FL, "<$fastaFL" ) || die("Cannot open $fastaFL:$!");
    foreach (<FL>) {
        s/[\n\r]//mg;
        if (/^[a-zA-Z]+$/) {
            $seq = $seq . $_;
            next;
        }
    }
    close FL;
    return $seq;
}

#--------------------------------------------------------------------------------------
sub collectPredictionFLsIntoOneFL {

    #perl ./collectPredictionFLsIntoOneFL.pl $lstFL
    #perl ./collectPredictionFLsIntoOneFL.pl ../data/dockingTestSet.fasta

    use strict;
    use File::Basename;

    my $jobID   = shift @_;
    my @taskIDs = @{ shift @_ };

    #	my $logFL   = shift @_;
    our $dataDIR;
    my $jobDIR   = "$dataDIR/$jobID";
    my $outputFL = "$jobDIR/predictionsFor$jobID.txt";
    my $predictFL;

    #my $pdbID;
    #my $chainID;
    my $taskID;
    our $safe_filename_characters;

    #process each task ID
    unlink($outputFL) if ( -e $outputFL );
    open( OUTPUT, ">>$outputFL" );
    foreach (@taskIDs) {
        if ( -f "$jobDIR/$_" ) {

            #		print "$_ is a file.\n";
            next;
        }
        else {
            if ( /^([$safe_filename_characters]+)$/ && /^[^\.]{0,}$/ ) {
                $taskID = $_;
                $predictFL =
"$jobDIR/$taskID/predictionResults/$taskID.RNABindRPlus.prediction";

                open( PREDIC, "<$predictFL" )
                  || die("Cannot open $predictFL:$!");
                foreach (<PREDIC>) {
                    s/[\n\r]//mg;

                    print OUTPUT "$_\n";
                }
                close(PREDIC);
            }
        }
    }
    close(OUTPUT);
    print LOG
      "All predictions for proteins in $jobID are put into $outputFL.\n ";
}

#-----------------------------------------------------------------------------------------------------------------------
sub collectPredictionFLsIntoOneFLSVM {

    #perl ./collectPredictionFLsIntoOneFL.pl $lstFL
    #perl ./collectPredictionFLsIntoOneFL.pl ../data/dockingTestSet.fasta

    use strict;
    use File::Basename;

    my $jobID   = shift @_;
    my @taskIDs = @{ shift @_ };

    #	my $logFL   = shift @_;
    our $dataDIR;
    my $jobDIR   = "$dataDIR/$jobID";
    my $outputFL = "$jobDIR/predictionsFor$jobID.SVM.txt";
    my $predictFL;

    #my $pdbID;
    #my $chainID;
    my $taskID;
    our $safe_filename_characters;
    my $predictFL_SVM;

    # 	#read taskIDs
    # 	opendir( my $dir, $jobDIR ) || die("cannot open $jobDIR!\n");
    # 	my @taskIDs = readdir($dir);
    # 	my @dots = grep { -f "$jobDIR/$_" } readdir($dir);
    # 	closedir($dir);

    #process each task ID
    unlink($outputFL) if ( -e $outputFL );
    open( OUTPUT, ">>$outputFL" );
    foreach (@taskIDs) {
        if ( -f "$jobDIR/$_" ) {
            next;
        }
        else {
            if ( /^([$safe_filename_characters]+)$/ && /^[^\.]{0,}$/ ) {
                $taskID = $_;
                $predictFL_SVM =
                  "$jobDIR/$taskID/predictionResults/$taskID.SVM.prediction";

                if ( -e $predictFL_SVM ) {

#if there is $predictFL_SVM, SVM is used to make prediction, and the predictions in $predictFL_KNN are all question marks.
                    $predictFL = $predictFL_SVM;
                }
                open( PREDIC, "<$predictFL" )
                  || die("Cannot open $predictFL:$!");
                foreach (<PREDIC>) {
                    s/[\n\r]//mg;

                    print OUTPUT "$_\n";
                }
                close(PREDIC);
            }
        }
    }
    close(OUTPUT);

    #	open( LOG, ">>$logFL" ) || die("Cannot open $logFL.\n");
    print LOG
      "All predictions for proteins in $jobID are put into $outputFL.\n ";

    #	close LOG;
}

#-------------------------------------------------------------------------------------------------------------------
sub collectPredictionFLsIntoOneFLKNN {
    use strict;
    use File::Basename;

    my $jobID   = shift @_;
    my @taskIDs = @{ shift @_ };
    our $dataDIR;
    my $jobDIR          = "$dataDIR/$jobID";
    my $outputFL        = "$jobDIR/predictionsFor$jobID.KNN.txt";
    my $homologoutputFL = "$jobDIR/homologsFor$jobID.txt";
    my $predictFL;
    my $homologFL;
    my $taskID;
    my $pdbID;
    my $chainID;
    our $safe_filename_characters;
    my $predictFL_KNN;

    #process each task ID
    unlink($outputFL)        if ( -e $outputFL );
    unlink($homologoutputFL) if ( -e $homologoutputFL );
    open( OUTPUT, ">>$outputFL" );
    open( OUT,    ">>$homologoutputFL" );
    foreach (@taskIDs) {
        if ( -f "$jobDIR/$_" ) {
            print "$_ is a file.\n";
            next;
        }
        else {
            if ( /^([$safe_filename_characters]+)$/ && /^[^\.]{0,}$/ ) {
                $taskID = $_;
                $predictFL_KNN =
                  "$jobDIR/$taskID/predictionResults/$taskID.KNN.prediction";
                $homologFL = "$jobDIR/$taskID/final_homologs.txt";

#if there is no $predictFL_SVM, it means HomPRIP is able to find homologs for this query. NB is not used to make predictions.
                $predictFL = $predictFL_KNN;
                open( PREDIC, "<$predictFL" )
                  || die("Cannot open $predictFL:$!");

                foreach (<PREDIC>) {
                    s/[\n\r]//mg;

                    print OUTPUT "$_\n";
                }
                close(PREDIC);
                open( HOMO, "<$homologFL" ) || die("Cannot open $homologFL:$!");
                print OUT "Homologs of: $taskID\n";
                foreach (<HOMO>) {
                    s/[\n\r]//mg;
                    print OUT "$_\n";
                }
                close(HOMO);
            }
        }
    }
    close(OUTPUT);

    #	open( LOG, ">>$logFL" ) || die("Cannot open $logFL.\n");
    print LOG
      "All predictions for proteins in $jobID are put into $outputFL.\n ";
    print LOG
      "All homologs for proteins in $jobID are put into $homologoutputFL.\n";

    #	close LOG;
}


#-------------------------------------------------------------------------------------------------------------------
# GETBINARYPREDICTION FUNCTION
#-------------------------------------------------------------------------------------------------------------------
sub getBinaryPrediction {
    my $predictionScore = shift @_;    #'0.25,0.25,0.25,0'
    my $scoreCutoff     = shift @_;
    my @pred            = ();

    if ( $predictionScore =~ /^[\d\.\-e\,\?]+$/ ) {
        my @scores = split( /,/, $predictionScore );
        my $string = '';
        foreach my $score (@scores) {

            if ( $score eq '?' ) {
                $string = '?';
                push( @pred, $string );
            }
            elsif ( $score >= $scoreCutoff ) {
                $string = '1';
                push( @pred, $string );
            }
            else {
                $string = '0';
                push( @pred, $string );
            }
        }

        #double check
        # if ( length($prediction) ne scalar @scores ) {
        # die(
        # "Binary prediction and prediction scores have different lengths:$!"
        # );
        # }

    }
    my $prediction = join( ',', @pred );
    return $prediction;

}

#-------------------------------------------------------------------------------------------------------------------
sub conservAnalysis {

    #!usr/bin/perl -w

#author: Xue, Li
#date: 2/5/2010
#This script is part of the pipe line of HomoPPI
#To do PPI conservation analysis
#Input:
# query list: a list of PDB ID and chain IDs, e.g., "..\data\nr6505.txt"
# 2. database list: a list of PDB ID and chain IDs, e.g., "..\data\all102853.txt"
#Output:  "..\data\statistics.txt"
#output format:
#>query1 pdbID chainID:
#PDBID+CHAINID Bit_score Positive_Score IdentityScore aligLen_Query aligLen_Homolog CC TP TN FP FN
#...
#>query2
#...
#
    use strict;
    use File::Basename;
    use File::Copy;

    our $HomeDIR;
    our $dataDIR;
    my $intNum_cutoff = 3;

    #variables
    my $inputFL     = shift @_;
    my $Evalue      = shift @_;
    my $PostiveSThr = shift @_;

    #my $alignLengthThr = shift @ARGV;
    #	my $intDef      = shift @_;    #
    my $atomDistThr = shift @_;

    #	my $rasaThr     = shift @_;
    my $FLAG = shift @_; #1 and 2: user input fasta file. 3: user input PDB IDs.
    my @taskIDs        = @{ shift @_ };
    my $rmSameProtFlag = shift @_;        #'Yes'  or 'No'
    print LOG " FLAG = $FLAG\n\n";
    print LOG " rmSameProtFlag = $rmSameProtFlag\n";

    my ( $name, $path, $suffix ) = fileparse( $inputFL, ( '.txt', '.lst' ) );

    my $pdbID;
    my $chainID;
    my $taskID;

    #my @taskIDs;

    #my $seq_interface_QryLstFL = "$dataDIR/seq_int_$basename.lst";
    my $jobID = basename( $inputFL, ( '.fasta', '.lst', '.txt' ) );
    my $jobDIR = "$dataDIR/$jobID";    #all the data for a submission job
    my $statFL   = "$jobDIR/statistics\_$jobID.txt";
    my $outputFL = $statFL;

    #--------------------------------------------------------------#
    #program begins

    print LOG "In ConservAnalysis function\n";

    foreach (@taskIDs) {
        $taskID = $_;

        print LOG
"\n\n-----------------------------------------------------------------------\n\n";
        print LOG
"\tNow collect alignment statistics for each homologs of taskID: $taskID";
        print LOG
"\n\n-----------------------------------------------------------------------\n\n";

        #		close LOG;

        #---------- File variables
        my $ProteinToBePredictedDIR =
          "$jobDIR/$taskID";    #each query is given a specific directory
        my $predictionResultsDIR = "$ProteinToBePredictedDIR/predictionResults";

        #	my $logFL                   = "$ProteinToBePredictedDIR/$taskID.log";
        my $actualIntFL   = "$ProteinToBePredictedDIR/$taskID.int";
        my $BlastOutputFL = "$ProteinToBePredictedDIR/$taskID.blast";
        my $PPIDBoutputFL =
          "$ProteinToBePredictedDIR/seq_int_homologsOfquerySeq.lst";
        my $localAlignFastaFL =
          "$ProteinToBePredictedDIR/seq_int_homologsOfquerySeq.localAlign"
          ; #the aligned part of homologs with query sequence. This file is written in a fasta format, and contains sequence and interface.
        my $statPredFL   = "$predictionResultsDIR/prediction.stat";
        my $homologLstFL = "$ProteinToBePredictedDIR/homologsOfquerySeq.lst"
          ;    #the output file of parse_blast.pl

        my $fastaFL = "$taskID.fasta.txt";
        $fastaFL = "$ProteinToBePredictedDIR/$fastaFL";

        #----------------------------#
        # PART I: BLASTp + PPIDB
        #----------------------------#

        &callBlastp( $fastaFL, $BlastOutputFL, $Evalue )
          ;    #Blast the query against PDB database
        &parse_blastp_pdb( $BlastOutputFL, $PostiveSThr )
          ; #parse the homologs' PDBID from the resulting blast file, and write them into a list as the input of PPIDB

        #		&callPPIDB( $homologLstFL, $intDef, $atomDistThr, $rasaThr, $logFL );
        &getIntSeqFromFullDB( $homologLstFL, $atomDistThr );

        &rmChainsWithLessThan5intAA( $intNum_cutoff, $PPIDBoutputFL )
          ;    #remove chains < $intNum_cutoff interfaces

        &localAlignFastaGen2( $PPIDBoutputFL, $BlastOutputFL )
          ;   #generate localAlignment Fasta file for homologs returned by PPIDB
        print LOG "done with for loop....\n";
    }

    #collect the alignment statistics for each homolog
    print LOG "Starting collectStat function!\n";
    &collectStat( \@taskIDs, $jobDIR, $outputFL );
    print LOG "Done with collectStat function\n";
    if ( $rmSameProtFlag =~ /Yes/ ) {
        &rmSimilarProt($statFL);
    }
    return \@taskIDs;
    print LOG "End ConservAnalysis function\n";
}

#------------------------------------------------------------------------------------------------------------------------------
sub callBlastp {

#Author: Xue, Li
#date: Jun, 2008
#
#This script is part of RNA-protein interface prediction
#
#This script is to call Blastp to get the homologs of input with user defined E cutoff value
#Usage: perl ./callBlast.pl query_protein(s).fasta outputfile.blast Evalue
#e.g.,
#perl ./callBlastp.pl ../data/1A9NB/1A9N_B.fasta.txt ../data/1A9NB/1A9N_B.blast 10

    #note: the PDB database which is blasted on is updated by Mar. 21st, 2007
    #note: multiple fasta files could be put in a single file

    #use CGI ":standard";

    #todo: check for the number of input arguments

    #Variables
    use strict;

    my $queryFastaFile = shift @_;
    my $outputFile     = shift @_;
    my $Evalue         = shift @_;

    #	my $logFL          = shift @_;
    our $BlastDIR;
    our $BlastDataset
      ; #'../data/nr_pdbaa_s2c/nr_pdbaa_s2c';#non-redundant protein dataset from S2C fasta file

    #Directoriesm
    my $blastBinDIR = "$BlastDIR/bin";    #where BLAST is installed

    #program begin

    if ( !-e $queryFastaFile ) {
        die("$queryFastaFile does not exist:$!");
    }

    my $command =
"$blastBinDIR/blastp -db \"$BlastDataset\" -query $queryFastaFile  -evalue $Evalue -out $outputFile";

    our $ENVpath;
    $command =~ /(.*)/;
    $command = $1;
    $ENV{'PATH'} = '';

    # 	open( LOG, ">>$logFL" ) || die("Cannot open $logFL.\n");
    # 	print LOG "$command";#xue
    # 	close LOG;

    system("$command")==0 or die ("FAILED: $command:$!");    #-F F: low complexicity filtering OFF


    $ENV{'PATH'} = $ENVpath;

    print LOG "$outputFile is generated. \n";

}

#-----------------------------------------------------------------------------------------------------------------------------------
sub parse_blastp_pdb {

#Author: Xue, Li
#Date: Mar. 2007
#Last modified: 2/20/2010
#
# Note: When chain ID is in lowercase, Blast will output double uppercase chainID
# For example: pdb|3KIX|LL  Chain l,  >pdb|2QNH|MM Chain m,  >pdb|3KIS|LL Chain ...   259    3e-70
# So we need to extract chain ID from "Chain l" part not from "pdb|3KIX|LL".

#This script is part of Protein-Protein interface prediction using customized training dataset
#parse pdb ID and chain No. from the BLAST result file, and write them into files, "homologsOfquerySeq.lst"
#user can specify the sequence similarity threshold
#
#note: This script deals with the format when Blast program blasts against pdb database. If *.blast is generated using Blast against user-defined database, please use parse_blastp_userDB.pl
#
#Usage: perl parse_blastp_pdb.pl filename.blast PositiveScoreThreshold
#e.g., perl ./parse_blastp_pdb.pl ../data/1a4yA/1a4yA.blast 0.75

    use strict;
    use File::Basename;

    #Variables
    my $inputfile        = shift @_;
    my $positiveScoreThr = shift @_;

    #	my $logFL            = shift @_;
    my $taskID = basename( $inputfile, '.blast' );

    # 	my $inputfilename = basename( $inputfile, '.blast' );
    my $outfilename;
    my $outfile;
    my $PDBID;
    my $chainID;
    my @homlog
      ; #to store the PDBID and chainID of homologs of query sequence returned Blastp
    my $positiveS;
    my $num_seq = 0;    #number of the homologs for each query sequence

    #directories

    my $taskDIR = dirname($inputfile);
    $outfilename = "homologsOfquerySeq.lst";    #define output file name
    $outfile     = "$taskDIR/$outfilename";

    #	open( LOG, ">>$logFL" ) || die("Cannot open $logFL.\n");
    open( BLASTOutputfile, "<$inputfile" ) or die("cannot  open $inputfile:$!");
    my $flag  = 0;    #flag for every query sequence
    my $flag1 = 0;    #flag for the first homolog of the query sequence
    my $flag2 = 0;    #flag for the similarity
    my $query;

    foreach my $line (<BLASTOutputfile>) {

        if ( $line =~ /^Query=[\s\t]{0,}([\w\-\.]+)/ ) {
            $flag  = 1;
            $query = $1;
        }
        if ( $flag == 1 && $line =~ /^Length=(\d+)/ )

          #	Query=  1a4yA
          #	Length=460
        {
            print LOG "The number of residues of query sequence $query: $1 \n";
            $flag = 0;
        }

        if ( $line =~ /No hits found/ ) {
            print LOG "No homologs found for $query\n";
            $num_seq = 0;
            last;
        }

        if (   $flag1 == 0
            && $line =~ /^>pdb/ )    #the homologs of this query sequence starts
        {

            unlink $outfile if ( -e $outfile );
            $flag1 = 1;              #the homologs of this query sequence starts

            #		$flag  = 0;    #reset the flag for every query sequence
        }

        if (   $flag1 == 1
            && $line =~ /^[>\s]{1}pdb\|([\da-zA-Z]{4})\|\w{1} Chain (\w+),/
          )    #  e.g., pdb|1A0O|A Chain A, Chey-Binding Domain
        {
            $PDBID   = $1;
            $chainID = $2;
            $PDBID =~ tr/A-Z/a-z/
              ; #change the PDBID into lower case, because the PDBID are stored as lower case in PPIDB
            push @homlog, [ $PDBID, $chainID ];
            $flag2 = 1;    #now let's check the similarity
            next;
        }

        if ( $line =~ /Positives = \d+\/\d+ \((\d+)%\)/
          )    # Identities = 106/106 (100%), Positives = 106/106 (100%)
        {
            $positiveS = $1 * 0.01;
            if ( $positiveS >= $positiveScoreThr ) #check the sequece similarity
            {
                open( OUTFILE, ">>$outfile" );
                for my $i ( 0 .. $#homlog ) {
                    $num_seq++;
                    print OUTFILE "$homlog[$i][0], $homlog[$i][1]\n";
                }
                close(OUTFILE);

                #			foreach my $row (@homlog)
                #			{
                #				print "@$row\n";
                #			}
            }
            @homlog = ();
        }
    }

    open( OUTFILE, ">>$outfile" );
    print OUTFILE
"#The number of homolog chains with >= Positive(similiarity) $positiveScoreThr is $num_seq\n";
    close(OUTFILE);
    print LOG "Parse blastp result file finish!  Outputfile: $outfile\n\n";

    #	close LOG;

}

#--------------------------------------------------------------------------------------------------------------------------------------------------------
sub getIntSeqFromFullDB {

#!usr/bin/perl -w
#Li Xue
#Apr. 2nd, 2010
#
#Format Ben's data into HOMRPI input format
#The coordinates of some residues are missing from pdb files. S2C database is used to map interface information to complete fasta sequences.
#
#input: a file with a list of query pdbIDs and chainIDs
#	For example,
#		1a81,A
#		1a81,E
#		1a81,G
#		1a81,I
#output: a fasta file with sequences and interfaces "seq_interface_$inputFile"
#	>query's pdbID_chainID
#	sequence
#	interface
#
#perl ./GenFullDatasetFL.pl list_of_pdbIDchainID disThr
#For example,
#perl ./getIntSeqFromFullDB.pl ../data/1AV6A/homologsOfquerySeq.lst 4
#perl ./getIntSeqFromFullDB.pl ../data/nr163.lst 4
#perl ./getIntSeqFromFullDB.pl ../data/rb203.lst 4
#perl ./getIntSeqFromFullDB.pl ../data/rb109.lst 4
#perl ./getIntSeqFromFullDB.pl ../data/rb199/rb199.lst 4
#perl ./getIntSeqFromFullDB.pl ../data/test.lst 4

    use strict;
    use File::Basename;

    our $HomeDIR;
    our $FullRPIDB
      ;    # "$HomeDIR/HOMRPI/PRIDB/resiDis";    #RNA_proteinDB, redundant
    our $s2cDIR;    #= "$HomeDIR/S2C";

    my $inputFL = shift @_;
    my $distThr = shift @_;

    #	my $logFL   = shift @_;
    print LOG "\nGet Int and seq for $inputFL\n";

    my $basename = basename( $inputFL, ( '.lst', '.fasta', '.txt' ) );
    my $dirname  = dirname($inputFL);
    my $outputFL = "$dirname/seq_int_$basename.lst";

    #program starts
    my $totalNum = 0; # Total number of queries
    my $num1     = 0; #number of queries in $outputFL
    my $num2     = 0; # number of queries that do not exist in Full RPI database
    my $num3     = 0
      ; # number of queries that exist in Full RPI but do not exist in s2c database

    #	open( LOG,   ">>$logFL" )  || die("Cannot open $logFL:$!");
    open( INPUT, "<$inputFL" ) || die("Cannot open $inputFL: $!");
    &header_outputFL( $outputFL, $distThr );

    foreach (<INPUT>) {
        s/[\n\r]//mg;

        if (/^(\w{4})[\s\t,]{0,}(\w{1})$/) {

            $totalNum++;

            my $PDBID    = uc($1);
            my $chainID  = $2;
            my $fl       = "$FullRPIDB/$PDBID\_$chainID";
            my $PDBID_lc = lc($PDBID);
            my $s2cFL    = $s2cDIR . "/$PDBID_lc.sc";
            my $interface;
            my $fastaSeq;

            print LOG
              "Searching full RPI database for ......  $PDBID $chainID\n";
            if ( !-e $fl ) {
                $num2++;
                print LOG
"$_ does not exist in Full RPI database.  (Full RPI database only contains proteins interacting with RNA within 8 angstroms).\n";
                next;

            }
            elsif ( !-e $s2cFL ) {
                $num3++;
                print LOG
"$_ does not exist in s2c database. s2c database needs update.\n";
                next;
            }
            else {
                $num1++;

                #read s2c files

                my ( $s2c_residues, $SEQRESresinum, $ATOMresinum ) =
                  &readS2Cfile( $PDBID, $chainID, $s2cDIR );
                $fastaSeq = join( '', @$s2c_residues );

                #get int residues
                my ( $int, $ATOMindex ) = &readRawinputFL( $fl, $distThr );

                if ( !defined $int ) {

                    #there is no interface for $PDBID, $chainID.
                    $interface = '0' x length($fastaSeq);
                }
                else {

                    #
                    my %int_atomResiNum;
                    @int_atomResiNum{@$ATOMindex} = @$int;

                    #
                    my $newInt =
                      &mapInt2fasta( \%int_atomResiNum, $s2c_residues,
                        $ATOMresinum );

                    $interface = join( '', @$newInt );
                }

                #write %int into an output file
                &writeOutputFL( $interface, $fastaSeq, $PDBID, $chainID,
                    $outputFL );
            }
        }
    }

    print LOG "\nSearching Full RPI database is finished.\n";
    print LOG
"$outputFL is generated. Total $totalNum queries. Total $num1 in $outputFL, $num2 queries do not exist in Full RPI database, $num3 queries exist in Full RPI but do not exist in s2c database\n\n\n";

    #	close LOG;

    #------------------------------------

    sub header_outputFL {
        my $outputFL = shift @_;
        my $distThr  = shift @_;

        unlink($outputFL) if ( -e $outputFL );
        open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL!\n");
        print OUTPUT
"# =========================================================================================================\n";
        print OUTPUT
"# auto generated file  by author lixue\@iastate.edu using getIntSeqFromFullDB.pl\n";
        print OUTPUT
          "# PRIDB data downloaded from http://pridb.gdcb.iastate.edu/\n";
        print OUTPUT "# Format description:\n";
        print OUTPUT "# >Protein name(PDBid + chain ID)\n";
        print OUTPUT "# Amino acid sequence in S2C database.\n";
        print OUTPUT
"# (non)interface of the protein: 1s denote interface residues, 0s denote non-interface residue\n";
        print OUTPUT "# DistThr: $distThr\n";
        print OUTPUT
"# =========================================================================================================\n";
        close(OUTPUT);
    }

    sub readRawinputFL {

        #read the files in $FullRPIDB

        my $file    = shift @_;
        my $distThr = shift @_;
        my $ATOMindex;
        my $int;

        open( INPUT, "<$file" ) || die("Cannot open $file: $!");
        foreach (<INPUT>) {
            s/[\n\r]//mg;

            #			13	T	1
            if (/^(\w+)\t([A-Z]{3})\t([\d\.e]+)/) {

                #			my $residue = $2;

                if ( $3 <= $distThr ) {
                    push @$ATOMindex, $1;
                    push @$int,       1;
                }

            }
        }
        close(INPUT);

        return ( $int, $ATOMindex );

    }

    sub writeOutputFL {

        #	(\%int,$PDBID,$chainID);
        #read the complete fasta file into a hash and compare with %int
        #for aa that are in %int, write the outputfile accordingly;
        #for aa that are not in %int, use "?" to denote the interface.

        my $interface = shift @_;
        my $seq       = shift @_;
        my $PDBID     = lc( shift @_ );
        my $chainID   = shift @_;
        my $outputFL  = shift @_;

        open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL!\n");
        print OUTPUT ">$PDBID$chainID\n";
        print OUTPUT "$seq\n";
        print OUTPUT "$interface\n";
        close(OUTPUT);

    }

    sub readS2Cfile {

        #Note: Sometimes s2c cannot process a PDB file. For example, 1kld.
        #
        # A s2c file:
        # SEQCRD    A R ARG ARG   122    201 C C 0
        # SEQCRD    A K LYS ---   123      - - - 0
        #
        my $pdbID   = lc(shift @_);
        my $chainID = shift @_;
        my $s2cDIR  = shift @_;
        my $s2cFL   = $s2cDIR . "/$pdbID.sc";
        my @residues;
        my @SEQRESresinum;
        my @ATOMresinum;

        open( S2C, "<$s2cFL" ) || die("Cannot open $s2cFL:$!");
        while (<S2C>) {
            s/[\n\r]//gm;

            if (/^SEQCRD\s+$chainID/) {

                #			$chainID=substr($_,7,1);

                my @tmp = split(/\s+/, $_);
                my $aa = $tmp[2];
                my $seqResNum = $tmp[5];
                my $atomResNum = $tmp[6];
                push @residues,      $aa;
                push @SEQRESresinum, $seqResNum;
                push @ATOMresinum, $atomResNum ;

            }
        }
        close S2C;



        if(!@residues){
            print("s2c file error. Sometimes s2c cannot process a PDB file. For example, 1kld. Check $s2cFL.\n");
        }

        return ( \@residues, \@SEQRESresinum, \@ATOMresinum );
    }

    sub readS2Cfile_old {

        use strict;
        my $pdbID   = lc( shift @_ );
        my $chainID = shift @_;
        my $s2cDIR  = shift @_;
        my $s2cFL   = $s2cDIR . "/$pdbID.sc";
        my @residues;
        my @SEQRESresinum;
        my @ATOMresinum;

        open( S2C, "<$s2cFL" ) || die("Cannot open $s2cFL: $!");
        foreach (<S2C>) {
            if (/^SEQCRD $chainID/) {

                #			SEQCRD 3 A ALA ALA     1      1 C C -

                #			$chainID=substr($_,7,1);
                push @residues,      substr( $_, 9,  1 );    #one letter code:A
                push @SEQRESresinum, substr( $_, 19, 5 );    #

                my ($temp) = substr( $_, 25, 6 ) =~ /([^\s\t]+)/;
                push @ATOMresinum, $temp;

            }
        }

        #remove space in @ATOMresinum

        return ( \@residues, \@SEQRESresinum, \@ATOMresinum );
    }

    sub mapInt2fasta {
        my $int_atomResiNum_ref = shift @_;    #from PRIDB file
        my $residues_ref        = shift @_;    # in the order of fasta.
        my $ATOMresinum_ref     = shift @_;    #from S2C
        my $int;

        for ( my $i = 0 ; $i < scalar @$residues_ref ; $i++ ) {

            # the residue is missing from the structure
            if ( $ATOMresinum_ref->[$i] eq '-' ) {
                $int->[$i] = '?';
                next;
            }

#the residue is non-interface if it is in the structure but it is not returned by PRIDB as int
            elsif ( !exists $int_atomResiNum_ref->{ $ATOMresinum_ref->[$i] } ) {
                $int->[$i] = '0';
                next;
            }

            #there is interface info for this residue
            else {
                $int->[$i] = $int_atomResiNum_ref->{ $ATOMresinum_ref->[$i] };
            }

        }
        return $int;
    }

}

#----------------------------------------------------------------------------------------------------------------------------------------------------
sub rmChainsWithLessThan5intAA {

    use strict;
    use File::Copy;
    use File::Basename;

    my $num_intAA_thresh = shift @_
      ; # 5;   #seq with less than 5 interface residues are removed from the input file.
    my $inputFL = shift @_;
    my $rand    = rand(2);
    my $tmpFL   = "$rand.tmp";
    my $dirname = dirname($inputFL);
    my $seq_int_lessThan5intFL =
      "$dirname/seq_int_homComplexesWithLessThan5int.lst"
      ;    #(contains seq and int info of the removed chains)
    my $header;
    my $seq;
    my $int;
    my $numOnes;
    my $flag           = 0;    #flag=1: sequences and interfaces starts
    my $num_totalinput = 0;    #number of seqs in the input file
    my $num_final      = 0;    #number of sequences in the final output file
    my @partnersToberemoved
      ; #these proteins have > 5 int, but their partner have <= 5 int. So they are removed, too.
    unlink $seq_int_lessThan5intFL if ( -e $seq_int_lessThan5intFL );

    open( INPUT, "<$inputFL" ) || die("Cannot open $inputFL:$!");
    unlink($tmpFL) if ( -e $tmpFL );

    foreach (<INPUT>) {
        s/[\n\r]//mg;

        if (/^>\w+/) {

            #		>1efvA|A:B
            $num_totalinput++;
            $header = $_;
            $flag   = 1;
            next;
        }
        if (/^[A-Za-z]+$/) {
            $seq = $_;
            next;
        }
        if (/^[01\?]+$/) {
            $int     = $_;
            $numOnes = &numOnes($int);

            if ( $numOnes >= $num_intAA_thresh ) {

                $num_final++;

                open( TMP, ">>$tmpFL" );
                print TMP "$header\n";
                print TMP "$seq\n";
                print TMP "$int\n";
                close(TMP);
            }
            else {
                open( OUTPUT, ">>$seq_int_lessThan5intFL" );
                print OUTPUT "$header\n";
                print OUTPUT "$seq\n";
                print OUTPUT "$int\n";
                close(OUTPUT);
                print LOG
"$header has less than $num_intAA_thresh interface residues and is removed from $inputFL.\n";
            }
            $header = '';
            $seq    = '';
            $int    = '';
            next;
        }

        #print header lines of the input file
        if ( $flag == 0 ) {
            open( TMP, ">>$tmpFL" );
            print TMP "$_\n";
            close(TMP);
            next;
        }
    }

    close(INPUT);

    unlink($inputFL);
    move( $tmpFL, $inputFL ) or die "Move $tmpFL failed: $!";

    print LOG
"Chains with less than $num_intAA_thresh interface residues are removed from $inputFL to $seq_int_lessThan5intFL.\n";
    print LOG
"There are total $num_totalinput input sequences. And now $num_final seqs in $inputFL.\n\n";

    #	close LOG;

    #---------------------

    sub numOnes {
        my $int     = shift @_;
        my $numOnes = 0;
        my @temp    = split //, $int;

        foreach (@temp) {
            if (/1/) {
                $numOnes = $numOnes + 1;
            }
        }
        return $numOnes;

    }

}

#-------------------------------------------------------------------------------------------------------------------
sub localAlignFastaGen2 {

#author: Xue, Li
#date: 4/21/2010
#This script is the pipeline of HomPPI
#
#Input:
#1. PPIDB output file: "seq_interface_homologsOfquerySeq.lst", which contains seq and interface info
#2. BLAST output file: "$taskID.blast", which contains alignment info
#
#Ouput:
#"seq_interface_homologsOfquerySeq.localAlign", a fasta file of homologs of query Sequence, in which only the locally aligned part of the homologs are included.
#The output file is put under the same directory with the input files.
#
#Usage:
#e.g.:  perl ./localAlignFastaGen2.pl ../data/1ahjA/seq_interface_homologsOfquerySeq.lst ../data/1ahjA/1ahjA.blast

    use strict;
    use File::Basename;

    #Files
    my $PPIDBoutputFL = shift @_;
    my $BlastFL       = shift @_;

    #	my $logFL         = shift @_;
    my $totalLengthQry;

    #Directories
    my $ProteinToBePredictedDIR = dirname( $BlastFL, '.blast' );

    my $outputFL =
      "$ProteinToBePredictedDIR/seq_interface_homologsOfquerySeq.localAlign";
    unlink $outputFL if ( -e $outputFL );

    #Program begin
    open( PPIDBFL, "<$PPIDBoutputFL" ) || die("Can not open $PPIDBoutputFL:$!");
    open( OUTPUT,  ">>$outputFL" );
    open( BLASTFL, "<$BlastFL" )       || die("Cannot open $BlastFL:$!");
    my $flag = 0;
    foreach (<BLASTFL>) {

        #Query=  3IKHA
        #Length=281
        if (/^Query=/) {
            $flag = 1;
        }
        if ( $flag == 1 && /Length=(\d+)/ ) {
            $totalLengthQry = $1;
            last;
        }
    }
    close(BLASTFL);

    if (!defined $totalLengthQry ){
        die("Query Length not read from $BlastFL:$!");
    }
    print OUTPUT "Query: $totalLengthQry letters\n";

    foreach (<PPIDBFL>) {
        chomp;
        s/[\n\r]//mg;

        if (/^>(.{5})$/) {

            #get PDBID and chainID of homologs
            my $homolog = $1;    #get the PDBID and chainID that PPIDB output

            my $groupID = &groupID2( $BlastFL, $homolog )
              ; #get groupID in $taskID.blast file for each $homolog. &groupID() is for user-defined blast db format

            #		print "$groupID\n";

            my @a = &searchBLAST2( $BlastFL, $homolog )
              ;    #&searchBLAST is for user-defined blast DB format

            for my $row (@a) {
                my (
                    $alignmentLength, $SbjctLength, $BitScore_Evalue,
                    $Identities,      $Positives,   $start_Q,
                    $end_Q,           $start_S,     $end_S,
                    $localAlign_Q,    $localAlign_S
                ) = @$row;
                print OUTPUT
">$homolog|GroupID $groupID|Alignment Length $alignmentLength|Sbjct Length $SbjctLength|Sbjct RESI $start_S - $end_S|Query RESI $start_Q - $end_Q|$BitScore_Evalue, Identities = $Identities, Positives = $Positives\n";
                print OUTPUT "$localAlign_Q\n";

#get the interface of the part of homologs that is aligned with the query sequence by BLASTp
                my $interface =
                  &subSbjctInt( $PPIDBoutputFL, $homolog, $start_S, $end_S );

                #		print "        $interface\n";

                #insert spaces into $interface according to the BLASTp alignment
                $interface = &insertSpc( $localAlign_S, $interface );
                print OUTPUT "$interface\n";
            }
        }
    }
    close(OUTPUT);
    close(PPIDBFL);

    #	open( LOG, ">>$logFL" ) || die("Cannot open $logFL.\n");
    print LOG
"Generation of localAlignment Fasta file is done! The output file is $outputFL.\n";

    #	close LOG;

    #-----

    sub searchBLAST {

#note: this subroutine is for *.blast file with format when Blast searches against user-defined proteinProtein database.

 #search *.blast for the local alignment of homolog in PPIDB with query sequence
 #return $alignmentLength, $SbjctLength, $BitScore_Evalue, $Identities, etc.

        my ( $BlastFL, $homolog ) = @_;

        #	$homolog =~ tr/a-z/A-Z/;

        my ($PDBID) = $homolog =~ /^(.{4})/;
        $PDBID = lc($PDBID);
        my ($chainID) = $homolog =~ /(.{1})$/;

        my $SbjctLength;
        my $BitScore_Evalue;    #Bit score and E-value
        my $alignmentLength;
        my $Identities
          ;    # Identities = 537/537 (100%), Positives = 537/537 (100%)
        my $Positives;
        my @startPos_S
          ;    #starting position of a subject seq in an alignment in ONE LINE
        my @endPos_S
          ;    #ending position of a subject seq in an alignment in ONE LINE
        my @startPos_Q
          ;    #starting position of the query seq in an alignment in ONE LINE
        my @endPos_Q
          ;    #ending position of the query seq in an alignment in ONE LINE
        my @seq_S = ();
        my @seq_Q = ();
        my $flag  = 0;
        my $start_S;       #starting position of the subject seq in an alignment
        my $start_Q;       #starting position of the query seq in an alignment
        my $end_S;         #ending position of the subject seq in an alignment
        my $end_Q;         #ending position of the query seq in an alignment
        my $localAlign_S;  #the aligned part of a subject seq
        my $localAlign_Q;  #the aligned part of the Query seq
        my $flag1 = 0
          ; #to flag how many possible alignments. Sometimes one homolog has several alignment with the query sequence. For example, 1yru_B and 1g4y_R
        my $BitScore_Evalue_next
          ;    #BitScore_Evalue for the next possible alignment
        my @a;

        #go to *.blast file to find the local alignment
        open( BLASTFL, "<$BlastFL" ) || die("Can not open $BlastFL!\n");
        while (<BLASTFL>) {

            s/[\r\n]//g;
            if ( /^>/ || eof(BLASTFL) ) {
                $flag = 0;
            }

            if (/^[>\s]+$PDBID$chainID\s*$/)    # 1IOK_D
            {
                $flag = 1;    #find the protein we are looking for
                next;
            }
            if ( $flag == 1 && /^Length=(\d+)/ ) {
                $SbjctLength = $1;
                next;
            }

            if ( $flag == 1
                && /(Score\s+=\s+.+\s+bits\s+\(.+\),\s+Expect\s+=\s+[0-9\-e\.]+)/
              )

              # Score =  256 bits (654),  Expect = 4e-069,
            {
                $flag1++;
                if ( $flag1 > 1 ) {
                    $BitScore_Evalue_next = $1;
                    $flag                 = 0;
                }
                else {
                    $BitScore_Evalue = $1;
                    next;
                }
            }
            if (
                $flag == 1
                && /^ Identities = \d+\/(\d+) \((\d+%)\), Positives = \d+\/\d+ \((\d+%)\)/

 #			      Identities = 94/94 (100%), Positives = 94/94 (100%), Gaps = 0/94 (0%)
              )
            {
                $alignmentLength = $1;
                $Identities      = $2;
                $Positives       = $3;
                next;

            }

            if ( $flag == 1 && /^Query\s+(\d+)\s+([A-Z\-]+)\s+(\d+)/ ) {
                push @startPos_Q, $1;
                push @endPos_Q,   $3;
                push @seq_Q,      $2;
                next;
            }
            if ( $flag == 1 && /^Sbjct\s+(\d+)\s+([A-Z\-]+)\s+(\d+)/ ) {
                push @startPos_S, $1;
                push @endPos_S,   $3;
                push @seq_S,      $2;
                next;
            }

            if ( $flag == 0 && $#seq_S >= 0 ) {
                $start_S      = $startPos_S[0];
                $end_S        = pop @endPos_S;
                $localAlign_S = join "", @seq_S;
                @seq_S        = ();
            }
            if ( $flag == 0 && $#seq_Q >= 0 ) {
                $start_Q      = $startPos_Q[0];
                $end_Q        = pop @endPos_Q;
                $localAlign_Q = join "", @seq_Q;
                @seq_Q        = ();

                push @a,
                  [
                    $alignmentLength, $SbjctLength, $BitScore_Evalue,
                    $Identities,      $Positives,   $start_Q,
                    $end_Q,           $start_S,     $end_S,
                    $localAlign_Q,    $localAlign_S
                  ];

                if ( $flag1 > 1 ) {
                    @startPos_S      = ();
                    @endPos_S        = ();
                    @startPos_Q      = ();
                    @endPos_Q        = ();
                    $BitScore_Evalue = $BitScore_Evalue_next;
                    $flag            = 1;
                }

            }

        }
        close(BLASTFL);
        return @a;

    }

    sub searchBLAST2 {

#this subroutine is for *.blast file with format when Blast searches against pdb database.

 #search *.blast for the local alignment of homolog in PPIDB with query sequence
 #return $alignmentLength, $SbjctLength, $BitScore_Evalue, $Identities, etc.

        my ( $BlastFL, $homolog ) = @_;

        my ($PDBID) = $homolog =~ /(.{4})/;
        $PDBID = uc($PDBID);
        my ($chainID) = $homolog =~ /$PDBID(.{1})/i;

        my $SbjctLength;
        my $BitScore_Evalue;    #Bit score and E-value
        my $alignmentLength;
        my $Identities
          ;    # Identities = 537/537 (100%), Positives = 537/537 (100%)
        my $Positives;
        my @startPos_S
          ;    #starting position of a subject seq in an alignment in ONE LINE
        my @endPos_S
          ;    #ending position of a subject seq in an alignment in ONE LINE
        my @startPos_Q
          ;    #starting position of the query seq in an alignment in ONE LINE
        my @endPos_Q
          ;    #ending position of the query seq in an alignment in ONE LINE
        my @seq_S = ();
        my @seq_Q = ();
        my $flag  = 0;
        my $start_S;       #starting position of the subject seq in an alignment
        my $start_Q;       #starting position of the query seq in an alignment
        my $end_S;         #ending position of the subject seq in an alignment
        my $end_Q;         #ending position of the query seq in an alignment
        my $localAlign_S;  #the aligned part of a subject seq
        my $localAlign_Q;  #the aligned part of the Query seq
        my $flag1 = 0
          ; #to flag how many possible alignments. Sometimes one homolog has several alignment with the query sequence. For example, 1yru_B and 1g4y_R
        my $BitScore_Evalue_next
          ;    #BitScore_Evalue for the next possible alignment
        my @a;

        #go to *.blast file to find the local alignment
        open( BLASTFL, "<$BlastFL" ) || die("Can not open $BlastFL!\n");
        while (<BLASTFL>) {

            s/[\n\r]//mg;
            if ( /^>pdb/ || eof(BLASTFL) ) {
                $flag = 0;
            }

            if (/^[>\s]pdb\|$PDBID\|$chainID /)    # pdb|1IOK|D
            {
                $flag = 1;    #find the protein we are looking for
                next;
            }
            if ( $flag == 1 && /^Length\s{0,}=\s{0,}(\d+)/ ) {
                $SbjctLength = $1;
                next;
            }

            if ( $flag == 1
                && /(Score\s+=\s+.+\s+bits\s+\(.+\),\s+Expect\s+=\s+[0-9\-e\.]+)/
              )
            {
                $flag1++;
                if ( $flag1 > 1 ) {
                    $BitScore_Evalue_next = $1;
                    $flag                 = 0;
                }
                else {
                    $BitScore_Evalue = $1;
                    next;
                }
            }
            if ( $flag == 1
                && /^ Identities = \d+\/(\d+) \((\d+%)\), Positives = \d+\/\d+ \((\d+%)\)/
              )
            {
                $alignmentLength = $1;
                $Identities      = $2;
                $Positives       = $3;
                next;

            }

            if ( $flag == 1
                && /^Query:{0,1}[\s\t]+(\d+)[\s\t]+([A-Z\-]+)[\s\t]+(\d+)/ )
            {
                push @startPos_Q, $1;
                push @endPos_Q,   $3;
                push @seq_Q,      $2;
                next;
            }
            if ( $flag == 1
                && /^Sbjct:{0,1}[\s\t]+(\d+)[\s\t]+([A-Z\-]+)[\s\t]+(\d+)/ )
            {
                push @startPos_S, $1;
                push @endPos_S,   $3;
                push @seq_S,      $2;
                next;
            }

            if ( $flag == 0 && $#seq_S >= 0 ) {
                $start_S      = $startPos_S[0];
                $end_S        = pop @endPos_S;
                $localAlign_S = join "", @seq_S;
                @seq_S        = ();
            }
            if ( $flag == 0 && $#seq_Q >= 0 ) {
                $start_Q      = $startPos_Q[0];
                $end_Q        = pop @endPos_Q;
                $localAlign_Q = join "", @seq_Q;
                @seq_Q        = ();

                push @a,
                  [
                    $alignmentLength, $SbjctLength, $BitScore_Evalue,
                    $Identities,      $Positives,   $start_Q,
                    $end_Q,           $start_S,     $end_S,
                    $localAlign_Q,    $localAlign_S
                  ];

                if ( $flag1 > 1 ) {
                    @startPos_S      = ();
                    @endPos_S        = ();
                    @startPos_Q      = ();
                    @endPos_Q        = ();
                    $BitScore_Evalue = $BitScore_Evalue_next;
                    $flag            = 1;
                }

            }

        }
        close(BLASTFL);
        return @a;

    }

    sub subSbjctInt {

#to extract substring of interfaces of homologs, given the starting pos and ending position

        my ( $PPIDBoutputFL, $homolog, $start, $end ) = @_;
        my $PDBID   = substr( $homolog, 0, 4 );
        my $chainID = substr( $homolog, 4, 1 );
        $PDBID =~ tr/A-Z/a-z/;
        $homolog = $PDBID . $chainID;
        my $interface;
        my $flag = 0;
        open( PPIDB, "<$PPIDBoutputFL" )
          || die("Can not open $PPIDBoutputFL!\n");

        #	if ( $homolog =~ /1dkdD/i )    #xue
        #	{
        #		print "$homolog\n";
        #	}

        foreach (<PPIDB>) {
            chomp;
            if (/^>$homolog$/) {
                $flag = 1;
                next;
            }

            if ( $flag == 1 && /^[01\?\-]+$/ ) {
                $interface = substr( $_, $start - 1, $end - $start + 1 );
                last;
            }
        }
        close(PPIDB);
        return $interface;
    }

    sub insertSpc {
        my ( $localAlign, $interface ) = @_;
        my $i = 0;                          #index of spaces in $localAlign
        my @temp = split '', $localAlign;
        foreach (@temp) {
            if (/\-/) {
                substr( $interface, $i, 0 ) = '-';
            }
            $i += 1;
        }
        return $interface;
    }

    sub groupID {

#Note: This subroutine is for $taskID.blast with the format when Blast searches against user-defined proteinProtein database.

        #Usage: Find the groupID in $taskID.blast for each homologs

        my ( $BlastFL, $homolog ) = @_;    #"2FDBN";

        my $groupID;
        my $num = 0;

        open( BLASTFL, "<$BlastFL" ) || die("Cannot open $BlastFL\n");
        while (<BLASTFL>) {
            if (/^> \w{5}/)                #>pdb|1HRT|I Chain I
            {
                $num += 1;
                if (/> $homolog/) {
                    $groupID = $num;
                    close(BLASTFL);
                    return $groupID;
                }
            }

        }
        close(BLASTFL);

    }

    sub groupID2 {

#Note: This subroutine is for $taskID.blast with the format when Blast searches against pdb database.

        #Usage: Find the groupID in $taskID.blast for each homologs

        my ( $BlastFL, $homolog ) = @_;    #"2FDBN";

        my ($pdbID)   = $homolog =~ /^(\w{4})/;
        my $uc_pdbID  = uc($pdbID);
        my $lc_pdbID  = lc($pdbID);
        my ($chainID) = $homolog =~ /(\w{1})$/;

        #read proteins in each group into an array of arrays

        my @groups = ();    #array of arrays
        my $row    = -1;    #row id for @groups
        my $flag   = 0;     #flag the start of each group in $taskID.blast file

        open( BLASTFL, "<$BlastFL" ) || die("Cannot open $BlastFL\n");
        while (<BLASTFL>) {

            if (/^>pdb\|(\w{4})\|(\w{1})/)    #>pdb|1HRT|I Chain I
            {
                $row += 1;
                push @{ $groups[$row] }, "$1$2";
                next;

                #		$flag= 1;

            }
            if (/^ pdb\|(\w{4})\|(\w{1})/) {
                push @{ $groups[$row] }, "$1$2";
            }
        }
        close(BLASTFL);

        my $groupID;
        for my $i ( 0 .. $#groups ) {
            for my $j ( 0 .. $#{ $groups[$i] } ) {
                if ( $groups[$i][$j] =~ /($uc_pdbID|$lc_pdbID)$chainID/ ) {
                    return $groupID = $i;
                }
            }
        }

    }

}

#--------------------------------------------------------------------------------------------------------------------------------------------------------
sub collectStat {

#!/usr/bin/perl -w
#
#Xue, Li
#Jun, 2008
#
#To collect prediction performance for each sequence if we use one homolog interfaces as the prediction
#
#
#input files: under ../data
#		1. $localAlignFL
#		2. $taskID.int
#output: ../data/statistics.txt
#output format:
#>qry_pdbID_chainID length_Qry #int_Qry:
#PDBID+CHAINID length #int Bit_score Positive_Score IdentityScore aligLen_Query aligLen_Homolog CC TP TN FP FN
#...
#>query2
#...
#
#perl ./collectStat.pl chainList.tmp (chainList.tmp: each row is a taskID,e.g.,1A9NB, whose results are to be collected. All the prediction results are under ../data by default.)
#e.g., perl ./collectStat.pl ../data/nr6505.txt ../data ../data/statistics.txt
#      perl ./collectStat.pl ../searchNewPPIDB/out/seq_interface_nr6505.lst ../data ../data/statistics.txt
#	perl ./collectStat.pl ../data/hetero_trans_1134/seq_interface_hetero_trans_final_1137.lst ../data/hetero_trans_1134 ../data/hetero_trans_1134/statistics_hetero_trans_final_1137.txt
#perl ./collectStat.pl ../data/benchmark180/seq_interface_test.lst ../data/benchmark180 ../data/benchmark180/statistics_test.txt

    use strict;
    use File::Basename;

    my @taskIDs = @{ shift @_ };
    my $jobDIR =
      shift @_;    #collect alignment statistics for each homolog under this DIR
    my $outputFL = shift @_;

    #	my $logFL    = shift @_;

    my $num_taskIDs = scalar(@taskIDs);
    my $num_taskIDs_exist =
      0;           #the number of taskIDs are collected in the output file.

    #---------

    unlink $outputFL if ( -e $outputFL );

    print LOG "In collectStat function!\n";

    open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL:$!\n");
    print OUTPUT "#num_residue1: the length of the seq.\n";
    print OUTPUT
      "#num_residue2: the number of resi that have (non)int information.\n";
    print OUTPUT "#>QUERY PDBID + CHAINID\n";
    print OUTPUT
"#HOMOLOG-PDBID+CHAINID\tnum_residue1\tnum_residue2\tnum_int\tBit_score\tEvalue\tPositive_Score\tIdentityScore\talignment_length\taligLen_Query\taligLen_Homolog\n";
    close(OUTPUT);

    my $num = 0;    #number of query proteins
    foreach (<@taskIDs>) {
        if (/^\w+$/) {
            $num++;
            my $taskID = $_;

            #			open( LOG, ">>$logFL" )
            #			  || die("Cannot open $logFL:$!");
            print LOG "query: -----------------------------$taskID\n";
            print LOG "#num_taskIDs is $num_taskIDs\n";

            #			close LOG;

            #		open( OUTPUT, ">>$outputFL" );
            #		print OUTPUT ">$taskID\n";
            #		close OUTPUT;

            if ( -d "$jobDIR/$taskID" ) {
                $num_taskIDs_exist++;
                &collectStat4oneQry( $taskID, $jobDIR, $outputFL );
            }
            else {
                die("The folder $jobDIR/$taskID does not exist:$!\n");
            }
        }
    }

    #	open( LOG, ">>$logFL" )
    #	  || die("Cannot open $logFL:$!");
    print LOG
"Collecting the statistics of the PPI conservation between query sequences and their homologs is finished! $outputFL is generated. $num_taskIDs_exist out of $num_taskIDs qry proteins are in $outputFL.\n";

    #	close LOG;

    #------------

    sub readINTFL {

        #read in $taskID's interface and sequences

        my $interfaceFL = shift @_;
        my $seq;
        my @int;    # array ref

        open( INT_Q_FL, "<$interfaceFL" ) || die("Cannot open $interfaceFL\n");
        foreach (<INT_Q_FL>) {
            if (/^([A-Z\?]+)[\n\r]*$/) {
                $seq = $1;
                next;
            }
            if (/^([01\?\-]+)[\n\r]*$/) {
                @int = split( //, $1 );
                last;
            }
        }

        close INT_Q_FL;

        return ( $seq, \@int )

    }

    #=========================
    sub collectStat4oneQry {

#read localAlignFL and $taskID.int file, and for each homolog calculate TN, TP, etc. and write them into the output file.

        my $taskID   = shift @_;
        my $jobDIR   = shift @_;
        my $outputFL = shift @_;

        #		my $logFL    = shift @_;

        #	print "Qry: $taskID\n";

        my $seq_Q;           #sequence of taskID
        my $int_Q;           #interface of taskID, array ref
        my $seq_S;           #sequence of a homolog
        my @int_S;           #interfaces of a homolog
        my $num_residue1;    #$queryLength
        my $num_residue2;    #number of aa that have int info in pdb file
        my $queryLength;
        my $alignmentLength;
        my $sbjctLength;     #the length of homolog
        my $sbjctPDBID;
        my $start_Q;
        my $end_Q;
        my $start_S;
        my $end_S;
        my $BitScore;
        my $EVal;
        my $Identities;
        my $Positives;
        my $propotion_aligLength_Q;
        my $propotion_aligLength_S;
        my $interface_S;
        my $interface_Q;
        my @where;    #to record the indices of '-' in homolog sequence
        my $flag = 0;
        my $CC;
        my $sensitivity;
        my $specificity;
        my $accuracy;
        my $TP;
        my $TN;
        my $FP;
        my $FN;

        my $localAlignFL =
          "$jobDIR/$taskID/seq_interface_homologsOfquerySeq.localAlign";
        my $interfaceFL      = "$jobDIR/$taskID/$taskID.int";
        my $fastaFL          = "$jobDIR/$taskID/$taskID.fasta.txt";
        my $seqInt_homologFL = "$jobDIR/$taskID/seq_int_homologsOfquerySeq.lst"
          ;    #is used to count the num of int of homologs

        #read in $taskID's interface and sequences
        my ( $seq_H, $int_H ) = &readSeqIntFL($seqInt_homologFL);
        $seq_Q = &readFastaFL($fastaFL);
        my $length_Q       = length($seq_Q);
        my $num_residue1_Q = $length_Q;

        #get number of intface residues
        my ( $num_residue2_Q, $num_int_Q );

        if ( -e $interfaceFL ) {

            ( $seq_Q, $int_Q ) = &readINTFL($interfaceFL);
            ( $num_residue2_Q, $num_int_Q ) = &getNumInt( join( '', @$int_Q ) );
        }
        else {
            ( $num_residue2_Q, $num_int_Q ) = ( '', '' );
        }

        my $num_residue1_S;    #length of sbj
        my $num_residue2_S;    #length of sbj that has int inf in pdb file

        open( OUTPUT, ">>$outputFL" );
        print OUTPUT ">$taskID\t$num_residue1_Q\t$num_residue2_Q\t$num_int_Q\n";
        close OUTPUT;

#-------------------collect the prediction results for one homolog-----------------------#

        #---------read $localAlignFL file--------#
        if ( -e $localAlignFL ) {

            #			&readLocalAlignFL($localAlignFL);

            open( LocalAlignFL, "<$localAlignFL" )
              || die("Cannot open $localAlignFL:$!\n");

            while (<LocalAlignFL>) {
                if (/Query: (\d+) letters/) {
                    $queryLength = $1;

                    if (!defined $queryLength || $queryLength ==0){
                        die("query length not extracted from $localAlignFL:$!");
                    }
                    next;
                }

                #1. process '>' line

                if (
/^>(.{5})\|GroupID \d+\|Alignment Length\s+(\d+)\|Sbjct Length (\d+)\|Sbjct RESI (\d+) \- (\d+)\|Query RESI (\d+) \- (\d+)\|Score =\s+([\.\d]+) bits \(.+\),[\s\t]+Expect =[\s\t]+([\d\-\.e]+), Identities = (\d+)%, Positives = (\d+)%/
                  )
                {

                    @where      = ();
                    $sbjctPDBID = $1;

                    print LOG "$sbjctPDBID\n";

                    $alignmentLength = $2;
                    $sbjctLength     = $3;
                    $num_residue1_S  = $sbjctLength;
                    $start_S         = $4;
                    $end_S           = $5;
                    $start_Q         = $6;
                    $end_Q           = $7;
                    $BitScore        = $8;
                    $EVal            = $9;
                    $Identities      = $10;
                    $Positives       = $11;

                    my $aligLength_Q = $end_Q - $start_Q;
                    my $aligLength_S = $end_S - $start_S;

                    if ($queryLength ==0 ){
                        die("query length not extracted from $localAlignFL:$!");
                    }
                    $propotion_aligLength_Q = $aligLength_Q/$queryLength;
                    $propotion_aligLength_S = $aligLength_S/$sbjctLength;

                    $flag = 1;
                    next;
                }

                #2. process query sequence line
                if ( $flag == 1 && /^([A-Z\-\?]+)[\n\r]*$/ ) {

                    #find the index for -

                    my $index = index( $1, '-' );

                    while ( $index >= 0 ) {

                        if ( $index >= 0 ) {
                            push @where, $index;
                        }
                        $index = index( $1, '-', $index + 1 );
                    }
                    next;
                }

                #3.process homolog interface line
                if ( /^([01\?\-]+)[\n\r]*$/ && $flag == 1 ) {
                    $flag = 0;
                    my $int = $1;    #the interface of a homolog

                    #remove the interface sign that corresponds to -
                    my $i = 0;
                    if (@where) {
                        foreach (<@where>) {
                            substr( $int, $_ - $i, 1 ) = '';
                            $i++;
                        }
                    }

                    #add ? to the two ends
                    my $multiX1 =
                      "?" x ( $start_Q - 1 );    #$num_multiX question marks
                    my $multiX2 = "?" x ( $queryLength - $end_Q );
                    @int_S = split( //, "$multiX1$int$multiX2" );

                }

                if ( -e $interfaceFL ) {

#----------compare interfaces of query and homolog, and calculate TP, TN, FP, FN, CC, etc-------

                    (
                        $TP, $TN, $FP, $FN, $CC, $specificity, $sensitivity,
                        $accuracy
                      )
                      = &TP_TN_FN_FP_CC_specif_sensi_acc( $int_Q, \@int_S,
                        $sbjctPDBID );
                }
                else {
                    (
                        $TP, $TN, $FP, $FN, $CC, $specificity, $sensitivity,
                        $accuracy
                    ) = ('') x 8;
                }

                #the int number of the aligned part of homolog
                my $numInt_aligned_S = &numInt( join( '', @int_S ) );

                #the int number of homolog
                #			my $num_int_S = &numInt($int_H->{$sbjctPDBID});
                my ( $num_residue2_S, $num_int_S ) =
                  &getNumInt( $int_H->{$sbjctPDBID} );

                #--------print to output file------------#

                if ( $TP eq '0' && $TN eq '0' && $FP eq '0' && $FN eq '0' ) {

                #the aligned part of query sequence has no interface information
                # For example, for query 1mw5A and its homolog 1dvjA
                    next;
                }
                else {
                    open( OUTPUT, ">>$outputFL" );
                    print OUTPUT
"$sbjctPDBID\t$num_residue1_S\t$num_residue2_S\t$num_int_S\t$BitScore\t$EVal\t$Positives\t$Identities\t$alignmentLength\t$propotion_aligLength_Q\t$propotion_aligLength_S\t$CC\t$specificity\t$sensitivity\t$accuracy\t$TP\t$TN\t$FP\t$FN\n";
                    close OUTPUT;
                }

            }
            close LocalAlignFL;
        }
    }

    sub numInt {
        my @int = split( //, shift @_ );
        my $num_int = 0;
        foreach (@int) {
            if (/1/) {
                $num_int++;
            }
        }
        return $num_int;

    }

    sub TP_TN_FN_FP_CC_specif_sensi_acc {

#----------compare interfaces of query and homolog, and calculate TP, TN, FP, FN, CC, etc-----------#

        my $int_Q      = shift @_;
        my $int_S      = shift @_;
        my $sbjctPDBID = shift @_;
        my ( $TP, $TN, $FP, $FN, $CC, $specificity, $sensitivity, $accuracy ) =
          ( 0, 0, 0, 0, 0, 0, 0, 0 );

        for my $i ( 0 .. ( scalar @$int_Q - 1 ) ) {
            if ( $int_Q->[$i] =~ /1/ ) {
                if ( $int_S->[$i] =~ /1/ ) {
                    $TP++;
                }
                elsif ( $int_S->[$i] =~ /0/ ) {
                    $FN++;
                }
            }

            if ( !defined $int_Q->[$i] ) {
                die("debug query: $!");    #xue
            }

            if ( !defined $int_S->[$i] ) {
                die("debug homolog: $sbjctPDBID:$!");    #xue
            }

            elsif ( $int_Q->[$i] =~ /0/ ) {
                if ( $int_S->[$i] =~ /1/ ) {
                    $FP++;
                }
                elsif ( $int_S->[$i] =~ /0/ ) {
                    $TN++;
                }
            }

        }

        #------------calculate CC etc.------------#
        if (
            ( $TP + $FN ) * ( $TP + $FP ) * ( $TN + $FP ) * ( $TN + $FN ) != 0 )
        {
            $CC =
              ( $TP * $TN - $FP * $FN ) /
              sqrt(
                ( $TP + $FN ) * ( $TP + $FP ) * ( $TN + $FP ) * ( $TN + $FN ) );
        }
        if ( $TP + $FP != 0 ) {
            $specificity = $TP / ( $TP + $FP );
        }
        if ( $TP + $FN != 0 ) {
            $sensitivity = $TP / ( $TP + $FN );
        }
        if ( $TP + $TN + $FN + $FP != 0 ) {
            $accuracy = ( $TP + $TN ) / ( $TP + $TN + $FN + $FP );
        }

        return ( $TP, $TN, $FP, $FN, $CC, $specificity, $sensitivity,
            $accuracy );
    }

    sub readSeqIntFL {
        my $seqIntFL = shift @_;
        my ( $seq, $int );
        my $pdbID_chnID;

        open( INPUT, "<$seqIntFL" ) || die("Cannot open $seqIntFL:$!");
        foreach (<INPUT>) {
            s/[\n\r]//mg;
            if (/^>(\w{5})/) {
                $pdbID_chnID = $1;
                next;
            }
            if (/^([a-zA-Z]+)$/) {
                $seq->{$pdbID_chnID} = $1;
                next;
            }
            if (/^([01\?]+)$/) {
                $int->{$pdbID_chnID} = $1;
                next;
            }

        }
        close INPUT;

        return ( $seq, $int );
    }

    sub getNumInt {
        my @int = split( //, shift @_ );
        my $num_int = 0;
        my $num_residue2 = 0;    #num of residues that have (non)int infor
        foreach (@int) {
            if (/1/) {
                $num_int++;
                $num_residue2++;
            }
            if (/0/) {
                $num_residue2++;
            }
        }
        return ( $num_residue2, $num_int );

    }

}

#-------------------------------------------------------------------------------------------------------------------
sub rmSimilarProt {

    #!usr/bin/perl -w
    #Li Xue
    #Jul 24th, 2011

#rm the homolog that from $inputFL and write the remaining into the output file.
#qry-homolog pairs are removed if they share >= 95% Identity (#identical aa/length_Qry>= 95% and #identical aa/length_homolog >= 95%)
#,and no matter what species they are from.
#
#$inputFL is the file where each homolog information are collected.

    #perl rmSameProt.pl ../data/nr6505/statistics_nr6505.txt
    #perl rmSameProt.pl ../data/statistics_benchMarkproteins.txt

    use strict;

    use File::Basename;
    use POSIX qw/ceil/;

    #	our $HomeDIR;

    #	my $newPPIDBdir   = "$HomeDIR/newPPIDB";
    #	my $NPS_HomPPIdir = "$HomeDIR/HomPPI/NPS-HomPPI";

#	our $pdb_chain_taxonomyLst =
#"/usr/share/apache-tomcat-6.0.16/webapps/HOMPPI/supplementaryData/pdb_chain_taxonomy.lst"
#	  ;    #from sifts project

    our $protSimilarityThr;    #by default, $protSimilarityThr= 95

    my $inputFL =
      shift @_;    #"$NPS_HomPPIdir/data/statistics_nr6505_EvalThr10.txt";

    #	my $logFL = shift @_;

    my $dirname  = dirname($inputFL);
    my $basename = basename( $inputFL, ( '.txt', '.lst' ) );
    my $outputFL = "$dirname/$basename\_wo_sameProteins.txt";

    #"$NPS_HomPPIdir/data/statistics_nr6505_EvalThr10_wo_sameProteins.txt";

    #
    my $qry;
    my $lengthRef;
    my $num_int_Qry;
    my $homologRef;
    my $numIntRef;
    my $IdentitySRef;
    my $LALRef;
    my $numIdenticalAA;
    my $LALfracQryRef;    #LAL/qryLen
    my $LALfracHomRef;    #LAL/homologLen
    my $num_qry = 0;      #flag the start of a new qry

    print LOG "\n\nRemove highly similar proteins from file $inputFL:\n";
    print LOG
"qry-homolog pairs are removed if they share >= $protSimilarityThr% Identity (#identical aa/length_Qry>= $protSimilarityThr% and #identical aa/length_homolog >= $protSimilarityThr%).\n\n";

    open( INPUT, "<$inputFL" ) || die("Cannot open $inputFL:$!");

    foreach (<INPUT>) {
        s/[\n\r]//mg;
        if (/^>(\w+)\t(\d+)/) {

            $qry = $1;
            $lengthRef->{$qry} = $2;    #num_residue1: the length of the seq.

       #			my $num_residue2 = $3
       #			  ; #num_residue2: the number of resi that have (non)int information.
       #			$num_int_Qry = $4;
            $num_qry++;
            next;
        }
        if (/^\w{5}\t/) {
            my @a             = split( /\t/, $_ );
            my $homolog       = $a[0];
            my $qryHomlogPair = "$qry:$homolog";
            push @{ $homologRef->{$qry} }, $homolog;
            $lengthRef->{$homolog}          = $a[1];
            $numIntRef->{$qryHomlogPair}    = $a[ 2 + 1 ];
            $IdentitySRef->{$qryHomlogPair} = $a[ 6 + 1 ];    #[0-100]
            $LALRef->{$qryHomlogPair}       = $a[ 7 + 1 ];
            $numIdenticalAA->{$qryHomlogPair} =
              ceil( $a[ 6 + 1 ] * $a[ 7 + 1 ] * 0.01 );   #identityS * LAL *0.01
            $LALfracQryRef->{$qryHomlogPair} = $a[ 8 + 1 ];
            $LALfracHomRef->{$qryHomlogPair} = $a[ 9 + 1 ];
            next;
        }
    }
    close INPUT;

# check whether qry-homolog pair has high Identity score and from the same species
    my $qryHomlogPair;
    my $num_similarProt = 0;
    my $homologToBeDelref;

    #	my $taxonomyMap = &readP_chain_taxonomyLST;
    $basename = basename( $inputFL, ( '.lst', '.txt' ) );
    my $similarProtFL = "$dirname/similarProt_in_$basename.lst";
    my $outputFL_header;

    #------------------------------------------
    #similiar prot definition :
    #if #sameAA/QryLen > =95% and #sameAA/HomLen >=95%,
    #then Qry and Hom are highly similar to each other.
    $outputFL_header =
'#The definition of highly similar proteins: sameAA/QryLen > =$protSimilarityThr% and #sameAA/HomLen >=$protSimilarityThr%';
    ( $homologToBeDelref, $num_similarProt ) = &getSimilarProt(
        $homologRef, $numIdenticalAA, $IdentitySRef,
        $lengthRef,  $similarProtFL
    );

    #------------------------------------------
    undef $IdentitySRef;
    undef $LALfracQryRef;    #LAL/qryLen
    undef $LALfracHomRef;    #LAL/homologLen

    unlink $outputFL if ( -e $outputFL );
    open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL:$!");
    print OUTPUT "$outputFL_header\n";
    close OUTPUT;

    #
    my %homologTobeDel;
    open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL:$!");
    open( INPUT,  "<$inputFL" )   || die("Cannot open $inputFL:$!");

    #my @qrys = keys(%$homologToBeDelref);
    #my %qryHasSameproteinAsHomologs;
    #@qryHasSameproteinAsHomologs{@qrys}=(1) x scalar @qrys;
    my $flag;
    my $num = 0;
    foreach (<INPUT>) {
        s/[\n\r]//mg;

        if (/^#/) {
            print OUTPUT "$_\n";
            next;
        }

        if (/^>(\w+)/) {

            #			open( LOG, ">>$logFL" ) || die("Cannot open $logFL:$!");
            print LOG "$_\n";

            $flag           = 0;
            %homologTobeDel = ();

            $qry = $1;

            if ( !$homologToBeDelref->{$qry} ) {
                print LOG "$qry has no highly similar homologs.\n";
                $flag = 1;
            }
            else {
                my @homologTobeDel1 = @{ $homologToBeDelref->{$qry} };
                @homologTobeDel{@homologTobeDel1} =
                  (1) x scalar(@homologTobeDel1);
                print OUTPUT "$_\n";
                next;
            }
        }
        if ( /^(\w{5})\t/ && $flag == 0 ) {
            my $homolog = $1;

            if ( $homologTobeDel{$homolog} ) {
                print LOG "$homolog\n";
                $num++;

                next;
            }
            else {
                print OUTPUT "$_\n";
            }
            next;

        }
        print OUTPUT "$_\n";
    }
    close INPUT;
    close OUTPUT;

    #	close LOG;

    #	open( LOG, ">>$logFL" ) || die("Cannot open $logFL:$!");

    print LOG
      "There are $num_qry qry proteins in the original input file: $inputFL.\n";
    print LOG
"There are totally $num_similarProt qry-homolog pair that are highly similar proteins. They are put in $similarProtFL.\n";

    print LOG
"$outputFL is generated. $num homologs that are highly similar to the qry are not writen in this file.\n";

    #	close LOG;

}

sub getSimilarProt {
    use strict;

    #write the similar proteins into $similarProtFL
    #and return them as $homologToBeDelref

    #if #sameAA/QryLen > =95% and #sameAA/HomLen >=95%

    our $protSimilarityThr;    #by default, $protSimilarityThr = 95

    my (
        $homologRef, $numIdenticalAA, $IdentitySRef,
        $lengthRef,  $similarProtFL
    ) = @_;

    my $num_similarProt = 0;
    my $qryHomlogPair;

    my $homologToBeDelref;
    unlink $similarProtFL if ( -e $similarProtFL );
    open( sameProt, ">>$similarProtFL" )
      || die("Cannot open $similarProtFL:$!");
    foreach my $QRY ( keys %$homologRef ) {

        foreach my $homolog ( @{ $homologRef->{$QRY} } ) {
            $qryHomlogPair = "$QRY:$homolog";

            print LOG "\n\nQry-Homolog Pair: $qryHomlogPair\n";
            print LOG "Length: $lengthRef->{$QRY}:$lengthRef->{$homolog}\n";
            print LOG
              "num of Identical AA:  $numIdenticalAA->{$qryHomlogPair}\n";
            print LOG
"numIdenticalAA/length_homolog =  $numIdenticalAA->{$qryHomlogPair} / $lengthRef->{$homolog}\n";
            print LOG
"numIdenticalAA/length_Qry =  $numIdenticalAA->{$qryHomlogPair} / $lengthRef->{$QRY}\n";
            print LOG
              "protein Similarity Threshold: $protSimilarityThr * 0.01\n\n";
            if ( $numIdenticalAA->{$qryHomlogPair} / $lengthRef->{$homolog} >=
                   $protSimilarityThr * 0.01
                && $numIdenticalAA->{$qryHomlogPair} / $lengthRef->{$QRY} >=
                $protSimilarityThr * 0.01 )
            {

                if ( $IdentitySRef->{$qryHomlogPair} >= $protSimilarityThr ) {

                    my $ans = 1;
                    if ( $ans == 1 ) {
                        $num_similarProt = $num_similarProt + 1;
                        print sameProt
                          "$QRY and $homolog maybe the same protein.\n";
                        print LOG "$QRY and $homolog maybe the same protein.\n";
                        push @{ $homologToBeDelref->{$QRY} }, $homolog;

                    }
                }
            }
            else {
                print LOG "$qryHomlogPair are NOT the same protein.\n";

            }
        }
    }
    close sameProt;

    return ( $homologToBeDelref, $num_similarProt );
}

sub isSamespecies {
    my $taxonomyMap =
      shift @_
      ; #$taxonomyMap->{ $pdbID, $chain } = $TaxID;$taxonomyMap is returned by readP_chain_taxonomyLST
    my ( $pdbID1, $chainID1, $pdbID2, $chainID2 ) = @_;

    $pdbID1 = lc($pdbID1);
    $pdbID2 = lc($pdbID2);
    my $protein1 = "$pdbID1$chainID1";
    my $protein2 = "$pdbID2$chainID2";
    my $ANS;

    #	open( LOG, ">>$logFL" ) || die("Cannot open $logFL:$!");

    if ( !$taxonomyMap->{$protein1} ) {
        print LOG
"$protein1 (protein1:$protein1, protein2:$protein2) does not have taxonomy assigned. It is possible that $protein1 is obsolete from PDB, or the chain_taxonomyLST is not updated.\n";

        $ANS = 2;
    }
    elsif ( !$taxonomyMap->{$protein2} ) {
        print LOG
"$protein2 (protein1:$protein1, protein2:$protein2) does not have taxonomy assigned. It is possible that $protein2 is obsolete from PDB, or the chain_taxonomyLST is not updated, or this protein is synthetic.\n";
        $ANS = 2;
    }

    elsif ( $taxonomyMap->{$protein1} eq $taxonomyMap->{$protein2} ) {
        $ANS = 1;

    }
    else {
        $ANS = 0;    #not the same species
    }

    #	close LOG;
    return $ANS;

}

#------------------
sub readP_chain_taxonomyLST {

    our $pdb_chain_taxonomyLst;
    my $taxonomyMap;

    open( taxonomyLst, "<$pdb_chain_taxonomyLst" )
      || die("Cannot open $pdb_chain_taxonomyLst:$!\n");
    foreach (<taxonomyLst>) {
        s/[\n\r]//mg;

        if (/^\w{4}\t\w{1}\t/) {
            my ( $pdbID, $chain, $TaxID, $MOLECULE_TYPE, $SCIENTIFIC_NAME ) =
              split( /\t+/, $_ );
            my $protein = "$pdbID$chain";
            if ($TaxID) {

                $taxonomyMap->{$protein} = $TaxID;
            }
            else {
                $taxonomyMap->{$protein} = '';
            }
        }
    }
    close taxonomyLst;

    return $taxonomyMap;

}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------
sub mode {

    #this sub-function is for batch6. It is different from sub mode() of batch5.

    my ( $jobDIR, $lstFL, $scoreThr, $FullStatFL, $Mode, $qryCanBepredictedFL,
        $qryCannotBepredictedFL )
      = @_;

    print LOG "\n\n---- $Mode ...\n\n\n";

    #	my @taskIDs = &readTaskIDs($lstFL);

    my ( $qryCanbePredicted, $qryCannotbePredicted ) =
      &batchHomPRIP( $jobDIR, $lstFL, $scoreThr, $FullStatFL, $Mode );

    #write file
    &writeFL( $qryCanbePredicted,    $qryCanBepredictedFL );
    &writeFL( $qryCannotbePredicted, $qryCannotBepredictedFL );

    #	open( LOG, ">>$logFL" ) || die("Cannot open $logFL:$!");
    print LOG "\n$Mode finished.\n\n";

    #	close LOG;
    return ( $qryCanbePredicted, $qryCannotbePredicted );

}

#----------------------------------------------------------------------------------------------------------------------------------------------------------
sub batchHomPRIP {
    my $jobDIR = shift @_;
    my $qryLst = shift @_;

    my $scoreThr    = shift @_;    #0.5
    my $FullStatFL  = shift @_;
    my $Mode        = shift @_;
    my $scoreCutoff = shift @_;
    my $k           = shift @_;

    my @taskIDs = &readTaskIDs_again($qryLst);

    my @qryCanbePredicted;
    my @qryCannotbePredicted;

    my ( $CC_cutoff, $EvalueThr, $logEvalThr, $positiveScoreThr,
        $logAlignmentLengthThr, $prop_alignLenQryHomThr )
      = &getModeParameters2($Mode);

    print LOG "\nmode: $Mode; CC_cutoff: $CC_cutoff\n\n";

    foreach my $taskID (@taskIDs) {

        print LOG "\n\n ** Int prediction for $taskID **\n\n";
        my $ProteinToBePredictedDIR =
          "$jobDIR/$taskID";    #each query is given a specific directory
        my $predictionResultsDIR = "$ProteinToBePredictedDIR/predictionResults";

        my $statPredFL   = "$predictionResultsDIR/prediction.stat";
        my $predictionFL = "$predictionResultsDIR/$taskID.KNN.prediction";

        my $flag =
          &extractWeightedKNNpredict( $Mode, $taskID, $CC_cutoff, $FullStatFL );

        # collect qrys can be predicted and cannot be predicted
        if ( $flag == 0 ) {

            #$taskID can find homologs in $Mode
            push @qryCanbePredicted, $taskID;
            print LOG "$taskID can find homologs in $Mode mode.\n";
        }
        elsif ( $flag == 1 ) {
            push @qryCannotbePredicted, $taskID;
            print LOG "$taskID can NOT find homologs in $Mode mode.\n";
        }
    }
    return ( \@qryCanbePredicted, \@qryCannotbePredicted );

}

#-------------------------------------------------------------------------------------------------------------------------------------------------------
sub readTaskIDs_again {
    my $lstFL = shift @_;
    my @taskIDs;

    open( INPUT, "< $lstFL" ) || die("Cannot open  $lstFL:$!");
    foreach (<INPUT>) {
        s/[\n\r]//mg;
        if (/^(\w+)[,\s\t]{0,}(\w{1})[\s\t]{0,}$/) {

            #			1ay7, B
            push @taskIDs, "$1$2";
        }
    }
    close INPUT;

    print LOG "taskIDs in $lstFL: @taskIDs\n";

    #	print STDERR "@taskIDs\n\n";

    return @taskIDs;

}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------
sub getModeParameters2 {
    use Switch;
    my $Mode = shift @_;
    my $EvalueThr;
    my $logEvalThr;
    my $positiveScoreThr;
    my $logAlignmentLengthThr;
    my $prop_alignLenQryHomThr
      ;    #the threshold for prop_alignLenQry * prop_alignLenHom
    my $CC_cutoff;

    switch ($Mode) {

        #	SafeMode, TwilightMode, DarkMode
        case 'SafeMode' {
            $EvalueThr = '3.7201e-044'
              ; #obligate: log(1.9287e-022) = -50, trans: log(3.7201e-044) = -100, hetero_trans: log(3.7201e-044) = -100, S1_46: 1
            $positiveScoreThr = 0.60;    #obligate: 0.90, trans: 0.80, S1: 0.80
            $logAlignmentLengthThr =
              4;    #obligate: 4.5, trans: 5.1, hetero_trans: 5.6; S1: 3
            $prop_alignLenQryHomThr = 0.2
              ; # 0.8;    #the threshold for prop_alignLenQry * prop_alignLenHom

            $CC_cutoff = 0.7;
        }
        case 'TwilightMode1' {
            $EvalueThr = '1.9287e-022';
            $positiveScoreThr = 0.5;    #obligate: 0.45, trans: 0.60, S1:0.61
            $logAlignmentLengthThr =
              4;    #obligate: 3.8, trans: 4, hetero_trans: 4.5, S1: 2.5

            $prop_alignLenQryHomThr = 0.15
              ; # 0.4;    #the threshold for prop_alignLenQry * prop_alignLenHom
                #obligate: 0.6
            $CC_cutoff = 0.5;
        }
        case 'TwilightMode2' {
            $EvalueThr = 1;    #1;
            $positiveScoreThr =
              0.4;             #0.60;    #obligate: 0.45, trans: 0.60, S1:0.61
            $logAlignmentLengthThr =
              3;  #4;       #obligate: 3.8, trans: 4, hetero_trans: 4.5, S1: 2.5
            $prop_alignLenQryHomThr = 0.15
              ; # 0.2;    #the threshold for prop_alignLenQry * prop_alignLenHom
                #obligate: 0.6
            $CC_cutoff = 0.4;
        }

        case 'TwilightMode3' {
            $EvalueThr = 1;    #1;
            $positiveScoreThr =
              0.4;             #0.60;    #obligate: 0.45, trans: 0.60, S1:0.61
            $logAlignmentLengthThr =
              3;  #4;       #obligate: 3.8, trans: 4, hetero_trans: 4.5, S1: 2.5
            $prop_alignLenQryHomThr = 0.15
              ; # 0.2;    #the threshold for prop_alignLenQry * prop_alignLenHom
                #obligate: 0.6
            $CC_cutoff = 0.2;
        }
        case 'DarkMode' {
            $EvalueThr             = 1;
            $positiveScoreThr      = 0;
            $logAlignmentLengthThr = 0;
            $prop_alignLenQryHomThr =
              0;    #the threshold for prop_alignLenQry * prop_alignLenHom
            $CC_cutoff = 0.15;
        }
        else {
            die("Please set a valid mode: SafeMode, TwilightMode, DarkMode.\n");
        }

    }

    return ( $CC_cutoff, $EvalueThr, $logEvalThr, $positiveScoreThr,
        $logAlignmentLengthThr, $prop_alignLenQryHomThr );
}

#-------------------------------------------------------------------------------------------------------------------
sub extractWeightedKNNpredict {

    #!/usr/bin/perl -w

#Author: Xue, Li
#Date: May, 2008
#This script is part of HomoPPI pipeline
#Extract prediction for each residue of the query sequence, and write into a file, e.g. "1luk.prediction" under the directory "predictionResults"
#
#Input:  taskID.fasta.txt and output of KNN.pl
#Output:..data/taskID/predictionResults/taskID.KNN.prediction
#If this script is used as evalution purpose, that is, there exists $taskID.int file that stores the actual interface info, then combine the predicted and actual interface residue together into the output file.
#
#Usage: ./extractKNNpredict.pl taskID statistics_file k LOG_AlignmentLengthThr logEvalThr PositiveSThr
#statistics_file: all the qry-homolog pair infor
#k: the k in KNN
#alignmentLengthThreshold: homologs with alignment length <  alignmentLengthThreshold will not be used in KNN
#e.g., perl ./extractKNNpredict.pl 1a4yA 0.5 ../data/benchmark180/statistics_trans_benchmark180_wo_sameProteins.txt
#perl extractWeightedKNNpredict.pl 1hq1A 0.3 ../data/rb199/statistics_rb199_wo_sameProteins.txt

    use strict;
    use File::Basename;

    our $scoreThr;

    #variables
    my $Mode      = shift @_;
    my $taskID    = shift @_;
    my $CC_cutoff = shift @_;
    my $statFL    = shift @_;

    #	my $logFL     = shift @_;
    my $flag =
      0;   #0: this taskID can be predicted. 1: this taskID cannot be predicted.

    #file variables
    my $dirname = dirname($statFL);
    my $taskDIR = "$dirname/$taskID";
    my $fastaFL = "$taskDIR/$taskID.fasta.txt";
    my $intFL   = "$taskDIR/$taskID.int";         #interface file
    my $localAlignFL = "$taskDIR/seq_interface_homologsOfquerySeq.localAlign"
      ;                                           #input file of KNN.pl
    my $predictionResultsDIR = "$taskDIR/predictionResults";
    my $outputFL             = "$predictionResultsDIR/$taskID.KNN.prediction";
    mkdir $predictionResultsDIR unless ( -d $predictionResultsDIR );
    open( INPUT, "<$fastaFL" ) || die("Cannot open $fastaFL:$!");
    unlink $outputFL if ( -e $outputFL );
    open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL:$!");

    while (<INPUT>) {
        s/[\n\r]//mg;
        if (/>/) {
            print OUTPUT "\t\t\t\t$_\n";
            next;
        }
        if (/^[A-Za-z]+$/) {
            print OUTPUT "\t\t\t\t$_\n";
            next;
        }
    }
    close INPUT;
    print OUTPUT "prediction score:\t\t";
    close(OUTPUT);

    &KNN2_weighted( $CC_cutoff, $statFL, $localAlignFL )
      ;    # #output file: ../data/3ikhA/predict.tmp

    my $KNNoutputFL     = "$taskDIR/predict.tmp";
    my $predictionScore = &getKNNprediction($KNNoutputFL);

    open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL:$!");
    print OUTPUT "$predictionScore\n";
    close(OUTPUT);

    my $prediction = &getBinaryPrediction( $predictionScore, $scoreThr );

    open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL:$!");
    print OUTPUT "prediction:\t\t\t$prediction\n";
    close(OUTPUT);

    if ( -e $intFL ) {

        open( INPUT, "<$intFL" ) || die("Cannot open $intFL:$!\n");
        open( OUTPUT, ">>$outputFL" );
        foreach (<INPUT>) {
            if (/^[01\?]+$/) {
                print OUTPUT "actual:\t\t\t\t$_\n";
            }
        }
        close OUTPUT;
        close INPUT;
    }

    if ( $prediction =~ /^[\?,]+$/ ) {

        print LOG
"$taskID cannot find homologs in $Mode zone. No prediction is made.\n";

        $flag = 1;
    }

    print LOG
      "KNN prediction finished (KNN2() is used)!The output is $outputFL.\n";


    return $flag;

}

#------------------------------------------------------------------------------------------------------------------------------------------------------------
sub KNN2_weighted {

    #!usr/bin/perl -w

#Xue, Li
#May, 2008
#
#this script is part of HomoPPI pipeline.
# weighted version of KNN2.pl
#
#use the mean of K-nearest neighbour of the query sequence as prediction
#Only homologs with Similarity score > = $CC_cutoff will be used in predition.
#
#If no homologs has local alignment length larger than alignmentLengthThreshold, no prediction will be made.
#
#read statistics_$basename.txt for PositiveS, Eval,etc to determine which homolog to be used as template.
#
#Usage: perl ./KNN2_weighted.pl similarity_cutOff statisticsFL seq_interface_homologsOfquerySeq.localAlign k log_localAlignmentLen_Thr $logEvalThr $PositiveSThr
#$PositiveSThr : the threshold for mean of PositiveS_H and PositiveS_HP. range: [0-100]
#e.g.,
#perl ./KNN2_weighted.pl 0.5 ../data/trans212/statistics_trans212pairedChains_onlyTransInterfaces.txt ../data/trans212/1jiw/1jiw_I_P/1jiwP_P_I/seq_interface_homologsOfquerySeq.localAlign
#perl ./KNN2_weighted.pl  0.5 ../data/benchmark180/statistics_trans_benchmark180_wo_sameProteins.txt ../data/benchmark180/1a4yA/seq_interface_homologsOfquerySeq.localAlign
#perl ./KNN2_weighted.pl 0.5 ../data/hetero_trans_1137_van/statistics_hetero_trans_final_1137_wo_sameProteins.txt ../data/hetero_trans_1137_van/4fapB/seq_interface_homologsOfquerySeq.localAlign
#perl ./KNN2_weighted.pl 0.5 ../data/S1_46/statistics_S1_46_proteinChains_wo_sameProteins.txt  ../data/S1_46/2ivzA/seq_interface_homologsOfquerySeq.localAlign
#perl ./KNN2_weighted.pl 0.3 ../data/rb199/statistics_rb199_wo_sameProteins.txt ../data/rb199/1hq1A/seq_interface_homologsOfquerySeq.localAlign

    use File::Basename;
    use List::Util qw(sum);
    use List::Util qw[min max];

    my $CC_cutoff    = shift @_;
    my $statisticsFL = shift @_;
    my $alignFL      = shift @_;

    #	my $logFL        = shift @_;

    #my $k                     = shift @ARGV;
    #my $logAlignmentLengthThr = shift @ARGV;
    #my $logEvalThr            = shift @ARGV;
    #my $positiveScoreThr      = shift @ARGV;    #[0-1]
    #my $prop_alignLenQryHomThr = shift @ARGV;

    my $dirname       = dirname($alignFL);
    my $finalHomologs = "$dirname/final_homologs.txt";
    my $outputFL      = "$dirname/predict.tmp";
    unlink $outputFL if ( -e $outputFL );

    my $queryID =
      basename( dirname($alignFL) );    #will be used to search $statisticsFL
    my $homolog;
    my $totalLengthQry;
    my $alignmentLen;
    my $totallengthSbj;
    my $Evalue;
    my $Identities;
    my $Positives;
    my $start_S;
    my $end_S;
    my $start_Q;
    my $end_Q;
    my $localAlign_Q;
    my $localAlign_S;

    ; #flag whether no homologs has local alignment length larger than alignmentLengthThreshold.
    my %similarityScore;
    my %homologs_Seq; #to store sequences of all the homologs in the input files
    my %homologs_int
      ;    #to store interfaces of  all the homologs in the input files
    my $flag = 0
      ; #whether no homologs has local alignment length larger than alignmentLengthThreshold
    my $flag1 = 0;    #find a homolog header or not
    my @where;        #index for - in sequence
    my @prediction;

    #read statistics file
    my ( $Num_Int, $Length, $logEval, $PositiveS, $IdentityS, $alignLen,
        $aligLen_Query, $aligLen_Homolog )
      = &readStatisticsFL( $queryID, $statisticsFL );

    #if qry is peptide
    #if($Length->{$queryID} <= 150){
    #	$logAlignmentLengthThr=0.5*$logAlignmentLengthThr;
    #
    #}

    #get homolog IDs that meet the thresholds
    my @homologIDs = keys(%$logEval);    #1im9A|A:D,2dypA|A:D..
    my @finalHomologIDs;                 #the homologs that pass the thresholds
    my @similarityScores;
    foreach my $homolog (@homologIDs) {

        if ( $Num_Int->{$homolog} < 3 ) {

         #		print "$homolog has no int.\n";
         #if the homolog has no interface, it will not be used in the prediction
            next;
        }

        #sometimes there are multiple possible alignments generated by Blast
        #only use the first possible alignment as the alignment
        my $mean_logEval   = $logEval->{$homolog}->[0];
        my $mean_PositiveS = $PositiveS->{$homolog}->[0];
        my $alignmentLen   = $alignLen->{$homolog}->[0];
        my $aligLen_Qry    = $aligLen_Query->{$homolog}->[0];
        my $aligLen_Hom    = $aligLen_Homolog->{$homolog}->[0];

        #	if (   $mean_logEval <= $logEvalThr
        #		&& log($alignmentLen) >= $logAlignmentLengthThr
        #		&& $mean_PositiveS >= $positiveScoreThr * 100
        #		&& $aligLen_Query*$aligLen_Homolog>= $prop_alignLenQryHomThr)    #xue
        #	{

        my $intercept = -0.53162;
        my $a         = 0.00051917;
        my $b         = 0.00517;
        my $c         = 0.60002;
        my $d         = 0.08854;
        my $similarityScore =
          $intercept +
          $a * $mean_logEval +
          $b * $mean_PositiveS +
          $c * $aligLen_Qry * $aligLen_Hom +
          $d * log($alignmentLen);

        if ( $similarityScore >= $CC_cutoff ) {
            $similarityScore{$homolog} = $similarityScore;
            push @finalHomologIDs, $homolog;
            print LOG "Created Final homologs list\n";
            push @similarityScores, $similarityScore;
            print LOG "Created Similarity score list\n";
        }

    }
    my $katie = scalar(@finalHomologIDs);
    print LOG "Num of final homologs used in prediction: $katie\n";
    print LOG
"Final homologs and their similarity scores are saved in $finalHomologs.\n";
    open( OUT, ">" . $finalHomologs ) or die("Cannot open $finalHomologs: $!");

    for my $rasna ( 0 .. scalar @finalHomologIDs - 1 ) {
        my $temp = sprintf( "%.2f", $similarityScores[$rasna] );

        #print OUT "$finalHomologIDs[$rasna]\t$similarityScores[$rasna]\n";
        print OUT "$finalHomologIDs[$rasna]\t$temp\n";
    }
    close(OUT);

    if ( !@finalHomologIDs ) {

        if ( !defined $Length->{$queryID} ) {
            die("length for $queryID is not available:$!");
        }
        @prediction = ('?') x $Length->{$queryID};

    }
    else {

        #read $alignFL to get %homologs_int
        foreach my $homolog (@finalHomologIDs) {
            $homologs_int{$homolog} = &getHomologInt( $homolog, $alignFL );
        }

        #compare homologs
        if ( !keys %homologs_int ) {
            @prediction = ('?') x $Length->{$queryID};
        }

        else    #predict using KNN
        {
            my @sorted =
              sort { $similarityScore{$b} cmp $similarityScore{$a} }
              keys %similarityScore;    #Learning Perl: 15.4 Advanced Sorting
                #sort in the order of decreasing similarity score
                #$sored[0]='2pxvA'

            my @matrix
              ; #each row is an interface, the last element is the similarity score

            #		my $n = min( $k, scalar @sorted );    #  $n=min($k, $#sorted)

            for my $i ( 0 .. scalar @sorted - 1 ) {

                #		print "\t\t$similarityScore{$key}\t\t $key\n";
                if ( !defined $sorted[$i] ) {
                    die
                      "\n KNN2_weighted.pl: error here: i=$i; $queryID \n"; #xue
                        #				print "$sorted[$i]\n";#xue
                }    #xue

                my @tmp = split( //, $homologs_int{ $sorted[$i] } );
                my $similarScore = $similarityScore{ $sorted[$i] };
                push @tmp, $similarScore;
                push @matrix, [@tmp];
            }

            #multiply each element in @matrix by weight (Similarity score)
            my @col_sum =
              split( //, '?' x ( $#{ $matrix[0] } ) )
              ; #put the non-question-mark elements of the ith column of weighted_matrix in $column->[$i]
            my @sum_weight = split( //, '?' x ( $#{ $matrix[0] } ) );
            my @weighted_matrix;
            for my $x ( 0 .. $#matrix ) {
                my $weight = $matrix[$x][-1];    #use similarity score as weight
                for my $y ( 0 .. $#{ $matrix[$x] } - 1 ) {
                    if ( $matrix[$x][$y] eq '?' || $matrix[$x][$y] eq '-' ) {
                        $weighted_matrix[$x][$y] = '?';
                    }
                    else {

                        if ( $col_sum[$y] eq '?' ) {
                            $col_sum[$y] = 0;
                        }
                        if ( $sum_weight[$y] eq '?' ) {
                            $sum_weight[$y] = 0;
                        }

                        $weighted_matrix[$x][$y] = $matrix[$x][$y] * $weight;
                        $col_sum[$y] = $col_sum[$y] + $weighted_matrix[$x][$y];
                        $sum_weight[$y] = $sum_weight[$y] + $weight;
                    }
                }
            }

            #normalize @weighted_matrix by the sum of weights

            for my $i ( 0 .. ( scalar @col_sum - 1 ) ) {
                if ( $col_sum[$i] eq '?' ) {
                    push @prediction, '?';
                }
                else {
                    my $temp =
                      sprintf( "%.2f", $col_sum[$i] / $sum_weight[$i] );

                    #push @prediction, $col_sum[$i] / $sum_weight[$i];
                    push @prediction, $temp;

                }

            }

        }
    }

    my $predict = join ",", @prediction;

    open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL:$!");
    print OUTPUT "$predict";
    close OUTPUT;

    #	open( LOG, ">>$logFL" );
    print LOG "$outputFL is generated.\n";

    #	close LOG;
}

#------------------------------------------------------------------------------------------------------------------------------------
sub getKNNprediction {
    my $KNNoutputFL = shift @_;    #"$dirname/predict.tmp";
    my $predictionScore;
    open( KNNOUTPUT, "<$KNNoutputFL" )
      || die("Cannot open $KNNoutputFL:$!");
    foreach (<KNNOUTPUT>) {
        s/[\n\r]//mg;
        if (/^[\w\d\?\.\s\t\!,]+$/) {
            $predictionScore = $_;
        }
    }
    close KNNOUTPUT;
    return $predictionScore;
}

#--------------------------------------------------------------------------------------------------------------------------------------------------
sub readStatisticsFL {
    use strict;
    my $queryID      = shift @_;
    my $statisticsFL = shift @_;

    my $Num_Int;
    my $Length;
    my $logEval;
    my $PositiveS;
    my $IdentityS;
    my $alignLen;
    my $aligLen_Query;
    my $aligLen_Homolog;
    my $homologID;
    my $prevID;
    my @temp;

    my $flag = 0;

    open( INPUT, "<$statisticsFL" ) || die("Cannot open $statisticsFL:$!");
    foreach (<INPUT>) {

        #		print "$_";#xue
        s/[\n\r]//mg;
        if (/^>$queryID/) {
            $flag = 1;
            ( my $tmp, $Length->{$queryID}, my $tmp2, $Num_Int->{$queryID} ) =
              split( /\t/, $_ );
            next;
        }
        if ( $flag == 1 && />/ ) {

            #a different query. End of reading.
            last;
        }
        if ( $flag == 1 ) {
            if (/^(\w{5})\t/) {
                @temp                  = split( /\t/, $_ );
                $homologID             = $1;                  #1fs1D|D:C
                $Length->{$homologID}  = $temp[1];
                $Num_Int->{$homologID} = $temp[ 2 + 1 ];

            }
            elsif (/^\t+\d+/) {
                @temp      = split( /\t/, $_ );
                $homologID = $prevID;                         #1fs1D|D:C
            }
            if ( $temp[4] ne '' ) {
                push @{ $logEval->{$homologID} }, &LogEval( $temp[ 4 + 1 ] );
            }

            push @{ $PositiveS->{$homologID} },       $temp[ 5 + 1 ];
            push @{ $IdentityS->{$homologID} },       $temp[ 6 + 1 ];
            push @{ $alignLen->{$homologID} },        $temp[ 7 + 1 ];
            push @{ $aligLen_Query->{$homologID} },   $temp[ 8 + 1 ];
            push @{ $aligLen_Homolog->{$homologID} }, $temp[ 9 + 1 ];

            $prevID = $homologID;
            next;
        }

    }

    return ( $Num_Int, $Length, $logEval, $PositiveS, $IdentityS, $alignLen,
        $aligLen_Query, $aligLen_Homolog );

}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------
sub writeFL {
    my @prots    = @{ shift @_ };
    my $outputFL = shift @_;

    #	my $logFL    = shift @_;

    unlink $outputFL if ( -e $outputFL );
    open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL:$!");

    foreach (@prots) {
        print OUTPUT "$_\n";
    }
    close OUTPUT;

    #	open( LOG, ">>$logFL" ) || die("Cannot open $logFL:$!");
    print LOG "$outputFL is generated.\n";

    #	close LOG;

}

#----------------------------------------------------------------------------------------------------------------------------------------------------------
sub getQrys4Blank {

    #read qry IDs
    #These qry will be predicted by SVM.
    use strict;
    our $safe_filename_characters;
    my $qryHomFL = shift @_;

    #	my $logFL =shift @_;

    #	open(LOG, ">>$logFL")||die("Cannot open $logFL:$!");
    print LOG "Extracting Qrys for no predictions from HomPRIP..\n";

    #	close LOG;

    my @qryProtIDs;
    open( INPUT, "<$qryHomFL" )
      || die("Cannot open $qryHomFL:$!");
    foreach (<INPUT>) {

        s/[\n\r]//mg;
        if (/^[$safe_filename_characters]+$/) {
            my $qryProtID = $_;
            push @qryProtIDs, $qryProtID;
        }
    }
    close INPUT;
    return @qryProtIDs;
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
sub appendPrediction {

    use strict;
    use File::Copy;
    use File::Basename;

    my @taskIDs = @{ shift @_ };
    my $jobDIR  = shift @_;
    foreach my $taskID (@taskIDs) {

        #write the orginal weka output file into $predictionFL
        my $predictionResultsDIR = "$jobDIR/$taskID/predictionResults";

        mkdir($predictionResultsDIR) if ( !-d $predictionResultsDIR );
        my ($seq);
        my $seqFL = "$jobDIR/$taskID/$taskID.fasta.txt";
        $seq = &readFastaFL($seqFL);
        my $predictionFL =
          "$jobDIR/$taskID/predictionResults/$taskID.KNN.prediction";
        &writePredictionFL_Blank( $taskID, $seq, $predictionFL );

    }

}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub writePredictionFL_Blank {
    use strict;
    my $taskID          = shift @_;
    my $seq             = shift @_;
    my $outputFL        = shift @_;
    my @predictionScore = ();
    my @rounded         = ();
    my $prediction      = '?' x length($seq);
    for ( my $j = 0 ; $j < length($seq) ; $j++ ) {
        push( @predictionScore, '?' );
    }

    #for (my $i = 0; $i < scalar(@predictionScore); $i++){
    #	my $temp = sprintf(%.2f", $predictionScore[$i]);
    #	push(@rounded, $temp);
    #}
    #my $predictions = join( ',', @rounded);
    unlink $outputFL if ( -e $outputFL );
    my $predictions = join( ',', @predictionScore );

    open( OUTPUT, ">>$outputFL" ) || die("Cannot open $outputFL:$!");
    print OUTPUT "\t\t\t\t>$taskID\n";
    print OUTPUT "\t\t\t\t$seq\n";
    print OUTPUT "prediction score:\t\t$predictions\n";
    print OUTPUT "prediction:\t\t$prediction\n";
    close(OUTPUT);

    print LOG "$outputFL generated.\n";

}

#------------------------------------------------------------------------------------------------------------------------------------------------------------
sub LogEval {

    my $Evalue = shift @_;

    my $logEval;

    if ( $Evalue =~ /^[eE]{1}/ ) {
        $Evalue = '1' . $Evalue;
    }
    else {

        if ( $Evalue =~ /^[0\.\-]+$/ ) {

            #if ( $Evalue == 0 )
            $logEval = -450;
        }
        else {

            #			print "$Evalue";#xue
            $logEval = log($Evalue);
        }
    }

    return $logEval;
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------
sub getHomologInt {

    #get the int for $homolog from $alignFL

    my $homolog = shift @_;    #1im9A|A:D
    my $alignFL = shift @_;
    my $homologInt;
    my $totalLengthQry;
    my $alignmentLen;
    my $totallengthSbj;
    my $Evalue;
    my $Identities;
    my $Positives;
    my $start_S;
    my $end_S;
    my $start_Q;
    my $end_Q;
    my $localAlign_Q;
    my $localAlign_S;
    my @where;
    my %homologs_Seq;
    my $flag1 = 0;    #find a homolog header

    my ( $pdbIDchainID, $chain1, $chain2 ) = split( /[:\|]/, $homolog );

    open( INPUT, "<$alignFL" ) || die("Cannot open $alignFL\n");
    foreach (<INPUT>) {

        if (/^Query: (\d+) letters/) {
            $totalLengthQry = $1;
            next;
        }

#>2dypA|A:D|GroupID 41|Alignment Length 275|Sbjct Length 277|Sbjct RESI 2 - 276|Query RESI 1 - 275|Score =  479 bits (1232),  Expect = 7e-136, Identities = 83%, Positives = 89%
        if (
/>($pdbIDchainID)\|GroupID \d+\|Alignment Length (\d+)\|Sbjct Length (\d+)\|Sbjct RESI (\d+) - (\d+)\|Query RESI (\d+) - (\d+)\|Score =\s+[\d\.]+ bits \(\d+\),[\s\t]+Expect = ([\de\-\.]+),[\s\t]+Identities = (\d+)%, Positives = (\d+)%/
          )
        {

#			$flag = 0
#			  ; #whether this homolog has local alignment length longer than alignmentLengthThreshold
            $flag1 = 1;    #find a homolog header

            #		$homolog    = $1;
            $alignmentLen   = $2;
            $totallengthSbj = $3;
            $start_S        = $4;
            $end_S          = $5;
            $start_Q        = $6;
            $end_Q          = $7;
            $Evalue         = $8;
            $Identities     = $9;
            $Positives      = $10;

            next;
        }
        if ( /^([A-Z\-]+)[\n\r]{0,}$/ && $flag1 == 1 ) {

            #find the index for - in the seq $1
            @where = ();
            my $index = index( $1, '-' );

            while ( $index >= 0 ) {

                if ( $index >= 0 ) {
                    push @where, $index;
                }
                $index = index( $1, '-', $index + 1 );
            }

            $homologs_Seq{$homolog} = $1;
            next;
        }

        if ( /^([01\?\-]+)[\n\r]*$/ && $flag1 == 1 ) {
            $flag1 = 0;
            my $int = $1;

            #remove the interface sign that corresponds to -
            my @tempINT = split( //, $int );

            if (@where) {
                foreach (<@where>) {
                    $tempINT[$_] = '';
                }

            }
            $int = join( '', @tempINT );

            #add ? to the two ends
            my $multiX1 = "?" x ( $start_Q - 1 );    #$num_multiX question marks
            my $multiX2 = "?" x ( $totalLengthQry - $end_Q );
            $homologInt = $multiX1 . $int . $multiX2;
            last;
        }
    }

    return $homologInt;

}

#-------------------------------------------------------------------------------------------------------------------------------------------------------------

#the end
1;

#------------------------------------------------------------------------------------------------------------------------------------------------
