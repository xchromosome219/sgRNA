#!/usr/bin/perl
 
my %hash;
my $header = "Gene";
foreach my $i ( 0..@ARGV-1){
        $header .= "\t$ARGV[$i]";
        open I,"$ARGV[$i]";
        while(<I>){
                chomp;
                my($gene_num,$num) = split;
                $hash{$gene_num} .= "$num\t";
        }
}
print $header,"\n";
foreach $i (keys %hash){
        print "$i\t$hash{$i}\n";
}