NASM_VER_NUM=$(shell $(CCASM) -v | cut -d' ' -f3)

NASM_VER_MAJOR := $(shell echo $(NASM_VER_NUM) | cut -f1 -d.)
NASM_VER_MINOR := $(shell echo $(NASM_VER_NUM) | cut -f2 -d.)

ifeq ($(shell [ $(NASM_VER_MAJOR) -lt 2 -o $(NASM_VER_MINOR) -lt 11 ] && echo true), true)
$(error the actual version is $(NASM_VER_NUM), version >= $(NASM_VER_MAJOR).$(NASM_VER_MINOR) required ...)
endif

WW_CRYPTO=$(OUT_DIR)/libww_crypto.so

ifeq ($(shell uname -s), Darwin)
SRC=src/osx/rc6.s
endif

ifeq ($(shell uname -s), Linux)
SRC=src/linux_x86/rc6.s
endif

OBJ=$(SRC:.s=.o)

$(WW_CRYPTO): $(OBJ)
	$(CC) -shared $^ -o $@ $(CFLAGS)

%.o: %.s
	$(CCASM) $(SFLAGS) $< -o $@