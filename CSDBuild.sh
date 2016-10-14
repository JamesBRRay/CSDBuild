#!/bin/bash -e

# Where to install to, by default $HOME/CSDWrapper
read -p "Where would you like the CSD Wrapper and associated code to end up
[default: $HOME/CSDWrapper]: " INSTLOC
if [ -z ${INSTLOC} ]; then
	INSTLOC=${HOME}/CSDWrapper
fi

if [ -e ${INSTLOC} ]; then
	echo "${INSTLOC} alread exists... bailing out"
	exit 1
else
	mkdir ${INSTLOC}
	mkdir ${INSTLOC}/lib
fi

read -p "Name of the VPN Connection to create in NetworkManager
[default: UCLVPN]: " VPNNAME
if [ -z ${VPNNAME} ]; then
	VPNNAME=UCLVPN
fi

read -p "URL to predeploy tarball
[default: https://www.ucl.ac.uk/isd/how-to/remote-working/resources/linux/anyconnect-predeploy-linux-64-4.3.02039-k9.tar] " PREDEPLOY

if [ -z ${PREDEPLOY} ]; then
	PREDEPLOY="https://www.ucl.ac.uk/isd/how-to/remote-working/resources/linux/anyconnect-predeploy-linux-64-4.3.02039-k9.tar"
fi

# Check the connection name is free
CONFREE=0
(NULL=$(nmcli connection show ${VPNNAME} 2>&1>/dev/null)) || CONFREE=1 2>&1 > /dev/null

if [ ${CONFREE} -eq 0 ]; then
	echo "Connection name is not free in NetworkManager... bailing out"
	exit 2
fi

# Check the pre-reqs
DISTRO=$(lsb_release -i -s)
REL=$(lsb_release -r -s)
if [ ${DISTRO} == "Ubuntu" ]; then
	# It's an Ubuntu of sorts
	if [ ${REL} == "16.04" -o ${REL} == "16.10" ]; then
		PREREQS="openconnect network-manager-openconnect network-manager-openconnect-gnome curl"
	fi
fi

# No prereqs and no distforce, die
if [ -z "${PREREQS}" ] && [ -z ${DISTFORCE} ]; then
	echo "Unsupported version and DISTFORCE=1 not set... bailing out";
	exit 1
fi

# Check each pre-req
MISSINGREQ=()
for prereq in ${PREREQS}; do
	if [ ${DISTRO} == "Ubuntu" ]; then
		(NULL=$(dpkg -s ${prereq} 2>&1>/dev/null)) || MISSINGREQ+=(${prereq})
	fi
done

echo ${MISSINGREQ}

if [ ${DISTRO} == "Ubuntu" ]; then
	sudo apt-get install ${MISSINGREQ[*]}
fi

# Download the tarball
TARBALL=$(mktemp)
curl -o ${TARBALL} ${PREDEPLOY}

# Uncompress the AnyConnect Linux tarball
tar -zxf ${TARBALL}

# Locate the cstub client
CSTUB=$(find ./anyconnect-* | grep cstub | head -n 1)
cp $CSTUB ${INSTLOC}/

# We need the following three libraries also
LIBS=$(find ./anyconnect-*/posture -name libacciscocrypto.so -o -name libacciscossl.so -o -name libaccurl.so.4.3.0)
cp $LIBS ${INSTLOC}/lib

# We do this as parts as a need variables expansion in some parts and not others
tee > ${INSTLOC}/CSDWrapper.sh <<EOF
#!/bin/bash 

INSTLOC=${INSTLOC}

EOF

tee >> ${INSTLOC}/CSDWrapper.sh <<"EOF"
shift
while [ "$1" ]; do
  case $1 in
    -ticket)    shift; ticket=$1;;
    -stub)      shift; stub=$1;;
    -group)     shift; group=$1;;
    -certhash)  shift; certhash=$1;;
    -url)       shift; url=$1;;
  esac
  shift;
done
args=" -log debug -ticket $ticket -stub $stub -group $group -host $url -certhash $certhash"
if [ ! -L ${HOME}/.cisco/hostscan/lib/libaccurl.so.4.3.0 ]; then
	rm ${HOME}/.cisco/hostscan/lib/libaccurl.so.4.3.0 || echo "Failed to remove libaccurl.so.4.3.0"
	if [ ! -d ${HOME}/.cisco/hostscan/lib/ ]; then
		mkdir -p ${HOME}/.cisco/hostscan/lib/
	fi
	ln -s ${INSTLOC}/lib/libaccurl.so.4.3.0 ${HOME}/.cisco/hostscan/lib/libaccurl.so.4.3.0
fi

sudo -u ${USER} LD_LIBRARY_PATH=${INSTLOC}/lib "${INSTLOC}/cstub" $args
EOF
chmod +x ${INSTLOC}/CSDWrapper.sh

# Lets add a NetworkManager instance for it
nmcli connection add ifname '*' con-name ${VPNNAME} autoconnect no save yes type vpn vpn-type openconnect -- vpn.data "authtype = password, gateway = vpn.ucl.ac.uk, csd_wrapper = ${INSTLOC}/CSDWrapper.sh, cookie-flags = 2, certsigs-flags = 0, stoken_source = disabled, lasthost-flags = 0, autoconnect-flags = 0, gateway-flags = 2, gwcert-flags = 2, pem_passphrase_fsid = no, xmlconfig-flags = 0, enable_csd_trojan = yes"

nmcli connection up ${VPNNAME}
