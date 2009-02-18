
export PRJROOT:=$(PWD)

include $(PRJROOT)/Rules.mak
-include $(PRJROOT)/.config

TOOLCHAIN_DIR			:= $(PRJROOT)/scripts/toolchain
TOOLCHAIN			:= $(TOOLCHAIN_DIR)/$(patsubst "%",%,$(TOOLCHAIN))
export PATH			:= $(TOOLCHAIN_DIR)/bin:$(shell echo $$PATH)
CONFIG_DIR			:= $(PRJROOT)/config
KERNEL_SRC_DIR			:= $(PRJROOT)/$(patsubst "%",%,$(KERNEL_SRC))
ROOTFS_DIR			:= $(PRJROOT)/rootfs
export BASE_ROOTFS		:= $(ROOTFS_DIR)/$(patsubst "%",%,$(BASE_ROOTFS))
BUSYBOX_SRC_DIR			:= $(PRJROOT)/$(patsubst "%",%,$(BUSYBOX_SRC))
export TARGET_DIR		:= $(PRJROOT)/target

export TARGET_ROOTFS_DIR	:= $(TARGET_DIR)/rootfs
export TARGET_BIN_DIR		:= $(TARGET_DIR)/bin

BUILT_VERSION			:= $(TARGET_BIN_DIR)/built_version

export ANDROID
export ANDROID_ROOTFS		:= $(patsubst "%",%,$(ANDROID_ROOTFS))
#export TARGET_ANDROID_ROOTFS_DIR	:= $(TARGET_DIR)/android_rootfs
export ANDROID_GIT
export ANDROID_GIT_ROOTFS	:= $(patsubst "%",%,$(ANDROID_GIT_ROOTFS))

FS :=
ifeq "$(JFFS2)" "y"
	FS += jffs2
endif
ifeq "$(YAFFS2)" "y"
	FS += yaffs2
endif


modules:=rootfs toolchain kernel busybox version

.PHONY: all build install clean distclean menuconfig
.PHONY: jffs2 yaffs2

all: check_dir
	$(MAKE) build
	$(MAKE) install
ifneq "$(FS)" ""
	$(MAKE) $(FS)
