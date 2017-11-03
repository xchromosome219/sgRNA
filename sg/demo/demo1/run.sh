#!/bin/bash

#######################################
# step one demultipex
#######################################
cd /Users/haitao/Desktop/sg/demo1
perl demultiplex.pl --barcodes barcode.txt --1 R1.fq --2 R2.fq
#######################################



#######################################
# step two trimme each fastq files
#######################################
# unzip fastq file
gunzip sample1_R1.fastq.gz
# cutadapt to cut and trimme the data from 5'(only R1)
cutadapt -f fastq -q 10 -g GGACGAAACACC -o sample1_trimmed.fastq.gz sample1_R1.fastq
# cutadapt to cut and trimme the data from 3' (only R1)
cutadapt -f fastq -q 10 -a GTTTTAGAGCTAG -o sample1_2_trimmed.fastq.gz sample1_trimmed.fastq.gz
cat sample1_2_trimmed.fastq.gz > sample1_trimmed.fastq.gz
rm sample1_2_trimmed.fastq.gz

gunzip sample2_R1.fastq.gz
# cutadapt to cut and trimme the data from 5'(only R1)
cutadapt -f fastq -q 10 -g GGACGAAACACC -o sample2_trimmed.fastq.gz sample2_R1.fastq
# cutadapt to cut and trimme the data from 3' (only R1)
cutadapt -f fastq -q 10 -a GTTTTAGAGCTAG -o sample2_2_trimmed.fastq.gz sample2_trimmed.fastq.gz
cat sample2_2_trimmed.fastq.gz > sample2_trimmed.fastq.gz
rm sample2_2_trimmed.fastq.gz

gunzip sample3_R1.fastq.gz
# cutadapt to cut and trimme the data from 5'(only R1)
cutadapt -f fastq -q 10 -g GGACGAAACACC -o sample3_trimmed.fastq.gz sample3_R1.fastq
# cutadapt to cut and trimme the data from 3' (only R1)
cutadapt -f fastq -q 10 -a GTTTTAGAGCTAG -o sample3_2_trimmed.fastq.gz sample3_trimmed.fastq.gz
cat sample3_2_trimmed.fastq.gz > sample3_trimmed.fastq.gz
rm sample3_2_trimmed.fastq.gz

gunzip sample4_R1.fastq.gz
# cutadapt to cut and trimme the data from 5'(only R1)
cutadapt -f fastq -q 10 -g GGACGAAACACC -o sample4_trimmed.fastq.gz sample4_R1.fastq
# cutadapt to cut and trimme the data from 3' (only R1)
cutadapt -f fastq -q 10 -a GTTTTAGAGCTAG -o sample4_2_trimmed.fastq.gz sample4_trimmed.fastq.gz
cat sample4_2_trimmed.fastq.gz > sample4_trimmed.fastq.gz
rm sample4_2_trimmed.fastq.gz

gunzip sample5_R1.fastq.gz
# cutadapt to cut and trimme the data from 5'(only R1)
cutadapt -f fastq -q 10 -g GGACGAAACACC -o sample5_trimmed.fastq.gz sample5_R1.fastq
# cutadapt to cut and trimme the data from 3' (only R1)
cutadapt -f fastq -q 10 -a GTTTTAGAGCTAG -o sample5_2_trimmed.fastq.gz sample5_trimmed.fastq.gz
cat sample5_2_trimmed.fastq.gz > sample5_trimmed.fastq.gz
rm sample5_2_trimmed.fastq.gz
#######################################



#######################################
# step three generate read count tables
#######################################
gunzip *_trimmed.fastq.gz
mageck count -l MGLibA.txt -n table --sample-label sample1,sample2,sample3,sample4,sample5 --fastq sample1_trimmed.fastq sample2_trimmed.fastq sample3_trimmed.fastq sample4_trimmed.fastq sample5_trimmed.fastq
#######################################
