# Set default C compiler
ifeq ($(CC),)
CC=/usr/bin/clang
endif

# Set default asm compiler
ifeq ($(CCASM),)
CCASM=/usr/bin/nasm
endif

OUT_DIR=./build

.PHONY: all clean fclean test

$(shell mkdir -p $(OUT_DIR))

include make/rc6_crypto.mk
include make/test.mk

all: $(RC6_CRYPTO) test

test: $(TEST)

clean:
	@rm -rf $(OBJ) $(TEST_OBJ)

fclean: clean
	@rm -rf $(RC6_CRYPTO) $(TEST)

re: fclean all