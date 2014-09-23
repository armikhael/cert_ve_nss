#!/usr/bin/env bash

mkdir -p ~/public_html/certificados_iceweasel/certificados/
mkdir -p ~/public_html/certificados_iceweasel/paquetes/
cd ~/public_html/certificados_iceweasel/

echo "Iniciando procedimiento para obtencion del certificado"
echo "Es necesario tener git instalado"
su -c "aptitude install git"
git clone https://gist.github.com/Axelio/0a86cddf72dadfd43426 get_certificados

echo " "
echo "Descargando los siguientes certificados:"
cd certificados/
python ~/public_html/certificados_iceweasel/get_certificados/descargar_certificados.py

echo " "
echo "Obteniendo código fuente de nss y nspr"
cd ~/public_html/certificados_iceweasel/paquetes/
apt-get source nss nspr

cd nss-3.14.5/
export QUILT_PATCHES=debian/patches
quilt pop -a

echo "Compilando la herramienta addbuiltin"
git init
git add .
git commit -a -m "Versión original del código fuente."

cd mozilla
ln -s ../../nspr-4.9.2/mozilla/nsprpub/ .

cd security/nss/
make nss_build_all BUILD_OPT=1
