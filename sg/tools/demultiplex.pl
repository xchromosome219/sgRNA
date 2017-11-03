#!/usr/bin/perl -w

use strict;
use warnings;


use Getopt::Long;
use Pod::Usage;
use File::Basename;

#perl demultiplex.pl --barcodes barcode.txt --1 test_R1.fastq --2 test_R2.fastq
#zcat polyii-glu-t7-2_L001-unk_R1.fastq.gz | perl -e 'my $i=-2; my $count=0; while(<>){$i++; if($i%4==0 && /^ACAGTGCAC/){$count++;}} print $count,"\n";'

my %options;
$options{'suffix'} = '';
my $isPaired = 1;


GetOptions(\%options, 'barcodes=s', '1=s', '2=s', 'suffix=s', 'help|h') or die("Error in command line arguments\n");


if($options{'help'} || $options{'h'}){
	&pod2usage({EXIT => 2, VERBOSE => 2});
	#exit 1;
}


if(!$options{'barcodes'}){
	print STDERR "Error: Please provide the barcode file\n";
	&pod2usage({EXIT => 2, VERBOSE => 0});
}


if(!$options{'1'}){
	print STDERR "Error: Please provide the Read_1 file\n";
	&pod2usage({EXIT => 2, VERBOSE => 0});
}


if(!$options{'2'}){
	print STDERR "Warning: Read 2 file not provided. Assuming single end data\n";
	$isPaired = 0;
}


my $isGz = 0;
if($options{1}=~m/gz$/){
	$isGz=1;
}

#read barcode data:
my %barcodes = ();
my %files = ();

open(my $barFh, $options{'barcodes'}) or die "Cannot open file $options{'barcodes'}: $!";

while(<$barFh>){
	if(/^(\w+)\s+(\S+)\s*$/){
		my $bar = $1;
		my $name = $2;
		$bar = uc $bar;
		
		#check if the same file name is used for different barcodes
		if(exists $files{$name}){
			print "Error: Two different barcodes are using same sample name.
			$files{$name} : $name
			$bar : $name\n";
			die;
		}
		
		$files{$name} = $bar;
		
		$barcodes{$bar}->[0] = $options{'suffix'} eq '' ? $name : $name.'_'.$options{'suffix'};			#Sample name prefix
		#$barcodes{$bar}->[0] = $name.'_'.$options{'suffix'};			#Sample name prefix
		
		open($barcodes{$bar}->[1], "|gzip >$barcodes{$bar}->[0]_R1.fastq.gz") or die "Cannot create file $barcodes{$bar}->[0]_R1.fastq.gz: $!";			#R1 file
		
		if($isPaired){
			open($barcodes{$bar}->[2], "|gzip >$barcodes{$bar}->[0]_R2.fastq.gz") or die "Cannot create file $barcodes{$bar}->[0]_R2.fastq.gz: $!";			#R2 file
		}
		
		#this barcode length will be used to trim the sequence and qual line
		$barcodes{$bar}->[3] = length($1);
		$barcodes{$bar}->[4] = 0;			#counter for each barcode
	}
	elsif(/^\s*$/){
		next;
	}
	else{
		print "Wrong format is barcode file at line: $_";
		die;
	}
}

#All barcodes in regular expression
my $pattern = join("|", keys %barcodes);

$options{1}=~m/(.*)\.fastq.*/;
my $unknownR1 = basename($options{1});
$unknownR1 = 'unknown_'.$unknownR1;

my $unknownR2 = '';


$barcodes{'unknown'}->[0] = 'unknown'.'_'.$options{'suffix'};
open($barcodes{'unknown'}->[1], "|gzip >$unknownR1") or die "Cannot create file $unknownR1: $!";
$barcodes{'unknown'}->[3] = 0;				#barcode length for unknown sequences
$barcodes{'unknown'}->[4] = 0;				#counter for unknown sequences







#Read fastq data
open(my $fh1, $isGz ? "gzip -dc $options{1} |" : $options{1}) or die "Cannot open file $options{1}: $!";
my $fh2 = undef;

if($isPaired){
	$unknownR2 = basename($options{2});
	$unknownR2 = 'unknown_'.$unknownR2;
	open($barcodes{'unknown'}->[2], "|gzip >$unknownR2") or die "Cannot create file $unknownR2: $!";
	open($fh2, $isGz ? "gzip -dc $options{2} |" : $options{2}) or die "Cannot open file $options{2}: $!";
}

