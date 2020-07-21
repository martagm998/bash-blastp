#!/bin/bash
#Author: Marta Garcia Mondejar
#This script is a university project

set -e
set -u

#HELP FUNCTION

function ayuda (){
echo -e "\e[31;1m-WELCOME TO THE HELP FUNCTION OF THIS SCRIPT- \e[0m \n"
echo "This script will help you use the blastp app"
echo -e "You should follow the next order \n"
echo -e "\e[1;36mUsage: ./marta_garcia.bash {input1} {input2} {identity} {coverage} \e[0m \n"
echo "Input1: FASTA file with the data"
echo "Input2: MULTIFASTA file"
echo "Identity: introduce the identity value"
echo -e "Coverage: introduce the coverage value \n"
echo "The BlastP results will be saved in the RESULTS folder"
echo -e "The introduced files will be saved in the DATA folder\n"
echo "Errors will be saved in the log file"
}

#TO ACCESS THE HELP WRITE --help or -h

for arg in "$@" 
do
        if [[ "$arg" == "--help"  ||  "$arg" == "-h" ]]; then
        ayuda
        exit
fi
done

#CONTROL OF ARGUMENTS

if [[ $# -le 3  ||  $# -ge 5 ]]; then
      echo "ERROR: invalid number of arguments. You should add 4."
      echo "For more help type --help o -h"

exit 1
fi

#ERASE THE LOG FILE

if [ -f log ]; then
        rm log
fi

#VARIABLES

file=$1
file2=$2
identidad=$3
coverage=$4


echo "`date `" > log
echo "$file es el archivo fasta usado" >> log
echo "$file2 es el archivo multi.fasta usado" >> log
echo "$identidad es el valor que ha dado para la identidad" >> log
echo "$coverage es el valor que ha dado para el coverage" >> log

#CHECK FASTA FILES IN FASTA FORMAT
#BY DOING 2 IFS, I COULD KNOW WHICH FILE GIVES ERROR. THATHS WHY I DONT USE &&.

if [[ $( cat $file | grep "^>" ) ]]; then
        if  [[ $( cat $file2 | grep "^>") ]]; then

        
        echo "How do you want to name the DATA and RESULTS folders?"
        read varname
        folderDestinoData=${varname}_DATA
        folderDestinoResults=${varname}_RESULTS
        mkdir $folderDestinoData $folderDestinoResults

        #COPY THE FILES TO THE FINAL FOLDERS

        cp $file $folderDestinoData
        cp $file2 $folderDestinoData

        else
        echo "ERROR: " $'\033[0;31m' $file2 "is not in fasta format."
        exit 1
        fi

else
echo "ERROR: " $'\033[0;31m' $file "is not in fasta format."
exit 1
fi

#BLASTP
#6, qsequid (query seq name), qcovs (query coverage), pident (identity), evalue, ssquid (subject seq).
#-out: save the results.
#-evalue: evalue inferior to 1e10-6.

blastp -query $file -subject $file2 -evalue "0.000001" -out result_blastp.tsv -outfmt "6 qseqid qcovs pident evalue sseqid" 2>> log

#DELETE THE .fasta FROM THE FILE NAME IN ORDER TO AVOID FUTURE ERRORS

filefinal=$(echo $file | cut -d '.' -f 1)

#FILTER THE BLASTP FILE

awk -v ident=$identidad -v cover=$coverage '{ if (($3 >= ident) && ($2 >= cover))print }' result_blastp.tsv > ${filefinal}_results.tsv  2>>log

#COPY THE FILE TO THE RESULTS FOLDER
cp ${filefinal}_results.tsv $folderDestinoResults


#STANDARD OUTPUT

echo "The fasta file is:" $'\033[1;36m' $file $'\033[0m'
echo "The multifasta file is:"$'\033[1;36m' $file2 $'\033[0m'
echo "The established identity value is:" $'\033[1;36m' $identidad $'\033[0m'
echo "The established coverage value is:" $'\033[1;36m' $coverage $'\033[0m'

hits=`awk 'END {print NR}' ${filefinal}_results.tsv` 
echo "Number of hits:"$'\033[1;36m' $hits $'\033[0m'

max_identity=`cut -f3 ${filefinal}_results.tsv | sort -n -r | head -n1`
min_identity=`cut -f3 ${filefinal}_results.tsv | sort -n | head -n1`
echo "Highest identity obtained: " $'\033[1;36m'$max_identity $'\033[0m'
echo "Lowest identity obtained: "$'\033[1;36m'$min_identity $'\033[0m'

max_coverage=`cut -f2 ${filefinal}_results.tsv | sort -n -r | head -n1`
min_coverage=`cut -f2 ${filefinal}_results.tsv | sort -n | head -n1`
echo "Highest coverage obtained: " $'\033[1;36m'$max_coverage $'\033[0m'
echo "Lowest coverage obtained: " $'\033[1;36m'$min_coverage $'\033[0m'

echo "All results are saved in: " $'\033[1;36m' ${filefinal}_results.tsv

#COPY THE LOG FILE WITH THE ERRORS TO THE RESULTS FOLDER
cp log $folderDestinoResults

