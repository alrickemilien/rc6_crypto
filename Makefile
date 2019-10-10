# Set default C compiler
ifeq ($(CC),)
CC=clang
endif

# Set default asm compiler
ifeq ($(CCASM),)
CCASM=~/.brew/bin/nasm
endif

ifeq ($(RH_GT_5_3),true)
CPPFLAGS += -DRH_GT_5_3=1
endif

OUT_DIR=./build

$(shell mkdir -p $(OUT_DIR))

# Assembly flags
ifeq ($(shell uname -s), Darwin)
SFLAGS=-f macho64
endif

ifeq ($(shell uname -s), Linux)
SFLAGS=-f elf64
endif


# C flags
CFLAGS=-Wall -Wextra -Werror

include make/ww_crypto.mk
include make/test.mk

.PHONY: all clean fclean

all: $(WW_CRYPTO) $(TEST)

clean:
	@rm -rf $(OBJ) $(TEST_OBJ)

fclean: clean
	@rm -rf $(WW_CRYPTO) $(TEST)

re: fclean all