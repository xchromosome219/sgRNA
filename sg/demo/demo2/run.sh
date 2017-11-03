#!/bin/bash

# group_comparison

cd /Users/haitao/Desktop/sg/demo2 

mageck test -k group_comparison.txt -t final1,final2 -c initial1,initial2 -n testrun

#or
#mageck test -k group_comparison.txt -t 2,3 -c 0,1  -n testrun

    
