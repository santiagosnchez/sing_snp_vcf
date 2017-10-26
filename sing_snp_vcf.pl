#!/usr/bin/perl

my $usage = "
USAGE:

sing_snp_vcf.pl <file_name.vcf> [ max_maf | random ]

Your filtered file will be saved in the current directory as: file_name.max_maf.vcf or file_name.random.vcf\n\n";

my $infile = $ARGV[0];
my $snp_mode = $ARGV[1];

if (length($infile) == 0 or 
	length($snp_mode) == 0 or 
	$ARGV[0] =~ m/^-{1,2}he{0,1}l{0,1}p{0,1}/){
	die $usage;
}
if ($snp_mode =~ m/^max_maf/ or $snp_mode =~ m/^random/){
	print "Selecting $snp_mode SNP\n";
} else {
	die "Second argument \"$snp_mode\" is invalid\n$usage";
}
my $outfile = $infile;
if ($infile =~ m/\.vcf\.gz$/){
	open IN, " gunzip -c $infile | " or die "$usage$!";
	$outfile =~ s/\.vcf\.gz$/\.$snp_mode\.vcf/;
	$outfile =~ s/^.*\///;
} else {
	open IN, "<", $infile or die "$usage$!";
	$outfile =~ s/\.vcf$/\.$snp_mode\.vcf/;
	$outfile =~ s/^.*\///;
}

open OUT, ">", $outfile;
print "Writing to $outfile\n";

my $al = 0;
local $| = 1;
while(<IN>){
	if (/^#/){
		print OUT $_;
		if (/^#CHROM/){
			$init = $.;
			%SNP = ();
			%AFS = ();
		}
	}
	else {
		++$al;
		print "Processing SNP $al\r";
		@DAT = split /\t/, $_;
		if ($. == ($init+1)){
			$chrom = $DAT[0];
		}
		BLOCK: { 
			if ($chom eq $DAT[0]){
				$pos = $DAT[1];
				$info = $DAT[7];
				$SNP{$pos} = $_;
				if ($snp_mode eq "max_maf"){
					@INFO = split /;/, $info;
					($af) = grep { /AF=/ } @INFO;
					$af =~ s/AF=//;
					$AFS{$pos} = $af;
				}
			} else {
				if ($snp_mode eq "max_maf"){
					@AAF = values %AFS;
					$max_maf = max(@AAF);
					($key_max_maf) = grep { $AFS{$_} eq $max_maf } keys %AFS;
					print OUT $SNP{$key_max_maf};
				} else {
					@POS = keys %SNP;
					print OUT $SNP{$POS[rand @POS]};
				}
				%SNP = ();
				%AFS = ();
				$chom = $DAT[0];
				redo BLOCK;
			}
		}
	}
}
close IN;
local $| = 0;
print "\nDone.\n";

sub max {
	@arr = @_;
	@arrs = sort {$b cmp $a} @arr;
	$max = $arrs[0];
	return $max;
}


