WW_CRYPTO=$(OUT_DIR)/libww_crypto.so
SRC=src/encrypt.s
OBJ=$(SRC:.s=.o)

$(WW_CRYPTO): $(OBJ)
	$(CC) -shared $^ -o $@ $(CFLAGS)

%.o: %.s
	$(CCASM) $(SFLAGS) $< -o $@