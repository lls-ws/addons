#!/bin/sh
# Script para configurar o SSL no cloud Ubuntu Server 20.04 LTS 64 bits
#
# Autor: Leandro Luiz
# email: lls.homeoffice@gmail.com

# Caminho das bibliotecas
PATH=.:$(dirname $0):$PATH
. cloud/lib/tomcat.lib		|| exit 1

create_pfx()
{
	
	if [ -f ${KEYSTORE} ]; then
	
		rm -fv ${KEYSTORE}
	
	fi
	
	echo "Unpackge certificate..."
	mkdir -v ${DIR_SSLFORFREE}
	unzip ${ARQ_ZIP} -d ${DIR_SSLFORFREE}
	
	echo "Creating PFX key..."
	openssl pkcs12 -export \
		-out ${KEYSTORE} \
		-inkey ${PRIVATE_KEY} \
		-in ${CERTIFICATE} \
		-certfile ${CA_BUNDLE} \
		-passout pass:${PASSWORD} \
		-name ${ALIAS}
	
	rm -rf ${DIR_SSLFORFREE}
	
	show_pfx
	
}

show_pfx()
{
	
	chown -v tomcat.tomcat ${KEYSTORE}
	
	echo "Showing private key..."
	keytool -list -v -keystore ${KEYSTORE} -storepass ${PASSWORD} | less
	
}

certbot()
{
	
	echo " -- Cleaning -- "
	sudo rm -fv request.csr
	sudo rm -fv *.pem

	echo " -- Stop Services -- "
	sudo iptables -F -t nat
	sudo service tomcat stop

	echo " -- Delete Keystore -- "
	sudo rm -fv ${KEYSTORE}

	echo " -- Recreate Keystore -- "
	sudo keytool -genkey -noprompt -alias ${ALIAS} -dname "CN=${DNAME}, OU=${USER}, O=${USER}, L=Uberlandia, S=MG, C=BR" -keystore ${KEYSTORE} -storepass "${PASSWORD}" -KeySize 2048 -keypass "${PASSWORD}" -keyalg RSA

	echo " -- Build CSR -- "
	sudo keytool -certreq -alias ${ALIAS} -file request.csr -keystore ${KEYSTORE} -storepass "${PASSWORD}"

	echo " -- Request Certificate -- "
	sudo certbot certonly --csr ./request.csr --standalone

	echo " -- import Certificate -- "
	sudo keytool -import -trustcacerts -alias ${ALIAS} -file 0001_chain.pem -keystore ${KEYSTORE} -storepass "${PASSWORD}"

	echo " -- Restart services -- "
	sudo service tomcat start
	sudo iptables-restore -n < /etc/iptables/rules.v4

	echo " -- Cleaning -- "
	sudo rm -fv request.csr
	sudo rm -fv *.pem
	
	show_pfx
	
}

case "$1" in
	create)
		create_pfx
		;; 
	show)
		show_pfx
		;;
	certbot)
		certbot
		;;
	*)
		echo "Use: $0 {create|show|certbot}"
		exit 1
		;;
esac
