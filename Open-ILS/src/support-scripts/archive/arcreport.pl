#!/usr/bin/perl

use vars qw/$libpath/;
use FindBin qw($Bin);
BEGIN { $libpath="$Bin" };
use lib "$libpath";
use lib "$libpath/../libs";

use MARC::Record;
use MARC::File::XML (BinaryEncoding => 'UTF-8');
use MARC::Charset;
use DB_File;
#use MarcExport;

#use Convert::Cyrillic;
use DBI;
$| = 1;
my $DEBUG = $ARGV[0];

my $config_file='/openils/conf/db.config';

my %dbconfig = loadconfig($config_file);
my ($dbname, $dbhost, $dblogin, $dbpassword) = ($dbconfig{dbname}, $dbconfig{dbhost}, $dbconfig{dblogin}, $dbconfig{dbpassword});
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost",$dblogin,$dbpassword,{AutoCommit=>1,RaiseError=>1,PrintError=>0});

if ($dbh)
{
    $sqlquery = "select record as tcn, tag, subfield, value from metabib.real_full_rec where tag='931'";
    #$sqlquery.=" and record=918590";
    my $sth = $dbh->prepare("$sqlquery");
    $sth->execute();

    while (my ($id, $tag, $subfield, $value) = $sth->fetchrow_array())
    {
	$tags{$id}{$subfield}{$value}= "$value";

	unless ($known{$id})
	{
	    $count++;
	    $ids.="$id, ";
	    $known{$id}++;
	}
	$archive{$id}++;
    }

    $ids=~s/\,\s*$//g;
    print "Count1: $count\n" if ($DEBUG eq 2);
    exit(0) unless ($ids);

#    $sqlquery = "select b.id, marc, c.label from biblio.record_entry as b, asset.call_number as c where b.id in ($ids) and c.record=b.id and c.deleted='f'";
    #$sqlquery = "select b.id, b.marc, c.label, c.id from biblio.record_entry as b, asset.call_number as c, asset.copy as a where b.id in ($ids) and c.record=b.id and c.deleted='f' and a.id=c.id";
    $sqlquery = "select b.id, b.marc, c.label, c.id from biblio.record_entry as b, asset.call_number as c where b.id in ($ids) and c.record=b.id and c.deleted='f'";
#    $sqlquery.="and b.id=1004187";
    my $sth = $dbh->prepare("$sqlquery");
    $sth->execute();

    my %step2known;
    while (my ($id, $marc, $label) = $sth->fetchrow_array())
    {
        unless ($step2known{$id})
        {
            $reccount++;
            $ids.="$id, ";
        }
        $step2known{$id}++;

	$marc=~s/\r|\n/ /g;
	
	# <datafield tag="110" ind1="2" ind2=" "><subfield code="a">Christelijke Besturenbond.</subfield><subfield code="b">Barneveld.</subfield><subfield code="0">(NL-AMISG)54421</subfield></datafield>
	my $tmpmarc = $marc;
	my $line = 0;
	while ($tmpmarc=~s/<datafield.+?tag\=\"(\d+)\".+?>(.+?)<\/datafield>//sxi)
	{
	    my ($tag, $values) = ($1, $2);
	    my $DEBUG = 0;
	    print "$tag => $values\n" if ($DEBUG);
	    $line++;

	    # code="a">Tijdschrift voor Agologie.</subfield>
	    while ($values=~s/code\=\"(\w+)\">(.+?)<\/subfield>//sxi)
	    {
		my ($subfield, $value) = ($1, $2);
#		$value.=";;$id";
		# <datafield tag="110" ind1="2" ind2=" "><subfield code="a">Vereniging van Vrienden van het NBAS Bondshuis.</subfield>
		if ($subfield ne '0')
	 	{
	            print "$id $tag\$$subfield => $value\n" if ($DEBUG);
		    $info{$id}{$tag}{$subfield} = $value;
		    $maininfo{$id}{$line}{$tag}{$subfield} = $value;
		};
	    }
	}

	if ($label)
	{
	   $holdings{$id}{$label}.= $label.' ';
	};
    }

    if ($DEBUG eq 2)
    {
	open(file, "archive.last.txt");
	@arc = <file>;
	close(file);

	my %arc;
	foreach $str (@arc)
	{
	   # 1206850 |      1.84907332062721 | 1206850 |       |         |         |         |
	   $str=~s/\r|\n//g;
	   $str=~s/^\s+|\s+$//g;
	   my @items = split(/\s*\|\s*/, $str); 

	   if ($str=~/\|/)
	   {
	      my $thisID = $items[0];
	      $arc{$thisID}++ if ($thisID=~/\d+/);
	   };
	}

	foreach $id (sort keys %arc)
	{
	   unless ($step2known{$id})
	   {
	      print "$id\n";
	      $stepknown++;
	   };
	};
	print "Final: $stepknown\n";
	exit(0);
    }

    foreach $id (sort keys %known)
    {
	my %labels = %{$holdings{$id}};

        foreach $label (sort keys %labels)
	{
	    #print "$id;;$label;;";
	    my $name = $info{$id}{110}{'b'};
	    $name = $info{$id}{110}{'a'} unless ($name);

	    if (!$info{$id}{110}{a} && $info{$id}{100}{a})
	    {
		$name = $info{$id}{100}{a};
	    }
	    $name.= $info{$id}{111}{b}.' ' if ($info{$id}{111}{b});
	    if (!$info{$id}{111}{b} && $info{$id}{111}{a})
            {
                $name.= $info{$id}{111}{a}.' ';
            }
	    $name = $info{$id}{111}{b}.' ' if ($info{$id}{111}{b});

	    if ($info{$id}{110}{a} && $info{$id}{110}{b})
	    {
		$name = $info{$id}{110}{a}.' '.$info{$id}{110}{b};
	    }
	    $name=$info{$id}{245}{a} unless ($name=~/\S+/);

	    $item = "$label;;";
	    $name=~s/^\"//g;
	    $name = "\"No name for TCN $id\"" unless ($name);
	    my $arcfield = 931;
	    my %sublines = %{$maininfo{$id}};

	    foreach $line (sort keys %sublines)
	    {
	        my %subtags = %{$maininfo{$id}{$line}};
	
		my $found;
	        foreach $subfield (sort keys %subtags)
	        {
		    my %alltags = %{$subtags{$subfield}};
		    if ($subfield=~/931/)
		    {
			$item.="$arcfield.";
		        foreach $thisfield (sort keys %alltags)
		        {
		            $item.=" \&#177\;$thisfield $alltags{$thisfield}";
			    $found++;
		        };
		    }
	        }
		$item.="|" if ($found);
	    };

	    $name.=";;$id";
	    $archives{"$name;;$id"} = $item;
	    $arc{$id} = "$name;;$id";
	    $order{$name} = $id;
	};
    }

}

foreach $fullname (sort keys %order)
{
    my $id = $order{$fullname};
    my $item = $arc{$id};
    my ($name, $id) = split(/\;\;/, $item);
    $archive = $archives{$item};

    print "$name;;$id;;$archive\n";
}

#print "$reccount records\n";

sub loadconfig
{
    my ($configfile, $DEBUG) = @_;
    my %config;

    open(conf, $configfile);
    while (<conf>)
    {
        my $str = $_;
        $str=~s/\r|\n//g;
        my ($name, $value) = split(/\s*\=\s*/, $str);
        $config{$name} = $value;
    }
    close(conf);

    return %config;
}

