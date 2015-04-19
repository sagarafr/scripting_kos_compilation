#!/bin/bash

# CPU in use for the compilation
# You can change and take an other number (this command maximise)
declare -ix nb_cpu=`cat /proc/cpuinfo | head -13 | tail -1 | cut -d: -f2-2 | cut -d" " -f2-`

declare -x MAIN_DIRECTORY=`pwd`
declare -x NAME_NEW_BASHRC="new_bashrc"
declare -x NEW_BASHRC="$MAIN_DIRECTORY/$NAME_NEW_BASHRC"
declare -x OS=""

declare -arx OS_AVAILABLE=("ARCH")
declare -arx PACKAGE_MANAGER_SEARCH_AVAILABLE=("pacman -Q --search ARG")
declare -arx PACKAGE_MANAGER_INSTALL_AVAILABLE=("pacman -S ARG")

declare -arx PACKAGE_FOR_ARCH=("gcc" "git" "gawk" "patch" "bzip2" "tar" "make" "sed" "flex" "bison" "texinfo" "wget" "gettext" "elfutils" "libmpc" "mpfr" "gmp")

declare -arix EXIT_SCRIPT_VALUES=(255)

# Exit the script for some return
# USE : exit_the_script
# RETURN :
# NONE
function exit_the_script
{
	declare -ix return_value=$?
	for((cpt_exit_script_values=0 ; cpt_exit_script_values < ${#EXIT_SCRIPT_VALUES[*]} ; ++cpt_exit_script_values))
	do
		if [ $return_value -eq ${EXIT_SCRIPT_VALUES[$cpt_exit_script_values]} ]; then
			exit $?
		fi
	done
}

# Check the OS
# USE : check_os
# RETURN :
# 0 = OK / Find in OS_AVAILABLE
# -1 = NOK / Not supported
function check_os
{
	for((cpt_os_available=0 ; cpt_os_available < ${#OS_AVAILABLE[*]} ; ++cpt_os_available))
	do
		uname -a | grep ${OS_AVAILABLE[$cpt_os_available]} &> /dev/null

		if [ $? -eq 0 ]; then
			OS=${OS_AVAILABLE[$cpt_os_available]}
			return 0
		fi

	done

	return -1
}

# Check the librarys installed and install all missing librarys
# USE : check_library_package
# RETURN :
# 0 = OK / Success to install all missing package
# -1 = NOK / Not supported
function check_library_package
{
	declare -x package_manager_search=""
	declare -x package_manager_install=""
	declare -x missing_package=""

	# Check the OS var
	case $OS in
		ARCH)
			# Find the position of ARG in PACKAGE_MANAGER_SEARCH_AVAILABLE
			limit=`expr index "${PACKAGE_MANAGER_SEARCH_AVAILABLE[0]}" ARG`
			# Substr PACKAGE_MANAGER_SEARCH_AVAILABLE 0 -> limit ( before ARG )
			package_manager_search=${PACKAGE_MANAGER_SEARCH_AVAILABLE:0:$(($limit-1))}
			
			# Find the position of ARG in PACKAGE_MANAGER_INSTALL_AVAILABLE
			limit=`expr index "${PACKAGE_MANAGER_INSTALL_AVAILABLE[0]}" ARG`
			# Substr PACKAGE_MANAGER_INSTALL_AVAILABLE 0 -> limit ( before ARG )
			package_manager_install=${PACKAGE_MANAGER_INSTALL_AVAILABLE:0:$(($limit-1))}
			;;
		*)
			# Not init
			return -1
			;;
	esac

	# Check all packages
	for((cpt_package_for_arch=0 ; cpt_package_for_arch < ${#PACKAGE_FOR_ARCH[*]} ; ++cpt_package_for_arch))
	do
		# Do the search
		$package_manager_search "^${PACKAGE_FOR_ARCH[$cpt_package_for_arch]}$" &> /dev/null

		# Check if there are an error => no lines => not installed
		if [ $? -ne 0 ]; then
			missing_package="$missing_package ^${PACKAGE_FOR_ARCH[$cpt_package_for_arch]}$"
		fi
	done

	# Check the missing_package var
	if [ "$missing_package" != "" ]; then
		# Do the sudo command
		echo "sudo $package_manager_install $missing_package"
		sudo $package_manager_install $missing_package
		
		# TODO = if the user is not sudo do something
		if [ $? -eq 0 ]; then
			echo "No root password"
			return -2
		fi
	fi

	return 0
}

check_os
exit_the_script

echo $OS

check_library_package
exit_the_script

echo "All missing librarys installed"
