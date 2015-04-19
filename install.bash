#!/bin/bash

### CPU ###
# CPU in use for the compilation
# You can change and take an other number (this command maximise)
declare -ix nb_cpu=`cat /proc/cpuinfo | head -13 | tail -1 | cut -d: -f2-2 | cut -d" " -f2-`

### GIT ###

declare -x KOS_REPO="git.code.sf.net/p/cadcdev/kallistios"
declare -x KOS_PORTS_REPO="git.code.sf.net/p/cadcdev/kos-ports"
declare -ix GIT_DOWNLOAD_MODE=0

### FOLDER ###

declare -x MAIN_FOLDER=`pwd`

# TO MODIFY IF YOU WANT BEGIN
# 0 = no sudo power needed
# 1 = sudo power needed
declare -ix REGULAR_FOLDER=0

declare -xr DC_CHAIN_INSTALL_FOLDER_NAME="dreamcast_chain"
declare -xr DC_CHAIN_INSTALL_PATH="$MAIN_FOLDER/$DC_CHAIN_INSTALL_FOLDER_NAME/"

declare -xr NAME_NEW_BASHRC="new_bashrc"
declare -xr KOS_FOLDER_NAME="kos"
declare -xr KOS_PORTS_FOLDER_NAME="kos-ports"
# TO MODIFY IF YOU WANT END

declare -xr NEW_BASHRC="$MAIN_FOLDER/$NAME_NEW_BASHRC"

declare -xr KOS_PORTS_GIT_MODULES_FILE=".gitmodules"
declare -xr KOS_DC_CHAIN_FOLDER_NAME="$MAIN_FOLDER/$KOS_FOLDER_NAME/utils/dc-chain"
declare -xr DC_CHAIN_DEFAULT_PATH="/opt/toolchains/dc/"

### OS ###

declare -x OS=""
declare -arx OS_AVAILABLE=("ARCH")
declare -arx PACKAGE_MANAGER_SEARCH_AVAILABLE=("pacman -Q --search ARG")
declare -arx PACKAGE_MANAGER_INSTALL_AVAILABLE=("pacman -S ARG")
declare -arx PACKAGE_FOR_ARCH=("gcc" "git" "gawk" "patch" "bzip2" "tar" "make" "sed" "flex" "bison" "texinfo" "wget" "gettext" "elfutils" "libmpc" "mpfr" "gmp")

### SCRIPT VALUE ###

# 255 = OS
# 254 = INTERNET
# 253 = FUNCTION BAD USE
# 252 = SED PB
declare -arix EXIT_SCRIPT_VALUES=(255 254 253 252)

### SCRIPT ERROR ###

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
			exit $return_value
		fi
	done
}

### TOOLS ###

