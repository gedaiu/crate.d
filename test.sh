#!bin/bash
bold=`tput bold`
normal=`tput sgr0`

echo -e "\033[35m${bold}\n\n*************\nRunning tests:${normal} \033[0m ";

dub test || { echo 'library test failed' ; exit 1; }

for d in tests/*/ ; do
	echo -e "\n\n\033[34m${bold}$d${normal}\033[0m ";

	cd $d;

	dub test || { echo 'test failed' ; exit 1; }

	cd ../../;
done



echo -e "\n\n\n\033[35m${bold}Building examples:${normal} \033[0m ";

for d in examples/*/ ; do
	echo -e "\n\n\033[34m${bold}$d${normal}\033[0m ";

	cd $d;

	dub build || { echo 'build failed' ; exit 1; }

	cd ../../;
done