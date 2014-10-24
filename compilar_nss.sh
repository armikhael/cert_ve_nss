#!/usr/bin/env shell
 
EXITO() {
printf "\033[1;32m${1}\033[0m\n"
}
 
mkdir -p ~/public_html/certificados_iceweasel/certificados/
mkdir -p ~/public_html/certificados_iceweasel/paquetes/
cd ~/public_html/certificados_iceweasel/
 
EXITO "Instalando dependencias necesarias"
# sudo aptitude update; aptitude install git git-buildpackage build-essential quilt libnss3 libc6-dev zlib1g-dev libnspr4-dev libsqlite3-dev
 
echo " "
EXITO "Iniciando procedimiento para obtencion del certificado"
git clone https://gist.github.com/Axelio/0a86cddf72dadfd43426 get_certificados
 
echo " "
EXITO "Descargando los siguientes certificados:"
cd certificados/
python ~/public_html/certificados_iceweasel/get_certificados/descargar_certificados.py
 
echo " "
EXITO "Obteniendo código fuente de nss y nspr"
cd ~/public_html/certificados_iceweasel/paquetes/
rm -rf ~/public_html/certificados_iceweasel/get_certificados/
apt-get source nss nspr
 
echo " "
EXITO "Quitando patchs"
VERSION_NSS=`ls -d */ | grep nss | cut -d \- -f 2 | cut -d \/ -f 1`
VERSION_NSPR=`ls -d */ | grep nspr | cut -d \- -f 2 | cut -d \/ -f 1`
VERSION_NSS_CHANGELOG=`head -1 ~/public_html/certificados_iceweasel/paquetes/nss-$VERSION_NSS/debian/changelog | tail -1 | cut -d \( -f 2 | cut -d \) -f 1`
 
cd ~/public_html/certificados_iceweasel/paquetes/nss-$VERSION_NSS/
export QUILT_PATCHES=debian/patches
quilt pop -a
rm -rf .pc
 
EXITO "Versionando Nss"
git init
git add .
git commit -a -m "Versión original del código fuente."

EXITO "Compilando la herramienta addbuiltin" 
cd ~/public_html/certificados_iceweasel/paquetes/nss-$VERSION_NSS/
ln -s ~/public_html/certificados_iceweasel/paquetes/nspr-$VERSION_NSPR/nspr/ .
 
echo $LIST

ARCH=`arch`
echo $ARCH

if [ "x86_64" = "$ARCH" ]
then
EXITO "Arquitectura $ARCH"
cd ~/public_html/certificados_iceweasel/paquetes/nss-$VERSION_NSS/nss/
make nss_build_all BUILD_OPT=1 USE_64=1
 
cd ~/public_html/certificados_iceweasel/paquetes/nss-$VERSION_NSS/nss/cmd/addbuiltin/
make BUILD_OPT=1 USE_64=1

else
EXITO "Arquitectura $ARCH"
cd ~/public_html/certificados_iceweasel/paquetes/nss-$VERSION_NSS/nss/
make nss_build_all BUILD_OPT=1
 
cd ~/public_html/certificados_iceweasel/paquetes/nss-$VERSION_NSS/nss/cmd/addbuiltin/
make BUILD_OPT=1

fi

echo " "
EXITO "Se copiará addbuiltin /usr/bin/"
EXITO "Se debe ejecutar como super usuario"
cd Linux*/
sudo cp -v addbuiltin /usr/bin/

echo " "
EXITO "Convirtiendo los certificados con addbuiltin"
cd ~/public_html/certificados_iceweasel/certificados/
 
CERTIFICADOS=`ls *.crt`
 
for certificado in $CERTIFICADOS
do
nombre=`echo $certificado | cut -d \. -f 1`
openssl x509 -inform PEM -outform DER -in $certificado -out $nombre.der
comando=`openssl x509 -inform PEM -text -in $certificado | grep "Subject"`
O=`echo $comando | cut -d \O -f 2 | cut -d \= -f 2 | cut -d \, -f 1`
comando=`cat $nombre.der | addbuiltin -n "$O" -t "C,C,C" > $nombre.nss`
done
 
echo " "
echo "Parcheando y reempaquetando NSS"
cd ~/public_html/certificados_iceweasel/paquetes/nss-$VERSION_NSS/
git reset --hard
git clean -fd
 
version=`dpkg-parsechangelog | grep "Version:" | awk '{print $2}'`
version=`echo $version | cut -d \: -f 2`
 
git tag debian/$version
 
cd ~/public_html/certificados_iceweasel/certificados/
 
CERTIFICADOS=`ls *.nss`
 
for certificado in $CERTIFICADOS
do
cat $certificado >> ~/public_html/certificados_iceweasel/paquetes/nss-$VERSION_NSS/nss/lib/ckfw/builtins/certdata.txt
done
 
cd ~/public_html/certificados_iceweasel/paquetes/nss-$VERSION_NSS/nss/lib/ckfw/builtins/
make generate
 
 
cd ~/public_html/certificados_iceweasel/paquetes/nss-$VERSION_NSS/
mkdir -p debian/patches
 
echo " "
EXITO "Generando parches"
git diff > ../99_ACR-certificates.patch
git reset --hard
git clean -fd
mv ../99_ACR-certificates.patch debian/patches/
echo "99_ACR-certificates.patch" >> debian/patches/series
 
echo " "
EXITO "Comprobando parches"
export QUILT_PATCHES=debian/patches
quilt push -af
quilt refresh
rm -rf nss/lib/ckfw/builtins/certdata.c.rej
quilt pop -a
rm -rf .pc
 
echo " "
EXITO "Subiendo de versión el paquete NSS"
git dch -N $VERSION_NSS_CHANGELOG+1canaima --auto --release --git-author --id-length=7 --commit
 
git add .
git commit -am "Agregando parche para los certificados aprobados por SUSCERTE"
git-buildpackage -us -uc -j5
