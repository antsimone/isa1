BIN := main
SRC := $(wildcard *.c)
OBJ := $(SRC:.c=.o)
DEP := $(OBJ:.o=.d)

CFLAGS := -Wall -MMD -pedantic

$(BIN): $(OBJ)
	$(CC) $(CFLAGS) $^ -o $@
	
-include $(DEP)

clean: 
	@rm -f $(BIN) *.o *.d *~
	
.PHONY: clean
