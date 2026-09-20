# ---------------------------------------------------------------------------
# Portable Makefile for Brian Gladman's AES library (non-Windows builds).
#
# Builds the C + AES-NI intrinsics variant of the library (aescrypt.c,
# aeskey.c, aestab.c, aes_modes.c, aes_ni.c). The legacy YASM assembler
# variants, VIA ACE support and 32-bit x86 asm files are out of scope for
# this Makefile; see README.md / via_ace.txt for those.
#
# Targets:
#   make            build libaes.a
#   make test       build and run the built-in known-answer test (aestst.c)
#   make examples   build the aesxam.c file-encryption example
#   make clean      remove all build artifacts
#
# Tested with GNU Make + gcc/clang on Linux and macOS. Written to avoid
# GNU-Make-only constructs where reasonably possible.
# ---------------------------------------------------------------------------

CC      ?= cc
AR      ?= ar
CFLAGS  ?= -O2 -Wall -maes -mssse3

LIB     = libaes.a
LIBOBJS = aescrypt.o aeskey.o aestab.o aes_modes.o aes_ni.o

TEST_BIN     = aestst
EXAMPLE_BIN  = aesxam

.PHONY: all test examples clean

all: $(LIB)

$(LIB): $(LIBOBJS)
	$(AR) rcs $@ $(LIBOBJS)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# The known-answer test program (aestst.c) always returns exit code 0 by
# design (see its source), so a successful run is instead detected by
# checking that its output contains the expected success message. Any other
# output (e.g. "Some values are in error") or a missing binary/output makes
# this target fail with a non-zero exit code.
test: $(TEST_BIN)
	./$(TEST_BIN) | tee aestst.out
	@grep -q "These values are all correct" aestst.out || \
		(echo "FAILED: known-answer test did not report success" >&2; exit 1)

$(TEST_BIN): aestst.o $(LIB)
	$(CC) $(CFLAGS) -o $@ aestst.o -L. -laes

examples: $(EXAMPLE_BIN)

$(EXAMPLE_BIN): aesxam.o $(LIB)
	$(CC) $(CFLAGS) -o $@ aesxam.o -L. -laes

clean:
	rm -f $(LIBOBJS) $(LIB) aestst.o aestst.out $(TEST_BIN) aesxam.o $(EXAMPLE_BIN)
