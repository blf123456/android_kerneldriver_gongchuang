DDK_TARGET ?= android14-6.1
KDIR ?= /opt/ddk/kdir/$(DDK_TARGET)
ARCH ?= arm64
LLVM ?= 1
LLVM_IAS ?= 1
DRIVER_DIR ?= $(CURDIR)/src

.PHONY: all modules clean
all: modules

modules:
	$(MAKE) -C "$(KDIR)" M="$(DRIVER_DIR)" ARCH=$(ARCH) LLVM=$(LLVM) LLVM_IAS=$(LLVM_IAS) CONFIG_DEBUG_INFO_BTF_MODULES= modules

clean:
	$(MAKE) -C "$(KDIR)" M="$(DRIVER_DIR)" ARCH=$(ARCH) LLVM=$(LLVM) LLVM_IAS=$(LLVM_IAS) clean
