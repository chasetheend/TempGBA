# - - - Modifiable paths - - -
DS2SDKPATH  := /opt/ds2sdk
CROSS       := /opt/mipsel-4.1.2-nopic/bin/mipsel-linux-

# - - - Libraries and includes - - -
FS_DIR       = $(DS2SDKPATH)/libsrc/fs
CONSOLE_DIR  = $(DS2SDKPATH)/libsrc/console
KEY_DIR      = $(DS2SDKPATH)/libsrc/key
ZLIB_DIR     = $(DS2SDKPATH)/libsrc/zlib
CORE_DIR     = $(DS2SDKPATH)/libsrc/core

LIBS        := $(DS2SDKPATH)/lib/libds2b.a -lc -lm -lgcc
EXTLIBS     := $(DS2SDKPATH)/lib/libds2a.a

INCLUDE     := -Inds -I$(DS2SDKPATH)/include \
               -I$(FS_DIR) -I$(CONSOLE_DIR) -I$(KEY_DIR) -I$(ZLIB_DIR) \
               -I$(CORE_DIR)

LINK_SPEC   := $(DS2SDKPATH)/specs/link.xn
START_ASM   := $(DS2SDKPATH)/specs/start.S
START_O     := start.o

# - - - Names - - -
OUTPUT      := pokegba
PLUGIN_DIR  := POKEGBA

# - - - Tools - - -
CC           = $(CROSS)gcc
AR           = $(CROSS)ar rcsv
LD           = $(CROSS)ld
OBJCOPY      = $(CROSS)objcopy
NM           = $(CROSS)nm
OBJDUMP      = $(CROSS)objdump

# - - - Sources and objects - - -
C_SOURCES    = source/nds/gpsp_main.c    \
               source/nds/cpu_common.c   \
               source/nds/cpu_asm.c      \
               source/nds/video.c       \
               source/nds/gu.c          \
               source/nds/memory.c      \
               source/nds/sound.c       \
               source/nds/input.c       \
               source/nds/gui.c         \
               source/nds/cheats.c      \
               source/nds/bios.c        \
               source/nds/draw.c        \
               source/nds/bdf_font.c    \
               source/nds/zip.c         \
               source/nds/bitmap.c      \
               source/nds/ds2_main.c
# source/nds/cpu_c.c
CPP_SOURCES  = 
ASM_SOURCES  = source/nds/mips_stub.S
SOURCES      = $(C_SOURCES) $(CPP_SOURCES) $(ASM_SOURCES)
C_OBJECTS    = $(C_SOURCES:.c=.o)
CPP_OBJECTS  = $(CPP_SOURCES:.cpp=.o)
ASM_OBJECTS  = $(ASM_SOURCES:.S=.o)
OBJECTS      = $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS)

# - - - Compilation flags - - -
CFLAGS := -mips32 -mno-abicalls -fno-pic -fno-builtin \
	      -fno-exceptions -ffunction-sections -mno-long-calls \
	      -msoft-float -G 4 \
          -O3 -fomit-frame-pointer -fgcse-sm -fgcse-las -fgcse-after-reload \
          -fweb -fpeel-loops

DEFS   := -DNDS_LAYER
# Usable flags are
# -DTEST_MODE
# -DUSE_DEBUG
# -DUSE_C_CORE

.PHONY: clean makedirs
.SUFFIXES: .elf .dat .plg .c .S .o

all: $(OUTPUT).plg makedirs

release: all
	-rm -f $(OUTPUT).zip
	zip -r $(OUTPUT).zip $(PLUGIN_DIR) $(OUTPUT).plg $(OUTPUT).bmp $(OUTPUT).ini copyright installation.txt README.md source.txt

# $< is the source (OUTPUT.dat); $@ is the target (OUTPUT.plg)
.dat.plg:
	$(DS2SDKPATH)/tools/makeplug $< $@

# $< is the source (OUTPUT.elf); $@ is the target (OUTPUT.dat)
.elf.dat:
	$(OBJCOPY) -x -O binary $< $@

$(OUTPUT).elf: Makefile $(OBJECTS) $(START_O) $(LINK_SPEC) $(EXTLIBS)
	$(CC) -nostdlib -static -T $(LINK_SPEC) -o $@ $(START_O) $(OBJECTS) $(EXTLIBS) $(LIBS)

$(EXTLIBS):
	$(MAKE) -C $(DS2SDKPATH)/source/

$(START_O): $(START_ASM)
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ -c $<

makedirs:
	-rm -rf $(PLUGIN_DIR)
	-cp -r TEMPGBA $(PLUGIN_DIR)
	-mkdir $(PLUGIN_DIR)/gamepak
	-mkdir $(PLUGIN_DIR)/gamecht
	-mkdir $(PLUGIN_DIR)/gamerts
	-mkdir $(PLUGIN_DIR)/gamepic

clean:
	-rm -rf $(OUTPUT).plg $(OUTPUT).dat $(OUTPUT).elf depend $(OBJECTS) $(START_O)

.c.o:
	$(CC) $(CFLAGS) $(INCLUDE) $(DEFS) -o $@ -c $<
.cpp.o:
	$(CC) $(CFLAGS) $(INCLUDE) $(DEFS) -fno-rtti -o $@ -c $<
.S.o:
	$(CC) $(CFLAGS) $(INCLUDE) $(DEFS) -D__ASSEMBLY__ -o $@ -c $<

Makefile: depend

depend: $(SOURCES)
	$(CC) -MM $(CFLAGS) $(INCLUDE) $(DEFS) $(SOURCES) > $@
	touch Makefile

-include depend
