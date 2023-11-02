#!/bin/bash

###########################################################################
# DEFINITIONS ...
jnversion=170

b=$(tput bold)
n=$(tput sgr0)
INSTALL_PACKS=" zip unzip bzip2 wget postfix rkhunter nmap telnet at pv mc screen sudo openssh-server net-tools software-properties-common fping man lsb-release dirmngr dnsutils bash-completion libsmartcols1  bsdextrautils numlockx curl"
DEL_PACKS="avahi-daemon"
###########################################################################


usage(){

  echo -e "\n  Usage: "$b"$(basename $0)"$n" ["$b"params"$n"]  Version=$jnversion (c)2017-2023 Jan Novak, repcom@gmail.com\n"
    usageoutput=$usageoutput"\n  "$b"params are one of that:$n| "
    usageoutput=$usageoutput"\n  "$b"basics"$n"|install debian basics"					# basics
    usageoutput=$usageoutput"\n  "$b"packs"$n"|show packs to install only (nothing will be done)"	# packs
    usageoutput=$usageoutput"\n  "$b"installproxmox"$n"|install Proxmox System"				# install_proxmox
    usageoutput=$usageoutput"\n  "$b"sanoid"$n"|install sanoid zfs snapshot tool"			# install_sanoid
    usageoutput=$usageoutput"\n  "
    usageoutput=$usageoutput"\n  "$b"pml/pmn/pma/pmr"$n"|set proxmox [l]ocal / [n]ormal / restart [a]ll /[r]emove cluster (be careful with pmr)"	# setproxmoxpmxcfs
    usageoutput=$usageoutput"\n  "$b"pmrestart"$n"|restart proxmox cluster daemons"			# proxmoxrestartcluster
    usageoutput=$usageoutput"\n  "
    usageoutput=$usageoutput"\n  "$b"ip"$n"|What is my public ip"					# ip

    if [ "$(type -p column)" ]; then
        echo -e "$usageoutput"|column -t -s "|"
    else
        echo -e "${b}  ATTENTION: you do not have 'column' installed. The 'usage' output below looks ugly. Run 'apt install column' to fix that if you like.${n}"
        echo -e "$usageoutput"
    fi
    echo ""
}








# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
packages(){
    [ ! -e $RELEASE_FILE ] &&  echo -e "\n\tERROR: No releasefile found. Unknown system. Abort!\n" && exit 1
    [ "$(cat $RELEASE_FILE|grep -i "ubuntu")" ] && echo "Ubuntu System .. trying to install packages ..."
    [ "$(cat $RELEASE_FILE|grep -i "suse")" ] && echo "SuSE not supported at the moment..." &&  exit 1

    #apt-add-repository contrib >/dev/null 2>&1
    #apt-add-repository non-free >/dev/null 2>&1

    if [ "$(cat $RELEASE_FILE|grep -i "debian")" ]; then

        if [ "$(cat $RELEASE_FILE|grep "buster")" ]; then
            osr="buster"
            additionalPackageSource="deb http://ftp.debian.org/debian $osr-backports main"
            if [ -z "$(cat /etc/apt/sources.list|grep "$additionalPackageSource"|grep -v "#")" ]; then
                echo -n "Adding \"$additionalPackageSource\" to /etc/apt/sources.list ..."
                echo $additionalPackageSource >> /etc/apt/sources.list
                echo " Done!"
            fi
        fi
        if [ "$(cat $RELEASE_FILE|grep "bullseye")" ]; then
            osr="bullseye"
            if [ ! -e /etc/apt/sources.list.fi2 ]; then
                cp  /etc/apt/sources.list  /etc/apt/sources.list.fi2
                echo "
deb http://deb.debian.org/debian $osr main contrib non-free
deb-src http://deb.debian.org/debian $osr main contrib non-free

deb http://security.debian.org/debian-security $osr-security main contrib non-free
deb-src http://security.debian.org/debian-security $osr-security main contrib non-free

deb http://deb.debian.org/debian $osr-updates main contrib non-free
deb-src http://deb.debian.org/debian $osr-updates main contrib non-free

deb http://deb.debian.org/debian $osr-backports main contrib non-free
deb-src http://deb.debian.org/debian $osr-backports main contrib non-free
"> /etc/apt/sources.list
            fi




        fi
        if [ "$(cat $RELEASE_FILE|grep "bookworm")" ]; then
            osr="bookworm"
            [ ! -f /etc/apt/apt.conf.d/no-bookworm-firmware.conf ] && \
            echo -e 'APT::Get::Update::SourceListWarnings::NonFreeFirmware "false";' > /etc/apt/apt.conf.d/no-bookworm-firmware.conf
        fi
         cp  /etc/apt/sources.list  /etc/apt/sources.list.fi2
                echo "
deb http://deb.debian.org/debian bookworm main contrib non-free
deb-src http://deb.debian.org/debian bookworm main contrib non-free

deb http://security.debian.org/debian-security bookworm-security main contrib non-free
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free

deb http://deb.debian.org/debian bookworm-updates main contrib non-free
deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free

deb http://deb.debian.org/debian bookworm-backports main contrib non-free
deb-src http://deb.debian.org/debian bookworm-backports main contrib non-free
"> /etc/apt/sources.list

    fi

    apt update
    echo -e "\n"$b"Installing"$n"  ... \n\n"
    [ "$(dmesg |grep -i hypervisor)" ] && qemuGuestAddition="qemu-guest-agent haveged" ||  qemuGuestAddition=""
    apt install $non_interactive $INSTALL_PACKS $qemuGuestAddition

    echo -e "\n"$b"removing"$n"  ... \n\n"
    apt remove $non_interactive $DEL_PACKS
    apt autoremove

    echo -e "\n\n"$b"linking & creating dirs"$n""
    if [ ! -L /root/bin ] && [ ! -d /root/bin ]; then
        [ -z "$1" ] && echo -e -n "\tlinking bin into /root ... "
        ln -s /usr/local/bin/ /root/bin >/dev/null 2>&1
        [ -z "$1" ] && echo " OK"
    fi
    echo "done"

    echo "$b""Creating/checking bash aliases for l, la, ll ...""$n"
    [ -z "$(cat /etc/bash.bashrc|grep 'alias l=')" ] && echo 'alias l="ls -la"'>>/etc/bash.bashrc
    [ -z "$(cat /etc/bash.bashrc|grep 'alias la')" ] && echo 'alias la="ls -la"'>>/etc/bash.bashrc
    [ -z "$(cat /etc/bash.bashrc|grep 'alias ll')" ] && echo 'alias ll="ls -l"'>>/etc/bash.bashrc
    if [ -z "$(type -p /usr/sbin/poweroff)" ]; then
            echo "alias reboot='systemctl reboot'" >>/etc/bash.bashrc
            echo "alias poweroff='systemctl poweroff'" >>/etc/bash.bashrc
    fi
    echo "done"


    pf="/root/.profile"
    echo -n "checking $pf ... "
    if [ -f $pf ]; then
        if [ "$(cat $pf|grep 'mesg n || true')" ]; then
            if [ "$(cat $pf|grep 'test -t 0 && mesg n')" ]; then
                echo "already done."
            else
                echo -n "changeing ... "
                sed -i.bak 's/mesg n || true//g' $pf
                echo 'test -t 0 && mesg n'>>$pf
                echo "Done."
            fi
        else
            echo "String 'mesg n || true' not included. Nothing to do."
        fi
    else
        echo "File \"$pf\" not found. Abort!"
    fi

    if [ "$(type -p hostnamectl)" ] && [ "$(LANG=C;hostnamectl status|grep -i 'debian')" ]; then
        echo -n "checking debian \"sbin\" path ... "
        if [ -z "$(cat /etc/profile|grep sbin)" ]; then
            echo -n "setting ... "
            sed -i.bak 's/export PATH/PATH="\/usr\/local\/sbin:\/usr\/local\/bin:\/usr\/sbin:\/usr\/bin:\/sbin:\/bin:\/arc"\nexport PATH/g' /etc/profile
            echo "Done."
        else
            echo "already set. Nothing to do."
        fi
    fi
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_proxmox(){
    echo "Install proxmox..."
    if [ ! -f /etc/apt/sources.list.d/pve-install-repo.list ]; then
        echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" | sudo tee /etc/apt/sources.list.d/pve-install-repo.list
    fi
    wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
    apt update && apt -y dist-upgrade
    apt install -y postfix
    apt install -y proxmox-ve postfix open-iscsi molly-guard
    apt remove -y os-prober
    apt remove -y linux-image-amd64
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_sanoid(){
    echo "Installing sanoid to /opt/sanoid-master from github ..."
    apt install -y debhelper libcapture-tiny-perl libconfig-inifiles-perl pv lzop mbuffer
    mkdir -p /opt/sanoid-master
    cd /opt/sanoid-master
    wget -q https://github.com/jimsalterjrs/sanoid/archive/master.zip
    unzip -o -j ./master.zip #sanoid-master/sanoid sanoid-master/findoid  sanoid-master/sleepymutex  sanoid-master/syncoid
    rm -f master.zip
    mkdir -p /etc/sanoid
    if [ ! -e /etc/sanoid/sanoid.defaults.conf ]; then
        echo "Linking sanoid.defaults file ..."
        ln -s /opt/sanoid-master/sanoid.defaults.conf /etc/sanoid
    fi
    if [ ! -e /etc/sanoid/sanoid.conf ]; then
        echo "getting default sanoid config file from Server ..."
        getFileFromFabricServer "sanoid.conf"
        [ -e /tmp/sanoid.conf ] && mv /tmp/sanoid.conf /etc/sanoid
    fi
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
setproxmoxpmxcfs(){
    if [ "$(type -p pvecm)" ]; then
        cd /tmp
        if [ "$1" = "pml" ]; then
            systemctl stop pve-cluster
            systemctl stop corosync
            pmxcfs -l
            echo -e "\n\tProxmox /etc/pve is now in local mode\n"
        fi
        if [ "$1" = "pmn" ]; then
            killall pmxcfs
            systemctl start corosync
            systemctl start pve-cluster
            echo -e "\n\tProxmox /etc/pve is now in normal mode\n"
        fi
        if [ "$1" = "pmr" ]; then
            echo -e "stopping daemons..."
            systemctl stop pve-cluster corosync
            pmxcfs -l
            echo -e "removing cluster infos ..."
            rm /etc/corosync/*
            rm /etc/pve/corosync.conf
            killall pmxcfs
            pvecm expected 1
            echo -e "starting daemons..."
            systemctl start pve-cluster
            rm /var/lib/corosync/*
            echo -e"\n\nList of /etc/pve/nodes:"
            ls -la /etc/pve/nodes
            echo -e "\n\n"
        fi
        if [ "$1" = "pma" ]; then
            liste="
pve-firewall.service
pve-guests.service
pve-ha-crm.service
pve-ha-lrm.service
pve-lxc-syscalld.service
pvebanner.service
pvedaemon.service
pvefw-logger.service
pvenetcommit.service
pveproxy.service
pvestatd.service
pve-storage.target
pve-daily-update.timer
pvesr.timer
"
            for l in $liste; do
                systemctl restart $l
            done
        fi
    else
        echo -e "\nThis system does not look like a proxmox server (no pvecm available). Exit!\n"
    fi
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
proxmoxrestartcluster(){
    if [ "$(type -p pvecm)" ]; then
        cd /tmp
        echo "restarting pve-cluster..."
        service pve-cluster restart
        echo "stopping corosync..."
        service corosync stop
        echo "restarting pveproxy..."
        service pveproxy restart
        echo "starting corosync..."
        service corosync start
        echo "restarting pvedaemon..."
        service pvedaemon restart
        echo "restarting pvestatd..."
        service pvestatd restart
    else
        echo -e "\nThis system does not look like a proxmox server (no pvecm available). Exit!\n"
    fi
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

case $1 in
    basics)
        packages $2
        sleep 2
        ssh-keygen
    ;;
    installproxmox)
        install_proxmox $2
    ;;
    sanoid)
        install_sanoid
    ;;
    ip)
        [ -z "$(type -p dig)" ] && apt install dnsutils
        dig @resolver3.opendns.com myip.opendns.com +short
    ;;
    pml|pmn|pmr|pma)
        setproxmoxpmxcfs "$1"
    ;;
    pmrestart)
        proxmoxrestartcluster
    ;;
    packs)
        echo -e "Debian packages to install would be:\n${INSTALL_PACKS}\n\n"
    ;;
    *)
        usage
    ;;
esac
