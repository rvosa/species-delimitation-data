#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use GIS::Distance;
use GIS::Distance::Fast;
use Statistics::Descriptive;
use Scalar::Util 'looks_like_number';
use Bio::Phylo::Util::Logger ':levels';

# process command line arguments
my ( $infile, $outfile );
my $groupby = 'Species';
my $latcol  = 'Lat';
my $loncol  = 'Lon';
my $verbosity = WARN;
GetOptions(
	'infile=s'  => \$infile,
	'groupby=s' => \$groupby,
	'latcol=s'  => \$latcol,
	'loncol=s'  => \$loncol,
	'outfile=s' => \$outfile,
	'verbose+'  => \$verbosity,
);

# instantiate helper objects
my $stat = Statistics::Descriptive::Full->new();
my $gis  = GIS::Distance->new('Haversine');
my $log  = Bio::Phylo::Util::Logger->new(
	'-class' => 'main',
	'-level' => $verbosity,
);
my %in  = read_table($infile);
my %out = read_table($outfile);

# cluster by species
my %species;
for my $r ( @{ $in{'records'} } ) {
	if ( my $s = $r->{$groupby} ) {
		$species{$s} = [] if not $species{$s};
		push @{ $species{$s} }, $r;
	}
	else {
		$log->error("No value for '$groupby' in record:\n".Dumper($r));
	}
}

# iterate over species
my @columns = ( 'Average distance between samplings (km)', 'Stdev of distances between samplings (km)' );
push @{ $out{'header'} }, @columns;
SPECIES: for my $s ( keys %species ) {

	# find equivalent record in output table
	my ($r) = grep { $_->{$groupby} eq $s } @{ $out{'records'} };
	if ( not $r ) {
		$log->error("No output record for $s");	
		next SPECIES;
	}

	# fetch samplings
	my @m = @{ $species{$s} };		
	if ( @m > 1 ) {
		my @distances;
		SAMPLE1: for my $i ( 0 .. $#m - 1 ) {			
			my $lat1 = $m[$i]->{$latcol};
			my $lon1 = $m[$i]->{$loncol};
			if ( not looks_like_number $lat1 or not looks_like_number $lon1 ) {
				$log->warn("Non-numerical coordinates for sample ".($i+1).", species $s");
				next SAMPLE1;
			}						
			SAMPLE2: for my $j ( $i + 1 .. $#m ) {
				my $lat2 = $m[$j]->{$latcol};
				my $lon2 = $m[$j]->{$loncol};
				if ( not looks_like_number $lat2 or not looks_like_number $lon2 ) {
					$log->warn("Non-numerical coordinates for sample ".($j+1).", species $s");
					next SAMPLE2;
				}														
				my $dist = $gis->distance( $lat1,$lon1 => $lat2,$lon2 );
				push @distances, $dist->kilometers;
			}			
		}
		
		# compute summary statistics
		if ( @distances > 1 ) {
			$stat->add_data(@distances);		
			$r->{$columns[0]} = sprintf '%.2f', $stat->mean;
			$r->{$columns[1]} = sprintf '%.2f', $stat->standard_deviation;
			$stat->clear;
			$log->info("computed summary statistics for $s");
		}
		else {
			$log->warn("not enough distances to compute summary statistics for $s");
			$r->{$columns[0]} = 0;
			$r->{$columns[1]} = 'N/A';
		}
	}	
	else {		
		$log->warn("not enough samplings to compute distances for $s");
		$r->{$columns[0]} = 0;
		$r->{$columns[1]} = 'N/A';
	}
}

# write output
print join( "\t", @{ $out{'header'} } ), "\n";
for my $r ( @{ $out{'records'} } ) {
	print join( "\t", map { $r->{$_} } @{ $out{'header'} } ), "\n";
}

sub read_table {
	my $file = shift;
	$log->info("going to read TSV table $file");
	
	# start reading
	my ( @header, @records );
	open my $fh, '<', $file or die $!;
	LINE: while(<$fh>) {
		chomp;
		my @r = split /\t/, $_;
		next LINE unless $#r;
		
		# read column header
		if ( not @header ) {
			@header = @r;
			$log->debug("read ".scalar(@header)." column headers");
			next LINE;
		}
	
		# create and store record hash
		my %r = map { $header[$_] => $r[$_] } ( 0 .. $#r );
		push @records, \%r;	
	}
	$log->info("read ".scalar(@records)." data records from $file");

	# return as hash	
	return (
		'header'  => \@header, 
		'records' => \@records,
	);
}