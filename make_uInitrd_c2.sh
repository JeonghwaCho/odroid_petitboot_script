#!/bin/bash

# make-uInitrd.sh for ODROID-C2
# Author
# : back2future at ODROID Forum
# reference site
# : https://forum.odroid.com/viewtopic.php?p=237822#p237822

PLTFRM=aarch64-linux-gnu
#PLTFRM=x86_64-linux-gnu
echo $PLTFRM

set -e

# prep
C=$(id | grep -c "(root)" || true)
if [ "$C" != 1 ] ; then
      echo "please re-run as root" >&2
          exit 1
  fi


  C=$(apt-get --just-print upgrade | grep -cP "^Inst " || true)
  if [ "$C" -gt 0 ] ; then
    #    apt-get update -y
    #    apt-get upgrade -y
    #    apt-get dist-upgrade -y
        echo "Please re-run after reboot."
            echo "Reboot now? [y|n]"
          read -r YN
              if [ "$YN" == "y" ] ; then
               echo "reboot a docker container?"
              else
               echo "exit 1"
     fi
            fi
echo
echo " -/- remove previously built initramfs.igz uInitrd.igz"
echo
rm -rf ramdisk_petitboot_aio/initramfs.igz 
rm -rf ramdisk_petitboot_aio/uInitrd.igz 

echo " -/- apt-get install ***prerequisites***"
echo

#            apt-get install -y \
#   git autoconf automake autopoint libtool pkg-config \
#       libudev-dev libdevmapper-dev flex bison gettext \
#     intltool libgcrypt20-dev \
#         gperf libcap-dev libblkid-dev libmount-dev \
#       xsltproc docbook-xsl docbook-xml python-lxml \
#           libncurses5-dev libncursesw5-dev \
#         libdw-dev libgpgme-dev
            apt-get install -y \
   lm-sensors u-boot-tools
            apt-get install -y zlib1g-dev cpio     
            #cd /home/odroid
            mkdir -p ramdisk_petitboot_aio
            cd ramdisk_petitboot_aio

echo 
echo " -/- build tools systemd kexec-tools libtwin petitboot busybox"
echo 
###### compile start
# compiled sources ~740MByte
# systemd ~80min with -j2, 640MB(git_src ~35MB) 
# kexec-tools ~6MB
# libtwin 9MB
# petitboot 18MB
# initramfs 10MB
# busybox ~4min with -j2, 52MB
echo "     compiled sources ~740MByte"
echo "     systemd ~80min with -j2 (~175°F), 640MB(git_src ~35MB)"
echo "     kexec-tools ~6MB"
echo "     libtwin 9MB"
echo "     petitboot 18MB"
echo "     initramfs 10MB"
echo "     busybox ~4min with -j2 (~175°F), 52MB"


if [ ! -d systemd ] ; then
            
 echo "no systemd folder"
    
 
     git clone --depth 1 git://anongit.freedesktop.org/systemd/systemd
       (
     cd systemd
             ./autogen.sh
               mkdir build
  (
        cd build
        ../configure --prefix=/usr --enable-blkid --disable-seccomp --disable-libcurl --disable-pam --disable-kmod
 ###             make -j "$(nproc_hot)"
 #             make -j 2
          )
        )
      fi



      if [ ! -d kexec-tools ] ; then
            git clone --depth 1 git://git.kernel.org/pub/scm/utils/kernel/kexec/kexec-tools.git
          (
   cd kexec-tools
     ./bootstrap
       ./configure --prefix=/usr
         make -j 2
       )
              fi

              if [ ! -d libtwin ] ; then
      git clone --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/geoff/libtwin.git
           (
              cd libtwin
                 ./autogen.sh
                  make -j 2
    make install
                )
        fi


        if [ ! -d petitboot ] ; then
            git clone --depth 1 -b petitboot-1.6.x https://github.com/open-power/petitboot.git
                (
                cd petitboot
                ./bootstrap
                ./configure --with-twin-x11=no --with-twin-fbdev=no --with-signed-boot=no --disable-nls
                make -j 2
            )
            fi

            if [ ! -d busybox ] ; then
                git clone  --depth 1 git://git.busybox.net/busybox
            (
     cd busybox
     make defconfig
     LDFLAGS=--static make -j 2
                )
        fi


