LOCAL_DIR := $(GET_LOCAL_DIR)

MODULE := $(LOCAL_DIR)

MODULE_SRCS += \
	$(LOCAL_DIR)/start.S \
	$(LOCAL_DIR)/arch.c \
	$(LOCAL_DIR)/asm.S \
	$(LOCAL_DIR)/exceptions.c \
	$(LOCAL_DIR)/thread.c \
	$(LOCAL_DIR)/cache-ops.c \
	$(LOCAL_DIR)/mmu.c \
	$(LOCAL_DIR)/faults.c

GLOBAL_DEFINES += \
	SMP_MAX_CPUS=1

# set the default toolchain to or1k elf and set a #define
ifndef TOOLCHAIN_PREFIX
TOOLCHAIN_PREFIX := or1k-elf-
endif

cc-option = $(shell if test -z "`$(1) $(2) -S -o /dev/null -xc /dev/null 2>&1`"; \
	then echo "$(2)"; else echo "$(3)"; fi ;)

ARCH_OPTFLAGS := -O2

ARCH_LDFLAGS += -relax

LIBGCC := $(shell $(TOOLCHAIN_PREFIX)gcc $(GLOBAL_COMPILEFLAGS) $(ARCH_COMPILEFLAGS) -print-libgcc-file-name)
$(info LIBGCC = $(LIBGCC))

KERNEL_BASE ?= $(MEMBASE)
KERNEL_LOAD_OFFSET ?= 0

GLOBAL_DEFINES += \
	KERNEL_BASE=$(KERNEL_BASE) \
	KERNEL_LOAD_OFFSET=$(KERNEL_LOAD_OFFSET)

GLOBAL_DEFINES += \
    MEMBASE=$(MEMBASE) \
    MEMSIZE=$(MEMSIZE)

# we have an mmu
WITH_KERNEL_VM=1

# kernel address space definitions
# TODO: are these correct?
KERNEL_ASPACE_BASE := 0x80000000
KERNEL_ASPACE_SIZE := 0x80000000
USER_ASPACE_BASE   := 0x01000000
USER_ASPACE_SIZE   := 0x7e000000

GLOBAL_DEFINES += \
    ARCH_HAS_MMU=1 \
	KERNEL_ASPACE_BASE=$(KERNEL_ASPACE_BASE) \
	KERNEL_ASPACE_SIZE=$(KERNEL_ASPACE_SIZE) \
	USER_ASPACE_BASE=$(USER_ASPACE_BASE) \
	USER_ASPACE_SIZE=$(USER_ASPACE_SIZE)

# potentially generated files that should be cleaned out with clean make rule
GENERATED += \
	$(BUILDDIR)/linker.ld

# rules for generating the linker
$(BUILDDIR)/linker.ld: $(LOCAL_DIR)/linker.ld $(wildcard arch/*.ld)
	@echo generating $@
	@$(MKDIR)
	$(NOECHO)sed "s/%MEMBASE%/$(MEMBASE)/;s/%MEMSIZE%/$(MEMSIZE)/;s/%KERNEL_BASE%/$(KERNEL_BASE)/;s/%KERNEL_LOAD_OFFSET%/$(KERNEL_LOAD_OFFSET)/" < $< > $@

LINKER_SCRIPT += $(BUILDDIR)/linker.ld

include make/module.mk
