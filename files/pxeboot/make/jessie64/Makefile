
TOP_DIR=/pxeboot
TFTP_DIR=${TOP_DIR}/tftpd/img/jessie64
NGINX_DIR=${TOP_DIR}/nginx/jessie64
SRC_DIR=./SRC


KERNEL_URI=http://www.kernel.org/pub/linux/kernel/v4.x/linux-4.7.3.tar.xz
KERNEL_FILE=$(notdir ${KERNEL_URI})
KERNEL=$(KERNEL_FILE:.tar.xz=)
KVER=$(subst linux-,,${KERNEL})
KVER_MINOR=-64net01

BUSYBOX_URI=http://busybox.net/downloads/busybox-1.25.0.tar.bz2
BUSYBOX_FILE=$(notdir ${BUSYBOX_URI})
BUSYBOX=$(BUSYBOX_FILE:.tar.bz2=)

default: 
	@echo "Usage: make target "
	@echo " Available Targets "
	@echo "\t all		: Make all files"
	@echo "\t "
	@echo "\t prep			: xxx"
	@echo "\t kernel		: Compile kernel"
	@echo "\t initrd		: Create initrd image"
	@echo "\t modules.tgz		: xxx"
	@echo "\t rootfs		: xxx"
	@echo "\t rootfs.tgz		: xxx"
	@echo

.PHONY: default

all: 
	make prep
	make kernel
	make initrd
	make modules.tgz
	make rootfs
	make rootfs.tgz

install:
	make install-kernel
	make install-rootfs


.PHONY: all kernel  

prep:
	mkdir -p SRC
	mkdir -p boot	
	mkdir -p initrd-net
	aptitude install -y debootstrap \
	cdebootstrap \
	ca-certificates \
	libncurses5-dev \
	xz-utils \
	bc gcc git bzip2 g++ \
	libtool \
	pkg-config \
	zlib1g-dev \
	libglib2.0-dev \
	autoconf \
	build-essential \
	socat lsof time \
	bridge-utils \
	libattr1-dev \
	libcap-dev \
	flex bison \
	debian-archive-keyring debian-keyring \

.PHONY: initrd
initrd: initrd-net.img

initrd-net.img: initrd-net
	(cd $< ;find . | cpio -o -H newc | gzip -9 -n > ../$@)


initrd-net: ${SRC_DIR}/${BUSYBOX}/_install initrd.init
	rsync -a --delete $</ $@/
	mkdir -p $@/sysroot
	mkdir -p $@/proc
	mkdir -p $@/sys
	mkdir -p $@/dev
	mkdir -p $@/etc
	cp initrd.init $@/init
	cp udhcpc.script $@/etc/
	chmod +x $@/etc/udhcpc.script
	chmod +x $@/init

${SRC_DIR}/${BUSYBOX}/_install: dot.config.busybox
	if [ ! -d ${SRC_DIR}/${BUSYBOX} ]; then \
	wget -c ${BUSYBOX_URI} ; \
	tar xf ${BUSYBOX_FILE} -C ${SRC_DIR}; rm ${BUSYBOX_FILE} ; fi
	cp dot.config.busybox ${SRC_DIR}/${BUSYBOX}/.config
	(cd ${SRC_DIR}/${BUSYBOX} ; \
	make menuconfig ; \
	time make -j 20 install )
	egrep  "^CONF" ${SRC_DIR}/${BUSYBOX}/.config > dot.config.busybox 
	touch $@

kernel: ${SRC_DIR}/${KERNEL}/.config installkernel
	ARCH=x86_64 nice -n 10 make -C ${SRC_DIR}/${KERNEL} -j20
	ARCH=x86_64 make -C ${SRC_DIR}/${KERNEL} install INSTALL_PATH=${CURDIR}/boot/
	(cp ${SRC_DIR}/${KERNEL}/.config dot.config.kernel ; touch ${SRC_DIR}/${KERNEL}/.config)
	ARCH=x86_64 make -C ${SRC_DIR}/${KERNEL} modules_install INSTALL_MOD_PATH=${CURDIR}/
	LD_LIBRARY_PATH=./ depmod -a -b ./ ${KVER}${KVER_MINOR}

#.PHONY: ${SRC_DIR}/${KERNEL}/.config
${SRC_DIR}/${KERNEL}/.config: dot.config.kernel
	if [ ! -d ${SRC_DIR}/${KERNEL} ]; then \
	(wget -c ${KERNEL_URI} ;\
	tar xf ${KERNEL_FILE} -C ${SRC_DIR}/; rm ${KERNEL_FILE}) ; fi
	sed -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=\"${KVER_MINOR}\"/g' dot.config.kernel > ${SRC_DIR}/${KERNEL}/.config
	ARCH=x86_64 make -C ${SRC_DIR}/${KERNEL} menuconfig
	(cd ${SRC_DIR}/${KERNEL}/; cp -v  .config .config.tmp ;\
	sed -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=\"${KVER_MINOR}\"/g' .config.tmp > .config ;\
	rm .config.tmp )
	egrep  "^CONF" ${SRC_DIR}/${KERNEL}/.config > dot.config.kernel

.PHONY: installkernel
installkernel: ~/bin/installkernel
	mkdir -p ~/bin/
	sed -e  "s/run-parts --verbose.*//g" -e "s/\/etc\/kernel\/postinst.d//g" /sbin/installkernel > ~/bin/installkernel
	chmod +x ~/bin/installkernel

.PHONY: rootfs
rootfs: 
	mkdir -p $@ 
	-cdebootstrap --include=openssh-server,openssh-client,rsync,pciutils,\
	tcpdump,strace,libpam-systemd,ca-certificates,telnet,curl,ncurses-term,\
	python,python2.7-dev,python-pip,tree,psmisc,\
	bridge-utils,sudo,aptitude,ca-certificates,apt-transport-https,\
	sudo,gcc,libffi-dev,libssl-dev,git,screen,\
	linux-image-amd64,grub-pc \
	jessie $@ http://ftp.jp.debian.org/debian
	make rootfs-modify

.PHONY: rootfs.modify
rootfs.modify: 
	echo "root:root" | chpasswd --root ${CURDIR}/$(@:.modify=)/ 
	apt-get -o RootDir=${CURDIR}/$(@:.modify=)/ clean 
	cp $(@:.modify=)/usr/share/zoneinfo/Japan $(@:.modify=)/etc/localtime 
	echo "Asia/Tokyo" > $(@:.modify=)/etc/timezone 
	if [ -f ~/.ssh/authorized_keys ]; then \
	mkdir -p $(@:.modify=)/root/.ssh && chmod 700 $(@:.modify=)/root/.ssh && cp ~/.ssh/authorized_keys $(@:.modify=)/root/.ssh/ ;\
	fi 
	cp /etc/hosts $(@:.modify=)/etc/ 
	cp install_linux.sh $(@:.modify=)/root/
	chmod +x $(@:.modify=)/root/install_linux.sh
	make rootfs.tgz

.PHONY: rootfs.tgz
rootfs.tgz: 
	if [ -f $@ ]; then mv $@ $@.old; fi
	if [ -f .ssh/id_rsa.pub ]; then \
	cat .ssh/id_rsa.pub > rootfs/root/.ssh/authorized_keys ; fi
	if [ -f .ssh/id_rsa ]; then \
	cat .ssh/id_rsa > rootfs/root/.ssh/id_rsa ; fi
	(cd $(@:.tgz=) ; tar cf - .)|gzip > $@

modules.tgz: lib/modules/${KVER}${KVER_MINOR}
	tar cf - $< | gzip > $@

install-kernel: modules.tgz boot/vmlinuz-${KVER}${KVER_MINOR} initrd-net.img 
	cp -p boot/vmlinuz-${KVER}${KVER_MINOR} ${TFTP_DIR}
	cp -p initrd-net.img ${TFTP_DIR}
	cp -p modules.tgz ${NGINX_DIR}/modules.tgz.${KVER}${KVER_MINOR}
	(cd ${TFTP_DIR} ; ln -sf vmlinuz-${KVER}${KVER_MINOR} linux )
	(cd ${TFTP_DIR} ; ln -sf initrd-net.img initrd )
	(cd ${NGINX_DIR} ; ln -sf modules.tgz.${KVER}${KVER_MINOR} modules.tgz )

install-rootfs:
	(cd ${NGINX_DIR} ; if [ -f rootfs.tgz ]; then cp -p rootfs.tgz rootfs.tgz.$(shell date +"%Y%m%d%H%M" -r rootfs.tgz) ;fi ) 
	cp -p rootfs.tgz ${NGINX_DIR}