echo " -/- create initramfs, insert content"
echo

        if [ ! -d initramfs ] ; then
        mkdir -p initramfs/{bin,sbin,etc,lib/$PLTFRIM,proc,sys,newroot,usr,usr/bin,usr/sbin,usr/lib/$PLTFRM,usr/lib/udev/rules.d,usr/local/sbin/,usr/share/udhcpc,var,var/log/petitboot,run,run/udev,tmp}

#            mkdir -p initramfs/{\
#            bin,\
#            sbin,\
#            etc,\
#            lib/$PLTFRM,\
#            proc,\
#            sys,\
#            newroot,\
#            usr/bin,\
#            usr/sbin,\
#            usr/lib/$PLTFRM,\
#            usr/lib/udev/rules.d,\
#            usr/local/sbin,\
#            usr/share/udhcpc,\
#            var/log/petitboot,run,\
#            run/udev,\
#            tmp}
 
 echo " -/- touch initramfs/etc/mdev.conf"
 
                touch initramfs/etc/mdev.conf
            cp -Rp /lib/terminfo initramfs/lib/
                cp -Rp busybox/busybox initramfs/bin/
            ln -s busybox initramfs/bin/sh
            
 
 echo " -/- mkdir -p initramfs/lib/$PLTFRM"
 mkdir -p initramfs/lib/$PLTFRM
 
 
 
cp -L /lib/$PLTFRM/libc.so.* initramfs/lib/$PLTFRM/
cp -L /lib/$PLTFRM/libm.so.* initramfs/lib/$PLTFRM/
cp -L /lib/$PLTFRM/libdl.so.* initramfs/lib/$PLTFRM/
cp -L /lib/$PLTFRM/librt.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libacl.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libcap.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libattr.so.* initramfs/lib/$PLTFRM/
cp -L /lib/$PLTFRM/libpthread.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libncurses.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libncursesw.so.* initramfs/lib/$PLTFRM/         # <<<---------- added
cp -R /lib/$PLTFRM/libtinfo.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libpcre.so.* initramfs/lib/$PLTFRM/
cp -L /lib/$PLTFRM/libresolv.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libselinux.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libreadline.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libgcc_s.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libblkid.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libkmod.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libuuid.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libusb-1.0.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libdevmapper.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libz.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/liblzma.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libbz2.so.* initramfs/lib/$PLTFRM/
cp -R /lib/$PLTFRM/libgpg-error.so.* initramfs/lib/$PLTFRM/
cp -L /lib/$PLTFRM/libnss_files.so.* initramfs/lib/$PLTFRM/
 
mkdir -p initramfs/lib/
cp -L /lib/ld-linux-aarch64.so.* initramfs/lib/
 
