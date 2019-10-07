WW_CRYPTO=$(OUT_DIR)/libww_crypto.so

ifeq ($(shell uname -s), Darwin)
SRC=src/osx/encrypt.s
endif

ifeq ($(shell uname -s), Linux)
SRC=src/linux_x86/encrypt.s
endif

OBJ=$(SRC:.s=.o)

$(WW_CRYPTO): $(OBJ)
	$(CC) -shared $^ -o $@ $(CFLAGS)

%.o: %.s
	$(CCASM) $(SFLAGS) $< -o $@