.SECONDARY:
ROOT   = /Users/luca/Documents/GitHub/Embedded-Software/Toolchain/Compilers
CC_DIR = $(ROOT)/gcc-arm-none-eabi/bin
CC     = $(CC_DIR)/arm-none-eabi-gcc
AR     = $(CC_DIR)/arm-none-eabi-ar
SIZE   = $(CC_DIR)/arm-none-eabi-size
OBJCOPY = $(CC_DIR)/arm-none-eabi-objcopy
OBJDUMP = $(CC_DIR)/arm-none-eabi-objdump
READELF = $(CC_DIR)/arm-none-eabi-readelf

CFLAGS += -mcpu=cortex-m4 -mthumb -Og -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -ffreestanding -flto \
		  -Wunused -Wuninitialized -Wall -Wextra -Wmissing-declarations -Wconversion -Wpointer-arith -Wshadow -Wlogical-op \
		  -Waggregate-return -Wfloat-equal -Wmissing-prototypes -Wstrict-prototypes -Wbad-function-cast -g3


CFLAGS += $(foreach file,$(INC),-I"$(file)")

# Linker options
LFLAGS = -L"./test/demo/ldscript" -T mem.ld -nostartfiles -Xlinker --gc-sections -Wl,-Map=$(OUTPUT).map

# Link Time Optimization plugin used for library generation
PLUGIN    = $(ROOT)/gcc-arm-none-eabi/lib/gcc/arm-none-eabi/10.2.1/liblto_plugin.0.so

# Define here your main target
TARGET  = test/demo/main.c

# Startup file to boot-up system
STARTUP = test/demo/device/startup.c

# Main output directory
BUILD_DIR = ./bin

# Include paths
INC = \
./inc \
./test/demo/device/inc

# Output Library name
LIB 	  = embcli

# Source files to compile for the library
LIB_SRC   += \
src/embcli.c 

# Source files to compile for the demo
DEMO_SRC += \
$(STARTUP) \
test/demo/main.c \
test/demo/device/system.c \
test/demo/device/RCC.c \
test/demo/device/GPIO.c \
test/demo/device/USART.c 


OUTPUT    = $(foreach file, $(TARGET),$(BUILD_DIR)/$(file:%.c=%))
OBJS 	  = $(foreach file, $(DEMO_SRC),$(BUILD_DIR)/$(file:%.c=%.o))
LIB_OBJS  = $(foreach file, $(LIB_SRC),$(BUILD_DIR)/$(file:%.c=%.o))

all: $(BUILD_DIR) $(OUTPUT).elf $(OUTPUT).hex

%.hex: %.elf
	$(OBJCOPY) -O ihex $^ $@

%.elf: %.o $(OBJS) $(LIB).a
	@echo 'Building binary: $<'
	@echo 'Invoking: GNU ARM Cross C Compiler'
	$(CC) $(OBJS) $(CFLAGS) $(LFLAGS) -L"./bin" -l$(LIB) -o $@

$(BUILD_DIR)/%.o: %.c 
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C Compiler'
	$(CC) $(CFLAGS) -c "$<" -o "$@" 
	@echo 'Finished building: $<'
	@echo ' '

$(LIB).a: $(LIB_OBJS)
	@echo 'Generating library: $@'
	$(AR) -rc $(BUILD_DIR)/lib$(LIB).a $^ --plugin $(PLUGIN) 

$(BUILD_DIR):
	@echo 'Creating build directories'
	@mkdir -p $(BUILD_DIR)/src
	@mkdir -p $(BUILD_DIR)/test
	@mkdir -p $(BUILD_DIR)/test/demo
	@mkdir -p $(BUILD_DIR)/test/demo/device
	@mkdir -p $(BUILD_DIR)/test/unittest
	@echo '$(BUILD_DIR) created'

.PHONY: clean
clean:
	rm -r $(BUILD_DIR)

.PHONY: size
size: $(OUTPUT).elf
	$(SIZE) $^

.PHONY: symbol
symbol: $(OUTPUT).elf
	$(READELF) -s $^

.PHONY: sections
sections: $(OUTPUT).elf
	$(READELF) -S $^

.PHONY: disassembly
disassembly: $(OUTPUT).elf
	@echo 'Generate Disassemby: $(OUTPUT).s'
	@echo 'Invoking: arm-none-eabi-objdump'
	$(OBJDUMP) -d -S $(OUTPUT).elf > $(OUTPUT).s

.PHONY: setup
setup:
	@echo 'Setup python environment'
	@echo 'Invoking: pip'
	pip install -r requirements.txt

.PHONY: foo
foo: $(OBJS)
	@echo $^
	@echo $@

include test/unittest/makefile_ut.mk