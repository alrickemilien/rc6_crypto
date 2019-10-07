ifneq ($(shell uname -s), Darwin)
$(error OSX required ...)
endif

ifneq ($(CC),)
CC=clang
endif

ifneq ($(CC),)
CCASM=~/.brew/bin/nasm
endif

NASM_VERSION=$(shell $(CCASM) -v | cut -d' ' -f3)

REAQUIRED_NSAM_VERSION=2.14.02

ifneq ($(NASM_VERSION), $(REAQUIRED_NSAM_VERSION))
$(error the actual version is $(NASM_VERSION), version $(REAQUIRED_NSAM_VERSION) required ...)
endif

OUT_DIR=./build

$(shell mkdir -p $(OUT_DIR))

# Assembly flags
SFLAGS=-f macho64

# C flags
CFLAGS=-Wall -Wextra -Werror

include make/ww_crypto.mk
include make/test.mk

.PHONY: all clean fclean test

all: $(WW_CRYPTO) $(TEST)

clean:
	@rm -rf $(OBJ) $(TEST_OBJ)

fclean: clean
	@rm -rf $(WW_CRYPTO) $(TEST)

re: fclean all