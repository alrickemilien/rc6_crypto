# Set default C compiler
ifeq ($(CC),)
CC=/usr/bin/clang
endif

# Set default asm compiler
ifeq ($(CCASM),)
CCASM=/usr/bin/nasm
endif

OUT_DIR=./build

$(shell mkdir -p $(OUT_DIR))

include make/ww_crypto.mk
include make/test.mk

.PHONY: all clean fclean test

all: $(WW_CRYPTO) test

test: $(TEST)

clean:
	@rm -rf $(OBJ) $(TEST_OBJ)

fclean: clean
	@rm -rf $(WW_CRYPTO) $(TEST)

re: fclean all