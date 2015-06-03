Script to compile all KOS thinks
================================

KOS, or KallistiOS, is an open source Dreamcast toolchain, but the installation
and the compilation is not automatic.

So I will try to make a install script for Linux system.

Supporting system :

ArchLinux in no root path

Supporting system soon :

ArchLinux in all path
Debian

Based on http://www.neogaf.com/forum/showthread.php?t=916501 tutorial

How To Use
==========

In your terminal, just tape these commands :
chmod u+x install.bash
./install.bash

Caution :
---------
 At the begining, the script check all missing packages, so you must to be here
to put your root password


If you want to modify some thinks you can. You have :
REGULAR_FOLDER = Its not use for the moment, so if you install in root folder
the script cant run
DC_CHAIN_INSTALL_FOLDER_NAME = Name folder contains all dc-chain stuff
( kos/utils/dc-chain compilation )
DC_CHAIN_INSTALL_PATH = Path with DC_CHAIN_INSTALL_FOLDER_NAME folder
NAME_NEW_BASHRC = Not use yet, but can be use full to generated a .bashrc with
all path ( avoid the execution of the environ.sh script in each terminal and at
each login )
KOS_FOLDER_NAME = Folder containts all sources of KOS
KOS_PORTS_FOLDER_NAME = Folder containts all sources of KOS Ports repo
( like sdl, zlib ect sources and binary compiled with kos )
ENVIRON_SCRIPT_NAME = Name of the environ.sh script in KOS_FOLDER_NAME
