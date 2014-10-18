#!bin/bash
bold=`tput bold`
normal=`tput sgr0`

echo -e "\033[34mRunning tests: ";

for d in tests/*/ ; do


	echo -e "\n\n\033[34m${bold}$d${normal}\033[0m ";
    
	cd $d;

	dub;

	cd ..ß/../;
done