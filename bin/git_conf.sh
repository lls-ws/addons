#!/bin/bash
# Script para gerenciar os repositorios no Github
#
# email: lls.homeoffice@gmail.com

git_update()
{
	
	# Updating a local repository with changes from a GitHub repository
	git pull origin master
	
}

if [ "$EUID" -ne 0 ]; then
	echo "Rodar script como root"
	exit 1
  
fi

case "$1" in
	update)    	
		git_update
		;; 
	*)
		echo "Use: $(basename $0) {update}"
		exit 1
		;;
esac