# Give a path with an escape character before /
# USE : add_escape_character_for_path path
# Return value :
#	string with characters "/" are escape = OK
#	ERROR MUST HAVE AN ARGUMENT = ERROR / the fonction must have an argument
function add_escape_character_for_path
{
	string_path_escape="";
	string_path=$1;
	# echo ${#string_path}

    # Check if there are only 1 argument
	if [ $# -eq 1 ]; then

		# For all character if the current character is / then
		# he is escape thanks to \/ else the character are not modified 
		for((cpt_string_path=0 ; cpt_string_path < ${#string_path} ; ++cpt_string_path))
		do
			if [ ${string_path:$cpt_string_path:1} = "/" ]; then
				string_path_escape=$string_path_escape"\/";
			else
				string_path_escape=$string_path_escape${string_path:$cpt_string_path:1};
			fi
		done

		echo $string_path_escape;

	else
		echo "ERROR MUST HAVE AN ARGUMENT";
	fi
}

### CHECK ###

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
# -2 = ROOT PB
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

### DOWNLOAD REPO ###

# Downlaod the repo
# USE : download_repo repo_address_without_http|https
# RETURN :
# 0 = OK
# -3 = BAD USE
# -5 = GIT PB
function download_repo
{
	# Bad use
	if [ $# -ne 2 ]; then
		return -3
	fi

	case $GIT_DOWNLOAD_MODE in
		0)
			git clone git://$1 $2
			if [ $? -ne 0 ]; then
				GIT_DOWNLOAD_MODE=1
				git clone http://$1 $2

				if [ $? -ne 0 ]; then
					return -5
				fi
			fi
		;;

		1)
			git clone http://$1 $2
			if [ $? -ne 0 ]; then
				return -5
			fi
		;;

		*)
			return -5
		;;
	esac

	return 0
}

# Replace all git to http in $1
# USE : replace_submodules_git_to_http gitmodules_file
# RETURN :
# 0 = OK
# -3 = BAD USE
# -4 = SED PB
function replace_submodules_git_to_http
{
	# Function protection
	if [ $# -ne 1 ]; then
		return -3
	fi

	# Replace
	sed "s/git/http/g" --in-place $1
	# Error
	if [ $? -ne 0 ]; then
		return -4
	fi

	return 0
}

# Downlaod submodule
# USE : download_submodules gitmodules_file
# RETURN :
# 0 = OK
# -3 = BAD USE
# -5 = GIT PB
function download_submodules
{
	if [ $# -ne 1 ]; then
		return -3
	fi

	case $GIT_DOWNLOAD_MODE in
		0)
			# Submodule init cmd
			git submodule update --init

			# Pb try with http
			if [ $? -ne 0 ]; then
				GIT_DOWNLOAD_MODE=1
				
				# Replace
				replace_submodules_git_to_http
				exit_the_script

				# Submodule init cmd
				git submodule update --init
				# Error
				if [ $? -ne 0 ]; then
					return -5
				fi
			fi
		;;

		1)
			# Replace
			replace_submodules_git_to_http
			# Error
			exit_the_script

			# Submodule init cmd
			git submodule update --init
			# Error
			if [ $? -ne 0 ]; then
				return -5
			fi
		;;

		*)
			return -5
		;;
	esac
	
	return 0
}

### DREAMCAST CHAIN ###

# Download all Dreamcast chain
# TODO : See to modify the download script
# USE : download_dc_chain
# RETURN :
# 0
function download_dc_chain
{
	cd $KOS_DC_CHAIN_FOLDER_NAME
	chmod 744 download.sh
	./download.sh --no-deps

	return 0
}

# Unpack all Dreamcast chain
# TODO : See to not use the unpack script
# USE : unpack_dc_chain
# RETURN :
# 0 = OK
function unpack_dc_chain
{
	cd $KOS_DC_CHAIN_FOLDER_NAME
	chmod 744 unpack.sh
	./unpack.sh --no-deps

	return 0
}

# Make all Dreamcast chain
# USE : make_dc_chain
# RETURN :
# 0 = OK
function make_dc_chain
{
	cd $KOS_DC_CHAIN_FOLDER_NAME

	if [ $REGULAR_FOLDER -eq 0 ]; then
		mkdir -p $DC_CHAIN_INSTALL_PATH
	elif [ $REGULAR_FOLDER -eq 1 ];then
		echo "sudo mkdir -p $DC_CHAIN_INSTALL_PATH"
		sudo mkdir -p $DC_CHAIN_INSTALL_PATH
	fi

	declare -x dc_default_path_escape=$(add_escape_character_for_path $DC_CHAIN_DEFAULT_PATH)
	declare -x dc_install_path_escape=$(add_escape_character_for_path $DC_CHAIN_INSTALL_PATH)

	sed "s/$dc_default_path_escape/$dc_install_path_escape/g" --in-place Makefile
	sed "s/makejobs=-4/makejobs=-j$nb_cpu/g" --în-place Makefile

	make

	return 0
}

### MAIN ###

function main_function
{
	check_os
	exit_the_script
	echo $OS

	check_library_package
	exit_the_script
	echo "All missing librarys installed"

	download_repo $KOS_REPO $KOS_FOLDER_NAME
	exit_the_script
	echo "KOS repo download"

	download_repo $KOS_PORTS_REPO $KOS_PORTS_FOLDER_NAME
	exit_the_script
	echo "KOS Port repo download"

	cd $KOS_PORTS_FOLDER_NAME
	download_submodules $KOS_PORTS_GIT_MODULES_FILE
	exit_the_script
	echo "Submodule download"

	download_dc_chain
	unpack_dc_chain
	make_dc_chain	
}

main_function
exit 0
