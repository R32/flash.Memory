CC		:= g++
CFLAGS	:=
INCLUDE	:= -I.
OBJ_DIR	:= obj
TARGET	:= hello.exe
PCH_H   := stdafx.h

SOURCE_DIR 	:= .
#CFILES		:= $(foreach dir,$(SOURCE_DIR), $(wildcard $(dir)/*.c))
CPPFILES	:= $(foreach dir,$(SOURCE_DIR), $(wildcard $(dir)/*.cpp))
OBJS		:= $(addprefix $(OBJ_DIR)/, $(notdir $(CPPFILES:.cpp=.o) $(CFILES:.c=.co)))



all: $(OBJ_DIR) $(TARGET)
	@echo run...........$(CFLAGS)
	@echo
	@./$(TARGET)


clean:
	@rm -rf $(OBJ_DIR) $(PCH_H).gch $(TARGET) *.stackdump .depend

.PHONY: clean


$(TARGET): $(OBJS)
	@echo link....
	$(CC) $(CFLAGS) $(INCLUDE) $^ -o $(TARGET)

$(OBJ_DIR):
	@mkdir -p $@


$(OBJ_DIR)/%.o: $(SOURCE_DIR)/%.cpp $(SOURCE_DIR)/%.h
	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@

#$(OBJ_DIR)/%.co: $(SOURCE_DIR)/%.c
#	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@

$(PCH_H).gch: $(PCH_H)
	$(CC) $(CFLAGS) $(INCLUDE) $< -o $@


#DEPS := .depend
#$(DEPS): $(CFILES) $(CPPFILES)
#	$(CC) $(CFLAGS) $(INCLUDE) -MM $^ > $(DEPS)
#include $(DEPS)