#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use Data::Dumper;
use File::Path 'make_path';
use File::Spec;
use FindBin '$Bin';
use LWP::UserAgent;
use Getopt::Long;
use Bio::Phylo::Util::Logger ':levels';

# process command line arguments
my $outdir = "$Bin/../img/harvested";
my $infile = "$Bin/../data/Table_S2.tsv";
my $base   = "http://www.boldsystems.org/index.php/API_Tax/";
my $verbosity = WARN;
GetOptions(
	'outdir=s' => \$outdir,
	'infile=s' => \$infile,
	'base=s'   => \$base,
	'verbose+' => \$verbosity,
);

# instantiate logger
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);

# start reading the names list
$log->info("going to read names list from $infile");
open my $fh, '<', $infile or die $!;
while(<$fh>) {
	chomp;
	my ($name) = split /\t/, $_;
	next if $name =~ /Species/;
	eval {
		my @ids = get_taxon_id($name);
		for my $id ( @ids ) {
			get_images( $id => $name );
		}
	};
	warn $@ if $@;
}

sub get_images {
	my ( $id, $name ) = @_;
	$log->info("going to get images for $name (ID: $id)");
	
	# construct request, fetch response
	my $url = $base . '/TaxonData?dataTypes=images&taxId=' . $id;
	my $ua  = LWP::UserAgent->new;
	my $res = $ua->get($url);
	$log->debug("fetching: $url");
	
	# parse response
	if ( $res->is_success ) {
		my $imgbase = 'http://www.boldsystems.org/pics/_w300';
		my $content = $res->decoded_content;
		my $ref = decode_json( $content );
		$log->debug(Dumper($ref));		
		for my $img ( @{ $ref->{'images'} } ) {
		
			# prepare outdir
			my $imgpath = $img->{'image'};
			$imgpath =~ s/\\//;
			my $imgfile = "${outdir}/${name}/${imgpath}";			
			my ( $v, $d, $f ) = File::Spec->splitpath($imgfile);
			make_path($d) if not -d $d;
			
			
			# mirror image
			$log->info("going to download ${imgbase}/${imgpath} to ${imgfile}");
			my $imgurl = "${imgbase}/${imgpath}";
			my $imgres = $ua->mirror( $imgurl => $imgfile  );
			if ( not $imgres->is_success ) {
				warn $id; #, Dumper($res);
			}
		}		
	}
	else {
		warn "$id $res";
	}	
}

sub get_taxon_id {
	my $name = shift;
	$name =~ s/\s/+/g;
	
	# construct request, fetch response
	my $url  = $base . '/TaxonSearch?taxName=' . $name;
	my $ua   = LWP::UserAgent->new;
	my $res  = $ua->get($url);
	$log->debug("fetching: $url");
	
	# parse response
	if ( $res->is_success ) {
	
		# http://www.boldsystems.org/index.php/resources/api?type=taxonomy
		my $content = $res->decoded_content;				
		my $ref = decode_json( $content );
		$log->debug(Dumper($ref));
		
		# process results. if array: no results.
		my @ids;
		if ( ref $ref eq 'HASH' ) {
			for my $key ( keys %$ref ) {
				push @ids, $ref->{$key}->{'taxid'}
			}
		}
		else {
			$log->warn("no results for $name: ".Dumper($ref));
		}
		return @ids;
	}
	else {
		warn "$name $res";
	}
}
	

