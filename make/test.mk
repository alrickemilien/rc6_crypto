TEST=$(OUT_DIR)/test
TEST_SRC=test/test.c
TEST_OBJ=$(TEST_SRC:.c=.o)
CC_FLAGS=-Wall -Wextra -Werror

$(TEST): $(TEST_OBJ)
	$(CC) $^ -o $@ -L$(OUT_DIR) -lww_crypto $(CC_FLAGS)

%.o: %.c
	$(CC) -c $< -o $@ -I include/ $(CC_FLAGS)