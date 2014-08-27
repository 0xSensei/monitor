CC32 = i686-w64-mingw32-gcc -m32
CC64 = x86_64-w64-mingw32-gcc -m64
NASM = nasm
AR = ar
CFLAGS = -Wall -O0 -ggdb -Wextra -std=c99 -static \
		 -Wno-missing-field-initializers -I inc/ -I objects/x86/code/ \
		 -DDEBUG=$(DEBUG)0
LDFLAGS = -lws2_32 -lshlwapi
MAKEFLAGS = -j8

SIGS = $(wildcard sigs/*.rst)
JINJA2 = $(wildcard data/*.jinja2)

# Dependencies for the auto-generated hook files.
HOOKREQ = utils/process.py $(wildcard data/*.json) $(wildcard data/*.conf)
HOOK32 = objects/x86/code/hooks.h objects/x86/code/hooks.c
HOOK64 = objects/x64/code/hooks.h objects/x64/code/hooks.c
HOOKOBJ32 = objects/x86/code/hooks.o
HOOKOBJ64 = objects/x64/code/hooks.o

SRC = $(wildcard src/*.c)
SRCOBJ32 = $(SRC:%.c=objects/x86/%.o)
SRCOBJ64 = $(SRC:%.c=objects/x64/%.o)
HEADER = $(wildcard inc/*.h)

ASM32 = $(wildcard asm/x86/*.asm)
ASM64 = $(wildcard asm/x64/*.asm)
ASMOBJ32 = $(ASM32:asm/x86/%.asm=objects/x86/asm/%.o)
ASMOBJ64 = $(ASM64:asm/x64/%.asm=objects/x64/asm/%.o)

ASMOBJ32 += objects/x86/asm/tramp-special.o
ASMOBJ64 += objects/x64/asm/tramp-special.o

BSON = $(wildcard src/bson/*.c)
BSONOBJ32 = $(BSON:%.c=objects/x86/%.o)
BSONOBJ64 = $(BSON:%.c=objects/x64/%.o)
LIBBSON32 = objects/x86/src/libbson.a
LIBBSON64 = objects/x64/src/libbson.a

LIBCAPSTONE32 = objects/x86/capstone/capstone.lib
LIBCAPSTONE64 = objects/x64/capstone/capstone.lib

DLL32 = monitor-x86.dll
DLL64 = monitor-x64.dll

all: dirs $(LIBCAPSTONE32) $(LIBCAPSTONE64) \
		$(HOOK32) $(HOOK64) $(DLL32) $(DLL64)
	+make -C test/
	+make -C utils/

dirs: | objects/

objects/:
	mkdir -p objects/x86/asm/ objects/x64/asm/
	mkdir -p objects/x86/code/ objects/x64/code/
	mkdir -p objects/x86/src/bson/ objects/x64/src/bson/

$(HOOK32): $(SIGS) $(JINJA2) $(HOOKREQ)
	python utils/process.py data/ objects/x86/code/ $(SIGS)

$(HOOK64): $(SIGS) $(JINJA2) $(HOOKREQ)
	python utils/process.py data/ objects/x64/code/ $(SIGS)

$(LIBBSON32): $(BSONOBJ32)
	$(AR) cr $@ $^

$(LIBBSON64): $(BSONOBJ64)
	$(AR) cr $@ $^

$(LIBCAPSTONE32):
	git submodule update --init && \
	cp data/capstone-config.mk src/capstone/config.mk && \
	cd src/capstone/ && \
	BUILDDIR=../../objects/x86/capstone/ ./make.sh cross-win32

$(LIBCAPSTONE64):
	git submodule update --init && \
	cp data/capstone-config.mk src/capstone/config.mk && \
	cd src/capstone/ && \
	BUILDDIR=../../objects/x64/capstone/ ./make.sh cross-win64

objects/x86/%.o: %.c $(HEADER) Makefile
	$(CC32) -c -o $@ $< $(CFLAGS)

objects/x86/%.o: objects/x86/%.c $(HEADER) Makefile
	$(CC32) -c -o $@ $< $(CFLAGS)

objects/x64/%.o: %.c $(HEADER) Makefile
	$(CC64) -c -o $@ $< $(CFLAGS)

objects/x64/%.o: objects/x64/%.c $(HEADER) Makefile
	$(CC64) -c -o $@ $< $(CFLAGS)

objects/x86/asm/tramp-special.o: asm/x86/tramp.asm Makefile
	$(NASM) -f elf32 -i asm/x86/ -d tramp_special=1 -o $@ $<

objects/x64/asm/tramp-special.o: asm/x64/tramp.asm Makefile
	$(NASM) -f elf64 -i asm/x64/ -d tramp_special=1 -o $@ $<

objects/x86/asm/%.o: asm/x86/%.asm Makefile
	$(NASM) -f elf32 -i asm/x86/ -o $@ $<

objects/x64/asm/%.o: asm/x64/%.asm Makefile
	$(NASM) -f elf64 -i asm/x64/ -o $@ $<

$(DLL32): $(ASMOBJ32) $(SRCOBJ32) $(HOOKOBJ32) $(LIBBSON32) $(LIBCAPSTONE32)
	$(CC32) -shared -o $@ $^ $(CFLAGS) $(LDFLAGS)

$(DLL64): $(ASMOBJ64) $(SRCOBJ64) $(HOOKOBJ64) $(LIBBSON64) $(LIBCAPSTONE64)
	$(CC64) -shared -o $@ $^ $(CFLAGS) $(LDFLAGS)

clean:
	rm -rf objects/ $(DLL32) $(DLL64)
	+make -C test/ clean
	+make -C utils/ clean
