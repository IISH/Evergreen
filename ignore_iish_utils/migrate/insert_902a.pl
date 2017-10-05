#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use XML::LibXSLT;
use Data::UUID;
use MARC::Record;
use MARC::File::XML (BinaryEncoding => 'utf8');
use Unicode::Normalize;

use Carp qw( croak );

my $_stylesheet;
my $pid_file ;
my $source_dump ;

GetOptions(
    'stylesheet=s' => \$_stylesheet,
    'pid_file=s' => \$pid_file,
    'source_dump=s' => \$source_dump,
);

my $_parser = new XML::LibXML;
my $_xslt = new XML::LibXSLT;
my $stylesheet = $_xslt->parse_stylesheet(  $_parser->parse_file($_stylesheet) ) ;

#sudo -u evergreen psql -c 'select tcn,pid FROM pidservice.pids WHERE type=0' > /tmp/pids.txt
# COPY pids (tcn, pid, type) FROM stdin;
my %pids ;
open my $info, $pid_file or die "Could not open $!";
while ( my $line = <$info> )  {
    my @p = split(/\s\|\s/, $line);
    if ( scalar @p == 2) {
        $p[0] =~ s/\s//g;
        $p[1] =~ s/\s//g;
        die 'Must have a tcn for value ' . $p[0] . ' in line ' . $line unless ($p[0])  ;
        die 'Must have a pid for value ' . $p[1] . ' in line ' . $line unless ($p[1])  ;
        $pids{$p[0]} = $p[1] ;
    } else {
        # print "-- Cannot see tcn pid combination in $line";
    }
}
close $info;

# my $ug = new Data::UUID;
my $tab = "\t";
my $i = 0 ;

my $TCN_INDEX       = 0;
my $CREATOR_INDEX   = 1;
my $EDITOR_INDEX    = 2;
my $MARC_INDEX      = 12;
my $ACTOR_ID_ADMIN  = 1;
my $ACTOR_ID_MIEKE  = 57;

sub entityize {
    my($string, $form) = @_;
    $form ||= "";

    if ($form eq 'D') {
        $string = NFD($string);
    } else {
        $string = NFC($string);
    }

    # Convert raw ampersands to entities
    $string =~ s/&(?!\S+;)/&amp;/gso;

    # Convert Unicode characters to entities
    $string =~ s/([\x{0080}-\x{fffd}])/sprintf('&#x%X;',ord($1))/sgoe;

    return $string;
}

open $info, "<:encoding(UTF-8)", $source_dump or die "Could not open ${source_dump}: $!";
while( my $line = <$info> )  {

    if ( $i ) {
        if ( $line =~ m/^\\\.$/ ) {
            # We will stop the 902 insert now.
            $i = 0 ;
        } else {
            my @tmp = split($tab, $line);
            my $count = scalar @tmp;
            if ( $count eq 16 ) {

                my $tcn = $tmp[$TCN_INDEX];

                if ( $tcn != -1 ) {

                    # $tmp[$CREATOR_INDEX]    = $ACTOR_ID_MIEKE  if ( $tmp[$CREATOR_INDEX]   == $ACTOR_ID_ADMIN);
                    # $tmp[$EDITOR_INDEX]     = $ACTOR_ID_MIEKE  if ( $tmp[$EDITOR_INDEX]    == $ACTOR_ID_ADMIN);

		            my $pid = $pids{$tcn} || '10622' ;

                    my $result = $stylesheet->transform($_parser->parse_string($tmp[$MARC_INDEX]), XML::LibXSLT::xpath_to_string(pid => "$pid")) ;
                    $tmp[$MARC_INDEX] = entityize($stylesheet->output_as_chars($result));
                    $tmp[$MARC_INDEX] =~ s/\R//g ;
                    my $marc = MARC::Record->new_from_xml( $tmp[$MARC_INDEX], 'UTF8', 'XML') ;
                    unless ($marc->subfield('901', 'a') eq $tcn ) {
                        croak "Failed to parse string as XML with marc='$line' and tcn='$tcn'" ;
                    }
                    unless ($marc->subfield('902', 'a') eq $pid ) {
                        croak "Failed to parse string as XML with marc='$line' and pid='$pid'" ;
                    }
                    $line = join($tab, @tmp);
                }
            } else {
	            croak "Expect column count of 16 but got $count not correct for line: '$line'";
            }
        }
    } else {
    	if ( $line =~ m/^COPY record_entry \(id, creator, editor, source, quality, create_date, edit_date, active, deleted, fingerprint, tcn_source, tcn_value, marc, last_xact_id, owner, share_depth\) FROM stdin;$/ ) {
        	print "-- We will add the 902 from here.\n";
        	$i = 1 ;
	    }
    }

	print $line ;

}
close $info;


