#!/bin/bash
# Script para gerenciar o arquivo de backup do banco de dados bd_lls no mariadb
#
# email: lls.homeoffice@gmail.com

cria_log()
{
	
	if [ ! -d ${DIR_LOG} ]; then
	
		mkdir -v ${DIR_LOG}
	
	fi
	
	# Pegando a data e hora
	DATA_HORA_EMAIL=`date +"%d/%m/%y - %H:%M:%S"`
	
	# Pegando a data
	DATA_EMAIL=$(echo ${DATA_HORA_EMAIL} | cut -f 1 -d '-')
	
	# Pegando a hora
	HORA_EMAIL=$(echo ${DATA_HORA_EMAIL} | cut -f 2 -d '-')

	# Pegando a data no formato de arquivo
	ARQ_DATA_EMAIL=`date +"%d.%m.%y"`

}

criar_backup()
{
	
	cria_log
	
	if [ ! -d ${DIR_SQL} ]; then
	
		mkdir -v ${DIR_SQL}
	
	fi
	
	echo "Criando o arquivo de backup: ${ARQ_DUMP} ${DATA_EMAIL}-${HORA_EMAIL}" >> ${ARQ_LOG}
	tail -1 ${ARQ_LOG}
	
	#mysqldump -u "${USER}" --password="${PASSWORD}" --no-create-info "${BD}" > "${ARQ_DUMP}"
	mysqldump -u "${USER}" --password="${PASSWORD}" "${BD}" > "${ARQ_DUMP}"
	
	echo "Compactando o arquivo de backup: ${ARQ_ZIP} ${DATA_EMAIL}-${HORA_EMAIL}" >> ${ARQ_LOG}
	tail -1 ${ARQ_LOG}
	
	zip -j ${ARQ_ZIP} ${ARQ_DUMP}
	
}

restaurar_backup()
{
	
	clear_tables
	
	echo "Restaurando o arquivo de backup: ${ARQ_DUMP}"
	
	${CMD_BASE} < "${ARQ_DUMP}"
	
	show_tables
	
}

enviar_backup()
{
	
	criar_backup
	
	echo "Enviando backup por email..."
	
	echo -e "to: ${DESTINATARIO}\nsubject: Backup LLS-WS\n" |
	
	(cat - && uuencode ${ARQ_ZIP} ${ARQ_ZIP}) |
	
	/usr/sbin/ssmtp ${DESTINATARIO}
	
	RESPONSE="$?"
	
	if [ "${RESPONSE}" == "0" ]; then
	
		echo "Backup enviado para: ${DESTINATARIO} ${DATA_EMAIL}-${HORA_EMAIL}" >> ${ARQ_LOG}
	
	else
	
		echo "Erro ao enviar email!" >> ${ARQ_LOG}
	
	fi
	
	tail -1 ${ARQ_LOG}
	
}

loop_tables()
{
	
	OPT="$1"
	
	echo "Loop all tables..."
	
	${CMD_BASE} -Nse 'show tables' | 
	
	while read table;
	do 
		
		echo "${OPT} $table..."
		
		${CMD_BASE} -e "SET FOREIGN_KEY_CHECKS=0;${OPT} ${table};SET FOREIGN_KEY_CHECKS=1;";
	
	done
	
}

remove_tables()
{
	
	loop_tables "drop table"
		
}

clear_tables()
{
	
	loop_tables "truncate table"
	
}

show_tables()
{
	
	loop_tables "select count(*) as Total from"
	
}

if [ "$EUID" -ne 0 ]; then
	echo "Rodar script como root"
	exit 1
  
fi

OPCAO="$1"

DIR_LOG="log"
DIR_SQL="sql"

ARQ_LOG="${DIR_LOG}/backup_bd_lls.log"
#ARQ_DUMP="${DIR_SQL}/backup_bd_lls.dump"
ARQ_DUMP="${DIR_SQL}/backup_bd_lls.sql"
ARQ_ZIP="${DIR_SQL}/backup_bd_lls.zip"

XML_FILE="/usr/share/tomcat/conf/tomcat-users.xml"

USER="`cat ${XML_FILE} | grep -i username | awk '{ print $2 }' | cut -f 2 -d '=' | cut -f 2 -d '"'`"
PASSWORD="`cat ${XML_FILE} | grep -i password | awk '{ print $3 }' | cut -f 2 -d '=' | cut -f 2 -d '"'`"
BD="bd_lls"
CMD="mysql -u ${USER} --password=${PASSWORD} "
BASE_OPT=$(echo "-D ${BD}")
CMD_BASE=$(echo "${CMD} ${BASE_OPT}")

DESTINATARIO="lls.homeoffice@gmail.com"

if [ -f "destinatario.txt" ]; then

	DESTINATARIO="`cat destinatario.txt`"

fi

case "$OPCAO" in
	criar)    	
		criar_backup
		;; 
	restaurar)
		restaurar_backup
		;;
	send)
		enviar_backup
		;;
	show)
		show_tables
		;;
	clear)
		clear_tables
		;;
	remove)
		remove_tables
		;;
	*)
		echo "Use: $(basename $0) {criar|restaurar|send|show|clear|remove}"
		exit 1
		;;
esac