mkdir -p initramfs/usr/lib/$PLTFRM/
cp -R /usr/lib/$PLTFRM/libform.so.* initramfs/usr/lib/$PLTFRM/
cp -R /usr/lib/$PLTFRM/libformw.so.* initramfs/usr/lib/$PLTFRM/           #   <<<----- added
cp -R /usr/lib/$PLTFRM/libmenu.so.* initramfs/usr/lib/$PLTFRM/
cp -R /usr/lib/$PLTFRM/libmenuw.so.* initramfs/usr/lib/$PLTFRM/          #   <<<----- added
cp -L /usr/lib/$PLTFRM/libelf.so.* initramfs/usr/lib/$PLTFRM/
cp -L /usr/lib/$PLTFRM/libdw.so.* initramfs/usr/lib/$PLTFRM/
cp -R /usr/lib/$PLTFRM/libgpgme.so.* initramfs/usr/lib/$PLTFRM/
cp -R /usr/lib/$PLTFRM/libassuan.so.* initramfs/usr/lib/$PLTFRM/
 
 
 #               cp -L /lib/$PLTFRM/{\
 #       libc.so.*,\
 #       libm.so.*,\
 #       libdl.so.*,\
 #       librt.so.*,\
 #       libacl.so.*,\
 #       libcap.so.*,\
 #       libattr.so.*,\
 #       libpthread.so.*,\
 #       libncurses.so.*,\
 #       libncursesw.so.*,\
 #       libtinfo.so.*,\
 #       libpcre.so.*,\
 #      libresolv.so.*,\
 #      libselinux.so.*,\
 #      libreadline.so.*,\
 #      libgcc_s.so.*,\
 #      libblkid.so.*,\
 #      libkmod.so.*,\
 #      libuuid.so.*,\
 #      libusb-1.0.so.*,\
 #      libdevmapper.so.*,\
 #      libz.so.*,\
 #      liblzma.so.*,\
 #      libbz2.so.*,\
 #       libgpg-error.so.*,\
 #       libnss_files.so.*} initramfs/lib/$PLTFRM/ 
 #           cp -L /lib/ld-linux-aarch64.so.* initramfs/lib/
 #               cp -L /usr/lib/$PLTFRM/{\
 #       libform.so.*,\
 #       libformw.so.*,\
 #       libmenu.so.*,\
 #       libmenuw.so.*,\
 #       libelf.so.*,\
 #       libdw.so.*,\
 #       libgpgme.so.*,\
 #       libassuan.so.*} initramfs/usr/lib/$PLTFRM/
        
        
        
            cp -Rp /usr/bin/gpg initramfs/usr/bin/
                cp systemd/build/.libs/libudev.so.* initramfs/lib/$PLTFRM/
            cp -Rp systemd/build/{systemd-udevd,udevadm} initramfs/sbin/
                cp -Rp systemd/build/*_id initramfs/usr/lib/udev/
            cp -Rp kexec-tools/build/sbin/kexec initramfs/sbin/
                cp -Rp systemd/{rules/*,build/rules/*} initramfs/usr/lib/udev/rules.d/
            rm -f initramfs/usr/lib/udev/rules.d/*-drivers.rules
                cp -Rp busybox/examples/udhcp/simple.script initramfs/usr/share/udhcpc/simple.script
            chmod 755 initramfs/usr/share/udhcpc/simple.script
                sed -i '/should be called from udhcpc/d' initramfs/usr/share/udhcpc/simple.script
            cat <<EOF > initramfs/usr/share/udhcpc/default.script
            #!/bin/sh

            /usr/share/udhcpc/simple.script "\$@"
            /usr/sbin/pb-udhcpc "\$@"
EOF
                chmod 755 initramfs/usr/share/udhcpc/default.script
            cat <<EOF > initramfs/etc/nsswitch.conf
            passwd: files
            group: files
            shadow: files
            hosts: files
            networks:        files
            protocols:        files
            services:        files
            ethers: files
            rpc: files
            netgroup:        files
EOF
                cat <<EOF > initramfs/etc/group
        root:x:0:
        daemon:x:1:
        tty:x:5:
        disk:x:6:
        lp:x:7:
        kmem:x:15:
        dialout:x:20:
        cdrom:x:24:
        tape:x:26:
        audio:x:29:
        video:x:44:
        input:x:122:
EOF
            cat <<EOF > initramfs/init
            #!/bin/sh

            /bin/busybox --install -s

            CURRENT_TIMESTAMP=\$(date '+%s')
            if [ \$CURRENT_TIMESTAMP -lt \$(date '+%s') ]; then
     date -s "@\$(date '+%s')"
            fi

            mount -t proc proc /proc
            mount -t sysfs sysfs /sys
            mount -t devtmpfs none /dev
             
            echo 0 > /proc/sys/kernel/printk
            clear
             
            systemd-udevd &
            udevadm hwdb --update
            udevadm trigger

            pb-discover &
            petitboot-nc
             
            if [ -e /etc/pb-lockdown ] ; then
     echo "Failed to launch petitboot, rebooting!"
     echo 1 > /proc/sys/kernel/sysrq
     echo b > /proc/sysrq-trigger
            else
     echo "Failed to launch petitboot, dropping to a shell"
     exec sh
            fi
EOF
                chmod +x initramfs/init
            
        fi

        C=$(find initramfs/usr/sbin/ -type f | grep -c petitboot || true)
        if [ "$C" -lt 1 ] ; then
            (
     cd petitboot
     make DESTDIR="$(realpath ../initramfs/)" install
                )
                
echo " -/- strip symbols for debug"                
echo
            strip initramfs/{sbin/*,lib/$PLTFRM/*,usr/lib/$PLTFRM/*,usr/lib/udev/*_id}
                cp initramfs/usr/local/sbin/* initramfs/usr/sbin/
        fi

        if [ ! -f initramfs.igz ] ; then
            (
     cd initramfs

echo " -/- compress initramfs, mkimage"
echo
     find . | cpio -H newc -o | lzma > ../initramfs.igz
                )
            mkimage -A arm64 -O linux -T ramdisk -C lzma -a 0 -e 0 -n uInitrd.igz -d initramfs.igz uInitrd.igz
            fi

   echo "Everything is OK."