endif
ifeq "$(HOST_TFTP)" "y"
	cp -af $(TARGET_BIN_DIR)/* $(TFTP_DIR)
endif
ifeq "$(NFS_ROOT)" "y"
	cp -af $(TARGET_ROOTFS_DIR) $(NFS_ROOT_DIR)
endif

#ifeq "$(JFFS2)" "y"
#	$(MAKE) jffs2
#endif
#ifeq "$(YAFFS2)" "y"
#	$(MAKE) yaffs2
#endif

check_dir:
	@test -d $(TARGET_DIR) || mkdir -p $(TARGET_DIR)
	@test -d $(TARGET_ROOTFS_DIR) || mkdir -p $(TARGET_ROOTFS_DIR)
	@test -d $(TARGET_BIN_DIR) || mkdir -p $(TARGET_BIN_DIR)
	@test -d $(TOOLCHAIN_DIR)/bin || $(MAKE) build_toolchain

build: $(addprefix build_,$(modules))

install: $(addprefix install_,$(modules))

clean: distclean
#distclean: $(addprefix clean_,$(modules))
distclean: $(addprefix clean_, $(filter-out toolchain,$(modules)) toolchain)
	-rm -rf $(TARGET_DIR)
	$(MAKE) clean_menuconfig
	-rm -f .config

.PHONY: build_toolchain install_toolchain clean_toolchain
build_toolchain:
	@if [ ! -e $(TOOLCHAIN_DIR)/bin ] ; then \
		file -b $(TOOLCHAIN) | awk '{print $$1 " -d -c -v $(TOOLCHAIN)"}' | sh - | tar xvf - -C $(TOOLCHAIN_DIR); \
	fi

install_toolchain:
clean_toolchain:
	-find $(TOOLCHAIN_DIR)/* -maxdepth 0 -type d -exec rm -rf {} \;

.PHONY: build_kernel install_kernel clean_kernel
build_kernel:
	@if [ ! -e $(KERNEL_SRC_DIR)/.config ]; then \
		cd $(KERNEL_SRC_DIR) && $(MAKE) defconfig; \
	fi
	cd $(KERNEL_SRC_DIR) && $(MAKE)

install_kernel:
	cd $(KERNEL_SRC_DIR) && $(MAKE) INSTALL_MOD_PATH=$(TARGET_ROOTFS_DIR) modules_install 
	cp -f $(KERNEL_SRC_DIR)/arch/$(ARCH)/boot/zImage $(TARGET_BIN_DIR)
	gzip -9 -f $(TARGET_BIN_DIR)/zImage
	rm -f $(TARGET_BIN_DIR)/uImage
	$(PRJROOT)/scripts/bin/mkimage -A arm -O linux -T kernel -C gzip -a 0xa0008000 -e 0xa0008000 -n "EPS-Android" -d $(TARGET_BIN_DIR)/zImage.gz $(TARGET_BIN_DIR)/uImage
	rm -f $(TARGET_BIN_DIR)/zImage.gz
#ifeq "$(HOST_TFTP)" "y"
#	cp -f $(TARGET_BIN_DIR)/uImage $(TFTP_DIR)
#endif

clean_kernel:
	cd $(KERNEL_SRC_DIR) && $(MAKE) distclean

.PHONY: build_busybox install_busybox clean_busybox
build_busybox:
	@if [ ! -e $(BUSYBOX_SRC_DIR)/.config ] ; then \
		cp $(CONFIG_DIR)/busybox_config $(BUSYBOX_SRC_DIR)/.config; \
		cd $(BUSYBOX_SRC_DIR) && $(MAKE) oldconfig; \
	fi
	cd $(BUSYBOX_SRC_DIR) && $(MAKE)

install_busybox:
	cd $(BUSYBOX_SRC_DIR) && $(MAKE) install
	@if [ -e $(TARGET_ROOTFS_DIR)/bin/busybox ] ; then \
		chmod u+s $(TARGET_ROOTFS_DIR)/bin/busybox; \
	fi

clean_busybox:
	cd $(BUSYBOX_SRC_DIR) && $(MAKE) distclean

.PHONY: build_rootfs install_rootfs clean_rootfs
build_rootfs:
	cd $(ROOTFS_DIR) && $(MAKE)

install_rootfs:
	#rm -rf $(TARGET_ROOTFS_DIR)/*
	rm -rf $(TARGET_ROOTFS_DIR)
#	rm -rf $(TARGET_DIR)
	$(MAKE) check_dir
	cd $(ROOTFS_DIR) && $(MAKE) install
	$(MAKE) build_version
	$(MAKE) install_version
	#rsync -r --exclude='.svn' $(PRJROOT)/rootfs/rootfs.overwrite/* $(TARGET_ROOTFS_DIR)

clean_rootfs:
	cd $(ROOTFS_DIR) && $(MAKE) distclean

menuconfig:
	@if [ ! -e $(PRJROOT)/scripts/config/mconf ] ; then \
		cd $(PRJROOT)/scripts/config/ && $(MAKE); \
	fi
	#@./scripts/kconfig/mconf ./scripts/Config.in
	@$(PRJROOT)/scripts/config/mconf $(PRJROOT)/scripts/Config.in

clean_menuconfig:
	-cd $(PRJROOT)/scripts/config && $(MAKE) clean

# compound rules
rebuild_%:
	$(MAKE) clean_$*
	$(MAKE) build_$*

update_%:
	$(MAKE) build_$*
	$(MAKE) install_$*

.PHONY: help
help:
	@echo ""
	@echo "*** EPS Android build script ***"
	@echo ""
	@echo "Usage: make [targets]"
	@echo ""
	@echo "Available targets:"
	@echo "  all              - build all modules + whole target system"
	@echo "  menuconfig       - update current config utilising a menu based program"
	@echo "  clean            - clean all generated files + whole target system"
	@echo "  build_<module>   - build <module>" 
	@echo "  clean_<module>   - clean <module> generated files"
	@echo "  install_<module> - install <module> files"
	@echo "  rebuild_<module> - run clean_<module> and build_<module>"
	@echo "  update_<module>  - run build_<module> and install_<module>"
	@echo ""
	@echo "Module list:"
	@for i in $(modules); do\
		echo "  $$i"; \
	done
	@echo ""

.PHONY: build_version install_version clean_version
build_version:
install_version:
	@if [ ! -d $(TARGET_BIN_DIR) ] ; then \
		mkdir -p $(TARGET_BIN_DIR); \
	fi
	@echo "EPS Android Build" > $(BUILT_VERSION)
	@echo "---" >> $(BUILT_VERSION)
	@echo -n "Built date: " >> $(BUILT_VERSION)
	@echo "$(shell date --rfc-3339=second)" >> $(BUILT_VERSION)
	@echo "Builder: $(USER)" >> $(BUILT_VERSION)
	@echo -n "SVN revision: " >> $(BUILT_VERSION)
	@echo "$(shell LANG=C ; svn info $(PRJROOT) | grep -i "revision" | awk '{print $$2}')" >> $(BUILT_VERSION)
	@echo "---" >> $(BUILT_VERSION)
	@if [ ! -d $(TARGET_ROOTFS_DIR)/etc ] ; then \
		mkdir -p $(TARGET_ROOTFS_DIR)/etc; \
	fi
	cp $(BUILT_VERSION) $(TARGET_ROOTFS_DIR)/etc

clean_version:
	-rm -f $(BUILT_VERSION)

strip_rootfs:
	-find $(TARGET_ROOTFS_DIR) -type l -prune -o -name "*.ko" -prune -o -print -exec $(STRIP) {} \;
	-find $(TARGET_ROOTFS_DIR) -name "*.ko" -exec $(STRIP) -g -S -d --strip-debug {} \;

jffs2: strip_rootfs
	@if [ ! -e $(PRJROOT)/scripts/bin/mtd/util/mkfs.jffs2 ] ; then \
		cd $(PRJROOT)/scripts/bin && $(MAKE) mkfs.jffs2; \
	fi
	#$(PRJROOT)/scripts/bin/mkfs.jffs2 -e 131072 --pad=0xf00000 -r $(TARGET_ROOTFS_DIR) -o $(TARGET_BIN_DIR)/rootfs.jffs2
	$(PRJROOT)/scripts/bin/mtd/util/mkfs.jffs2 -v -e 131072 --pad=0x1B80000 -r $(TARGET_ROOTFS_DIR) -o $(TARGET_BIN_DIR)/rootfs.jffs2

yaffs2: strip_rootfs
	@if [ ! -e $(PRJROOT)/scripts/bin/yaffs2/utils/mkyaffs2image ] ; then \
		cd $(PRJROOT)/scripts/bin && $(MAKE) mkyaffs2image; \
	fi
	$(PRJROOT)/scripts/bin/yaffs2/utils/mkyaffs2image $(TARGET_ROOTFS_DIR) $(TARGET_BIN_DIR)/rootfs.yaffs2

