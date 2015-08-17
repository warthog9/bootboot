SHELL = /bin/bash

PWD := $(shell pwd)


ifndef BOOTBOOT_CONFIG
BOOTBOOT_CONFIG=CONFIG
endif

-include $(BOOTBOOT_CONFIG)

BOOTBOOT_ABSPATH = 

export BOOTBOOTPREFIX

#.SILENT:

COREDIR = bootboot
IPXEDIR = ipxe
SYSLINUXDIR = syslinux
PXEKNIFEDIR = pxeknife
#SUPPORTDIRS = $(SYSLINUXDIR) $(PXEKNIFEDIR)
SUPPORTDIRS = $(PXEKNIFEDIR)
#SUPPORTDIRS = $(SYSLINUXDIR)

IPXEIMAGESDIR = ipxe_images

DIRS = $(COREDIR) $(SUPPORTDIRS)

#all: make_statement $(DIRS) configurebootboot installinitrds
#all: make_statement $(DIRS)
#all: make_statement pxeknife
all: make_statement $(DIRS) bootboot 

bootboot: $(SUPPORTDIRS) $(IPXEDIR)

clean: make_statement $(patsubst %,%.clean,$(DIRS))

make_statement:
	echo "Boot Boot build process manager says: HELLO WORLD!"


$(SYSLINUXDIR): $(patsubst %,%.build,$(SYSLINUXDIR)) $(patsubst %,%.install,$(SYSLINUXDIR))
$(IPXEDIR): $(patsubst %,%.build,$(IPXEDIR)) $(patsubst %,%.install,$(IPXEDIR))
$(PXEKNIFEDIR): $(patsubst %,%.build,$(PXEKNIFEDIR))
#$(COREDIR): $(patsubst %,%.build,$(COREDIR))

$(patsubst %,%.build,$(SUPPORTDIRS)): make_statement
	$(MAKE) $(MFLAGS) BOOTBOOT_ABSPATH="$(BOOTBOOT_ABSPATH)/$(shell echo "$@" | sed 's/\.build//')" BOOTBOOT_CONFIG="../$(BOOTBOOT_CONFIG)" -C $(shell echo "$@" | sed 's/\.build//') -f Makefile

$(patsubst %,%.build,$(IPXEDIR)): make_statement
	cat ipxe_scripts/pxeDHCP.tmpl   | sed 's/P_BOOT_URL/$(shell echo "$(BASE_URL)" | sed -e 's/\//\\\//gi' )/g' > $(IPXEDIR)/src/pxeDHCP.ipxe
	cat ipxe_scripts/pxeSTATIC.tmpl | sed 's/P_BOOT_URL/$(shell echo "$(BASE_URL)" | sed -e 's/\//\\\//gi' )/g' > $(IPXEDIR)/src/pxeSTATIC.ipxe
	$(MAKE) $(MFLAGS) EMBEDDED_IMAGE=pxeDHCP.ipxe,pxeSTATIC.ipxe -C $(IPXEDIR)/src -f Makefile

$(COREDIR) ipxe_images: make_statement
	mkdir -p $@

$(patsubst %,%.install,$(SYSLINUXDIR)): make_statement
	find \
		$(SYSLINUXDIR) \
		 -type f \
		\( \
			-name *.c32 \
			-o \
			-name memdisk \
			-o \
			-name pxelinux.0 \
		\) \
		-exec cp {} bootboot/ \;

$(patsubst %,%.install,$(IPXEDIR)): make_statement ipxe_images
	$(MAKE) $(MFLAGS) EMBEDDED_IMAGE=pxeDHCP.ipxe,pxeSTATIC.ipxe -C $(IPXEDIR)/src -f Makefile bin/ipxe.usb
	$(MAKE) $(MFLAGS) EMBEDDED_IMAGE=pxeDHCP.ipxe,pxeSTATIC.ipxe -C $(IPXEDIR)/src -f Makefile bin/ipxe.dsk
	$(MAKE) $(MFLAGS) EMBEDDED_IMAGE=pxeDHCP.ipxe,pxeSTATIC.ipxe -C $(IPXEDIR)/src -f Makefile bin/ipxe.iso
	$(MAKE) $(MFLAGS) EMBEDDED_IMAGE=pxeDHCP.ipxe,pxeSTATIC.ipxe -C $(IPXEDIR)/src -f Makefile bin/ipxe.lkrn
	#$(MAKE) $(MFLAGS) EMBEDDED_IMAGE=pxeDHCP.ipxe,pxeSTATIC.ipxe -C $(IPXEDIR)/src -f Makefile bin/ipxe.sdsk
	$(MAKE) $(MFLAGS) EMBEDDED_IMAGE=pxeDHCP.ipxe,pxeSTATIC.ipxe -C $(IPXEDIR)/src -f Makefile bin/ipxe.pxe
	$(MAKE) $(MFLAGS) EMBEDDED_IMAGE=pxeDHCP.ipxe,pxeSTATIC.ipxe -C $(IPXEDIR)/src -f Makefile bin/undionly.kpxe
	mv $(IPXEDIR)/src/bin/ipxe.usb $(IPXEDIR)/src/bin/ipxe.dsk $(IPXEDIR)/src/bin/ipxe.iso $(IPXEDIR)/src/bin/ipxe.lkrn ipxe_images/
	#mv $(IPXEDIR)/src/bin/ipxe.sdsk $(IPXEDIR)/src/bin/ipxe.pxe $(IPXEDIR)/src/bin/undionly.kpxe ipxe_images/
	mv $(IPXEDIR)/src/bin/ipxe.pxe $(IPXEDIR)/src/bin/undionly.kpxe ipxe_images/

$(patsubst %,%.clean,$(DIRS)):
	$(MAKE) $(MFLAGS) -C $(patsubst %.clean,%,$@) -f Makefile clean

$(patsubst %,%.clean,$(IPXEDIR)):
	$(MAKE) $(MFLAGS) -C $(patsubst %.clean,%,$@)/src -f Makefile clean

configurebootboot: make_statement
	( \
		cd install_help; \
		./configure_BOOTBOOT.sh; \
	)

installinitrds: make_statement configurebootboot
	( \
		cd install_help; \
		./download_initramfs_images_http.sh; \
	)

menu menumerge:
