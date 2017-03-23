#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use File::Path 'make_path';
use File::Spec;
use FindBin '$Bin';
use LWP::UserAgent;
use Getopt::Long;

# process command line arguments
my $outdir = "$Bin/../img/harvested";
my $infile = "$Bin/../data/Table_S2.tsv";
my $base   = "http://www.boldsystems.org/index.php/API_Tax/";
GetOptions(
	'outdir=s' => \$outdir,
	'infile=s' => \$infile,
	'base=s'   => \$base,
);

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
	warn $@;
}

sub get_images {
	my ( $id, $name ) = @_;
	
	# construct request, fetch response
	my $url = $base . '/TaxonData?dataTypes=images&taxId=' . $id;
	my $ua  = LWP::UserAgent->new;
	my $res = $ua->get($url);
	
	# parse response
	if ( $res->is_success ) {
		my $imgbase = 'http://www.boldsystems.org/pics/_w300';
		my $content = $res->decoded_content;
		my $ref = decode_json( $content );		
		for my $img ( @{ $ref->{'images'} } ) {
		
			# prepare outdir
			my $imgpath = $img->{'image'};
			$imgpath =~ s/\\//;
			my $imgfile = "${outdir}/${name}/${imgpath}";			
			my ( $v, $d, $f ) = File::Spec->splitpath($imgfile);
			make_path($d) if not -d $d;
			
			
			# mirror image
			my $imgurl  = "${imgbase}/${imgpath}";
			my $imgres  = $ua->mirror( $imgurl => $imgfile  );
			if ( not $imgres->is_success ) {
				warn "$id $res";
			}
		}		
	}
	else {
		warn "$id $res";
	}	
}

sub get_taxon_id {
	my $name = shift;
	
	# construct request, fetch response
	my $url  = $base . '/TaxonSearch?taxName=' . $name;
	my $ua   = LWP::UserAgent->new;
	my $res  = $ua->get($url);
	
	# parse response
	if ( $res->is_success ) {
	
		# http://www.boldsystems.org/index.php/resources/api?type=taxonomy
		my $content = $res->decoded_content;				
		my $ref = decode_json( $content );
		my @ids;
		for my $key ( keys %$ref ) {
			push @ids, $ref->{$key}->{'taxid'}
		}
		return @ids;
	}
	else {
		warn "$name $res";
	}
}
	

