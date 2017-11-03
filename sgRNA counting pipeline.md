#sgRNA counting pipeline I

**First things first, sharing is an excellent way to tap everyone's potential by lowering the barriers.**

Authors: **Haitao Wang**,  **Jimmy Zeng**, **Lakhansing Pardeshi**



###**Step one: Software installation**

**Description:**

**[cutadapt](http://cutadapt.readthedocs.io/en/stable/guide.html)** for cutting **barcode** or **adaptor** in .fastq or .fq file

**[mageck](https://sourceforge.net/p/mageck/wiki/Home/)** for counting **activtion**/**inhibition**/**knowout** sgRNA reads

```sh
# Before install cutadapt you should install Conda, Conda can help you install bio software automatically, to make life easy.
# Conda installation
https://conda.io/docs/user-guide/install/macos.html#install-macos-silent

wget http://repo.continuum.io/miniconda/Miniconda3-3.7.0-Linux-x86_64.sh -O ~/miniconda.sh
bash ~/miniconda.sh -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"

conda config --add channels bioconda
# Cutadapt installation
conda install -c bioconda cutadapt
# MAGeCK installation
conda install -c bioconda mageck

# test whether installed or not
cutadapt -h # help info to check useage
mageck -h # help info to check useage
```



###**Step two: Demultipex**

**Description:**

based on **index** or **barcodes** to deconstruct from a mix fastq file

`demultiplex.pl` this tool created by **[Lakhansing Pardeshi](https://fhs.umac.mo/staff/research-staff/) from [Chris](https://fhs.umac.mo/staff/academic-staff/chris-koon-ho-wong/) lab** 

Usage

`perl demultiplex.pl --barcodes barcodes.txt --1 R1.fq --2 R2.fq --suffix <suffix to add>`

```sh
# prepare barcodes.txt look like this
TAAGTAGAG	HK112
ATACACGATC	HK113
GATCGCGCGGT	HK114
CGATCATGATCG	HK115
TCGATCGTTACCA	HK116
ATCGATTCCTTGGT	HK117
```



###**Step three** trimme each fastq file for future sg counting

**Description:**

**LentiCRISPRv2** All plasmids have the same overhangs after BsmBI digestion and the same oligos can be used for cloning into lentiCRISPRv2, lentiGuide-Puro or lentiCRISPRv1.

5' arm: ……<u>GGACGAAACACCG</u> **20bp-sg-sequence**  <u>GTTTTAGAGCTAG</u>…… 3' arm

![Screen Shot 2017-11-03 at 10.40.43 AM](/Users/haitao/Desktop/Screen Shot 2017-11-03 at 10.40.43 AM.png)

```sh
# Check the CRISPR-Cas9 seq reads using 5' and 3' sequence beside sg sequence
grep --color=auto GGACGAAACACC CC1-F01_1_R1.fastq | head
grep --color=auto GTTTTAGAGCTAG CC1-F01_1_R1.fastq | head
```

Trimming seq CRISPR-Cas9 knockout screening (**usually we only use R1 in sg sequencing data**)

(compare R1 and R2, R1 have more target info than R2.)

![Screen Shot 2017-11-03 at 11.02.49 AM](/Users/haitao/Desktop/Screen Shot 2017-11-03 at 11.02.49 AM.png)

```sh
# Trimming seq CRISPR-Cas9 knockout screening
### CRISPR-Cas9 knockout system (All plasmids have the same overhangs after BsmBI digestion and the same oligos can be used for cloning into lentiCRISPRv2, lentiGuide-Puro or lentiCRISPRv1)

### fq.R1 TCTTGTGGAAAGGACGAAACACCG - xxxxxxxxxxxxxx - GTTTTAGAGCTAGAAATAGCAAGTTAAAATAAGGCTAGTCCGTTATCAACTTGAAAAAGTGGCACCGAGTCGGTGCTTTTTTGAATTCGCTAGCTAG

### fq.R2 CTAGCTAGCGAATTCAAAAAAGCACCGACTCGGTGCCACTTTTTCAAGTTGATAACGGACTAGCCTTATTTTAACTTGCTATTTCTAGCTCTAAAAC - xxxxxxxxxxxxxx - CGGTGTTTCGTCCTTTCCACAAGA

# cutadapt to cut and trimme the data from 5'(only R1)
cd /PATH/
cutadapt -f fastq -q 10 \
-g GGACGAAACACC \
-o sample_1_trimmed.fastq.gz \
/PATH/sample_R1.fastq # only R1

# cutadapt to cut and trimme the data from 3' (only R1)
cutadapt -f fastq -q 10 \
-a GTTTTAGAGCTAG \
-o /PATH/sample_2_trimmed.fastq.gz \
/PATH/sample_1_trimmed.fastq.gz

cat /PATH/sample_2_trimmed.fastq.gz > /PATH/sample_trimmed.fastq.gz
rm /PATH/sample_1_trimmed.fastq.gz
rm /PATH/sample_2_trimmed.fastq.gz
```



###**Step four**: sg counting

**Method I:**

1. Raw Count sgRNA

`fastqgz_to_counts.py` this tool created by [mhorlbeck](https://github.com/mhorlbeck)

Usage (note: under python2.7; have to put required input files order like: 1. library; 2. output-path, 3. fastq files)

`python fastqgz_to_counts.py --trim_start 1 --trim_end 21 <library.fasta> <output/path> <all/sg.fastq.gz> `

library

```sh
>0610007P14Rik_TCCTGAATGTGTTACGAAGC
tcctgaatgtgttacgaagc
>0610007P14Rik_GGTCGGGCTCCGGTACCTAG
ggtcgggctccggtacctag
>0610007P14Rik_GCCAGCTTCGTAACACATTC
gccagcttcgtaacacattc
>0610009B22Rik_TCATCATGCTGCATGACGTG
tcatcatgctgcatgacgtg
>0610009B22Rik_ATTCAATGAGTGGTTCGTCT
attcaatgagtggttcgtct
>0610009B22Rik_TCGTCACGGCTGGGCACATG
tcgtcacggctgggcacatg
>0610009D07Rik_TACACTCTGATTTGACGAAT
tacactctgatttgacgaat
```

Run

```sh
# count sgRNA python fastqgz_to_counts.py library-fasta output-path sg-fastq
python fastqgz_to_counts.py -p 16 \
--trim_start 1 --trim_end 21 \
GeckoV2_MGLib_A.fasta \
/output \
*trimmed.fastq.gz
```

Output

```sh
# count file have two columns, symbol and count
0610009O20Rik_CTGTGCCAAGAGCGTTCAGC	0
0610009O20Rik_TGGGTTTGGGCGTTATCCCA	0
0610010B08Rik_CGTGCATGTGAACTTCACTC	22
0610010B08Rik_GACTTCTAGAAGTTTGAAAA	6
0610010B08Rik_TATAGCTGTGAGATTCTTAT	0
```

2. Raw Count merge to table

`merged_table.pl` this tool created by [Jimmy](https://fhs.umac.mo/staff/research-staff/) and [haitao](https://fhs.umac.mo/staff/research-staff/)

Usage (note: can only merge files which include same row names and numbers )

`perl merged_table.pl <file1> <file2> <file3>...`

```sh
# merge selected files
perl merged_table.pl <file1> <file2> <file3>
# or All files
perl merged_table.pl /output/*
```

Output

```sh
# count file
sgRNA	Gene	CC1-F01	CC1-F02	CC1-F03	CC1-F04	CC1-F05
MGLibA_57638	Usp50	3	2	245	15	4
MGLibA_2481	Ablim1	10	12	5	18	6
MGLibA_18840	Foxo6	14	24	24	98	32
MGLibA_20534	Gm13040	1	505	3	7	2
MGLibA_42555	Prame	1	0	2	5	0
MGLibA_10739	Clec3b	18	621	32	122	38
MGLibA_36174	Olfr127	9	16	11	61	23
MGLibA_58314	Vmn1r238	10	6	6	69	23
MGLibA_24769	Hp1bp3	2	5	5	19	3
```

3. Normalize counts table (by total counts - size factor)

```sh
# add one more column named 'gene' for annotation
# sgRNA Gene sample1 sample2 ...
mageck count \
-k merged.txt \
-n /output/merged \
--norm-method total
```

Output

```sh
# Normalized count file by size factor
sgRNA	Gene	CC1-F01	CC1-F02	CC1-F03	CC1-F04	CC1-F05
MGLibA_57638	Usp50	13.88454104	5.200697141	893.8208094	9.225439438	8.905259711
MGLibA_02481	Ablim1	46.28180348	31.20418285	18.24124101	11.07052733	13.35788957
MGLibA_18840	Foxo6	64.79452487	62.40836569	87.55795684	60.27287099	71.24207769
MGLibA_20534	Gm13040	4.628180348	1313.176028	10.9447446	4.305205071	4.452629855
MGLibA_42555	Prame	4.628180348	0	7.296496403	3.075146479	0
MGLibA_10739	Clec3b	83.30724627	1614.816462	116.7439425	75.0335741	84.59996725
MGLibA_36174	Olfr127	41.65362313	41.60557713	40.13073022	37.51678705	51.20524334
MGLibA_58314	Vmn1r238	46.28180348	15.60209142	21.88948921	42.43702141	51.20524334
MGLibA_24769	Hp1bp3	9.256360696	13.00174285	18.24124101	11.68555662	6.678944783
```



**Method II:**

Using mageck **one step** `count` function to count, merge and normalize data

Usage

`mageck count -l library.txt -n <output> --sample-label name1,name2,name3 —fastq 01_trimmed.fastq 02_trimmed.fastq 03_trimmed.fastq`

Library

```sh
#  MGLibA.txt mouse library A looks like:
MGLibA_00001	TCCTGAATGTGTTACGAAGC	0610007P14Rik
MGLibA_00002	GGTCGGGCTCCGGTACCTAG	0610007P14Rik
MGLibA_00003	GCCAGCTTCGTAACACATTC	0610007P14Rik
MGLibA_00004	TCATCATGCTGCATGACGTG	0610009B22Rik
MGLibA_00005	ATTCAATGAGTGGTTCGTCT	0610009B22Rik
```

Run

```sh
mageck count -l MGLibA.txt \
-n /Users/haitao/Desktop/sgRNA/fq \
--sample-label CC1-F01,CC1-F02,CC1-F03 \
--fastq CC1-F01_trimmed.fastq CC1-F02_trimmed.fastq CC1-F03_trimmed.fastq
```

Output

```sh
# Normalized count file by size factor
sgRNA	Gene	CC1-F01	CC1-F02	CC1-F03	CC1-F04	CC1-F05
MGLibA_57638	Usp50	13.88454104	5.200697141	893.8208094	9.225439438	8.905259711
MGLibA_02481	Ablim1	46.28180348	31.20418285	18.24124101	11.07052733	13.35788957
MGLibA_18840	Foxo6	64.79452487	62.40836569	87.55795684	60.27287099	71.24207769
MGLibA_20534	Gm13040	4.628180348	1313.176028	10.9447446	4.305205071	4.452629855
MGLibA_42555	Prame	4.628180348	0	7.296496403	3.075146479	0
MGLibA_10739	Clec3b	83.30724627	1614.816462	116.7439425	75.0335741	84.59996725
MGLibA_36174	Olfr127	41.65362313	41.60557713	40.13073022	37.51678705	51.20524334
MGLibA_58314	Vmn1r238	46.28180348	15.60209142	21.88948921	42.43702141	51.20524334
MGLibA_24769	Hp1bp3	9.256360696	13.00174285	18.24124101	11.68555662	6.678944783
```



### **Step five**: group sample comparison

**Description:**

**Comparison between samples**

MAGeCK has different commands:

`test` (if you already have count tables)

`count` (if you want to generate count tables from fastq files)

`run` (combine both test and count)

`pathway` (if you want to do the pathway test)

count file: sample.txt

```
sgRNA	Gene	initial1	initial2	final1	final2
A1CF_m52595977	A1CF	213	274	883	175
A1CF_m52596017	A1CF	294	412	1554	1891
AAAS_m53714382	AAAS	704	671	799	1426
AAAS_m53715169	AAAS	651	627	797	1690
AAAS_m53715176	AAAS	545	89	392	664
AAK1_m69870049	AAK1	364	465	693	2006
AATF_m35306444	AATF	449	456	1396	1402
AATF_m35306475	AATF	493	612	1102	537
```

Run

```sh
mageck test \
# Raw Count tables
-k sample.txt \
# Treatment sample labels
-t final1,final2 \
# Control sample labels
-c initial1,initial2 \
-n Output # Output labels
```

Output

![Screen Shot 2017-11-03 at 11.58.07 AM](/Users/haitao/Desktop/Screen Shot 2017-11-03 at 11.58.07 AM.png)



### Step Six**: sg downstream analysis

**coming soon**