my ($p1, $p2, $outBar);

if($isPaired){
	#for paired end data
	while(1){
		if(eof($fh1)){
			last;
		}
		
		#read line1: headers
		$p1 = <$fh1>;
		$p2 = <$fh2>;
		
		if($p1=~m/^@\w+:\d+:[\w-]+(:\d+){4}\s\d+:(Y|N)/ && $p2=~m/^@\w+:\d+:[\w-]+(:\d+){4}\s\d+:(Y|N)/){
			#@SIM:1:FCX:1:15:6329:1045 1:N:0:2
			
			#read line 2: sequence
			my $sq1 = <$fh1>;
			my $sq2 = <$fh2>;
			if($sq1=~m/^($pattern)/){
				$outBar = $1;
				#trim from 5_prime end to remove barcode
				$p1 .= substr($sq1, $barcodes{$outBar}->[3]);
				$p2 .= substr($sq2, $barcodes{$outBar}->[3]);
			}
			elsif($sq2=~m/^($pattern)/){
				$outBar = $1;
				#trim from 5_prime end to remove barcode
				$p1 .= substr($sq1, $barcodes{$outBar}->[3]);
				$p2 .= substr($sq2, $barcodes{$outBar}->[3]);
			}
			else{
				$outBar = 'unknown';
				$p1 .= $sq1;
				$p2 .= $sq2;
			}
					
			#read line 3: +
			$p1 .= <$fh1>;
			$p2 .= <$fh2>;
			
			#read line 4: qual
			#trim the qual of 5_prime barcode
			$p1 .= substr(<$fh1>, $barcodes{$outBar}->[3]);
			$p2 .= substr(<$fh2>, $barcodes{$outBar}->[3]);
			
			print {$barcodes{$outBar}->[1]} $p1;
			print {$barcodes{$outBar}->[2]} $p2;
			$barcodes{$outBar}->[4]++;
		}
	}
}
else{
	#for single end
	while(1){
		if(eof($fh1)){
			last;
		}
		
		#read line1: headers
		$p1 = <$fh1>;
		
		if($p1=~m/^@\w+:\d+:[\w-]+(:\d+){4}\s\d+:(Y|N)/){
			#@SIM:1:FCX:1:15:6329:1045 1:N:0:2
			
			#read line 2: sequence
			my $sq1 = <$fh1>;
			if($sq1=~m/^($pattern)/){
				$outBar = $1;
				#trim from 5_prime end to remove barcode
				$p1 .= substr($sq1, $barcodes{$outBar}->[3]);
			}
			else{
				$outBar = 'unknown';
				$p1 .= $sq1;
			}
					
			#read line 3: +
			$p1 .= <$fh1>;
			
			#read line 4: qual
			#trim the qual of 5_prime barcode
			$p1 .= substr(<$fh1>, $barcodes{$outBar}->[3]);
			
			print {$barcodes{$outBar}->[1]} $p1;
			$barcodes{$outBar}->[4]++;
						
		}
	}
}

open(my $out, '>>','demultiplex.stats') or die "Cannot create file reads.stats: $!";


foreach(sort{$barcodes{$a}->[0] cmp $barcodes{$b}->[0]}keys %barcodes){
	close($barcodes{$_}->[1]);
	if($isPaired){
		close($barcodes{$_}->[2]);
	}
	
	print $out "$barcodes{$_}->[0]\t$barcodes{$_}->[4]\n";
}

close($out);
close($barFh);


__END__


=head1 NAME


=head1 SYNOPSIS

perl demultiplex.pl --barcodes <Barcode file> -1 <Mate1> -2 <Mate2> --suffix <suffix to add>

Help Options:

	--help	Show this scripts help information.

=head1 DESCRIPTION

Demultiplexing the FASTQ data with given barcodes


=head1 OPTIONS

=over 30

=item B<--barcodes>

[STR] Barcode file

=item B<--1>

[STR] Forward read file

=item B<--2>

[STR] Reverse read file (Optional)

=item B<--suffix>

[STR] Sample name suffix to add (Optional)

=item B<--help>

Show this scripts help information.

=back


=cut

