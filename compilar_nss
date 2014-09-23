#!/usr/bin/env bash
mkdir -p ~/public_html/certificados_iceweasel/certificados/

echo "Obteniendo certificados"
cd ~/public_html/certificados_iceweasel/certificados/
wget -c https://github.com/suscerte/descargar_certificados/blob/master/download_certificates.py
python download_certificates.py

# Saliendo del directorio certificados/
cd ../

cd ~/public_html/certificados_iceweasel/

echo "Obteniendo código fuente de nss y nspr"
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