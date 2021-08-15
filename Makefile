# -*- Makefile -*- for abseil

.SECONDEXPANSION:
.SUFFIXES:

ifneq ($(findstring $(MAKEFLAGS),s),s)
ifndef V
        QUIET          = @
        QUIET_CXX      = @echo '   ' CXX $<;
        QUIET_AR       = @echo '   ' AR $@;
        QUIET_RANLIB   = @echo '   ' RANLIB $@;
        QUIET_INSTALL  = @echo '   ' INSTALL $<;
        export V
endif
endif

LIB      = libabseil.a
AR      ?= ar
ARFLAGS ?= rc
CXX     ?= g++
RANLIB  ?= ranlib
RM      ?= rm -f

BUILD_DIR := obj
BUILD_ID  ?= default-build-id
OBJ_DIR   := $(BUILD_DIR)/$(BUILD_ID)

ifeq (,$(BUILD_ID))
$(error BUILD_ID cannot be an empty string)
endif

prefix ?= /usr/local
libdir := $(prefix)/lib
includedir := $(prefix)/include

HEADERS := \
	$(shell find absl -type f -name '*.h') \
	$(shell find absl -type f -name '*.inc') \

SOURCES := \
    absl/base/internal/cycleclock.cc \
    absl/base/internal/low_level_alloc.cc \
    absl/base/internal/periodic_sampler.cc \
    absl/base/internal/raw_logging.cc \
    absl/base/internal/scoped_set_env.cc \
    absl/base/internal/spinlock.cc \
    absl/base/internal/spinlock_wait.cc \
    absl/base/internal/strerror.cc \
    absl/base/internal/sysinfo.cc \
    absl/base/internal/thread_identity.cc \
    absl/base/internal/throw_delegate.cc \
    absl/base/internal/unscaledcycleclock.cc \
    absl/base/log_severity.cc \
    absl/container/internal/hashtablez_sampler.cc \
    absl/container/internal/raw_hash_set.cc \
    absl/debugging/failure_signal_handler.cc \
    absl/debugging/internal/address_is_readable.cc \
    absl/debugging/internal/demangle.cc \
    absl/debugging/internal/elf_mem_image.cc \
    absl/debugging/internal/examine_stack.cc \
    absl/debugging/internal/stack_consumption.cc \
    absl/debugging/internal/vdso_support.cc \
    absl/debugging/leak_check.cc \
    absl/debugging/leak_check_disable.cc \
    absl/debugging/stacktrace.cc \
    absl/debugging/symbolize.cc \
    absl/flags/commandlineflag.cc \
    absl/flags/flag.cc \
    absl/flags/internal/commandlineflag.cc \
    absl/flags/internal/flag.cc \
    absl/flags/internal/private_handle_accessor.cc \
    absl/flags/internal/program_name.cc \
    absl/flags/internal/usage.cc \
    absl/flags/marshalling.cc \
    absl/flags/parse.cc \
    absl/flags/reflection.cc \
    absl/flags/usage.cc \
    absl/flags/usage_config.cc \
    absl/hash/internal/city.cc \
    absl/hash/internal/hash.cc \
    absl/hash/internal/wyhash.cc \
    absl/numeric/int128.cc \
    absl/random/discrete_distribution.cc \
    absl/random/gaussian_distribution.cc \
    absl/random/internal/chi_square.cc \
    absl/random/internal/pool_urbg.cc \
    absl/random/internal/randen.cc \
    absl/random/internal/randen_detect.cc \
    absl/random/internal/randen_hwaes.cc \
    absl/random/internal/randen_round_keys.cc \
    absl/random/internal/randen_slow.cc \
    absl/random/internal/seed_material.cc \
    absl/random/seed_gen_exception.cc \
    absl/random/seed_sequences.cc \
    absl/status/status.cc \
    absl/status/statusor.cc \
    absl/status/status_payload_printer.cc \
    absl/strings/ascii.cc \
    absl/strings/charconv.cc \
    absl/strings/cord.cc \
    absl/strings/escaping.cc \
    absl/strings/internal/charconv_bigint.cc \
    absl/strings/internal/charconv_parse.cc \
    absl/strings/internal/cordz_functions.cc \
    absl/strings/internal/cordz_handle.cc \
    absl/strings/internal/cordz_info.cc \
    absl/strings/internal/cordz_sample_token.cc \
    absl/strings/internal/cord_internal.cc \
    absl/strings/internal/cord_rep_btree.cc \
    absl/strings/internal/cord_rep_btree_navigator.cc \
    absl/strings/internal/cord_rep_btree_reader.cc \
    absl/strings/internal/cord_rep_consume.cc \
    absl/strings/internal/cord_rep_ring.cc \
    absl/strings/internal/escaping.cc \
    absl/strings/internal/memutil.cc \
    absl/strings/internal/ostringstream.cc \
    absl/strings/internal/pow10_helper.cc \
    absl/strings/internal/str_format/arg.cc \
    absl/strings/internal/str_format/bind.cc \
    absl/strings/internal/str_format/extension.cc \
    absl/strings/internal/str_format/float_conversion.cc \
    absl/strings/internal/str_format/output.cc \
    absl/strings/internal/str_format/parser.cc \
    absl/strings/internal/utf8.cc \
    absl/strings/match.cc \
    absl/strings/numbers.cc \
    absl/strings/string_view.cc \
    absl/strings/str_cat.cc \
    absl/strings/str_replace.cc \
    absl/strings/str_split.cc \
    absl/strings/substitute.cc \
    absl/synchronization/barrier.cc \
    absl/synchronization/blocking_counter.cc \
    absl/synchronization/internal/create_thread_identity.cc \
    absl/synchronization/internal/graphcycles.cc \
    absl/synchronization/internal/per_thread_sem.cc \
    absl/synchronization/internal/waiter.cc \
    absl/synchronization/mutex.cc \
    absl/synchronization/notification.cc \
    absl/time/civil_time.cc \
    absl/time/clock.cc \
    absl/time/duration.cc \
    absl/time/format.cc \
    absl/time/internal/cctz/src/civil_time_detail.cc \
    absl/time/internal/cctz/src/time_zone_fixed.cc \
    absl/time/internal/cctz/src/time_zone_format.cc \
    absl/time/internal/cctz/src/time_zone_if.cc \
    absl/time/internal/cctz/src/time_zone_impl.cc \
    absl/time/internal/cctz/src/time_zone_info.cc \
    absl/time/internal/cctz/src/time_zone_libc.cc \
    absl/time/internal/cctz/src/time_zone_lookup.cc \
    absl/time/internal/cctz/src/time_zone_posix.cc \
    absl/time/internal/cctz/src/zone_info_source.cc \
    absl/time/time.cc \
    absl/types/bad_any_cast.cc \
    absl/types/bad_optional_access.cc \
    absl/types/bad_variant_access.cc


SOURCES := $(wildcard $(SOURCES))

HEADERS_INST := $(filter %.h,$(patsubst %,$(includedir)/%,$(HEADERS)))
HEADERS_INST += $(filter %.inc,$(patsubst %,$(includedir)/%,$(HEADERS)))
OBJECTS := $(patsubst %.cc,$(OBJ_DIR)/%.o,$(SOURCES))

CFLAGS ?= -O2
CFLAGS += -I. -std=c++17

.PHONY: install

all: $(OBJ_DIR)/$(LIB)

$(includedir)/%.h: %.h | $$(@D)/.
	$(QUIET_INSTALL)cp $< $@
	@chmod 0644 $@

$(includedir)/%.inc: %.inc | $$(@D)/.
	$(QUIET_INSTALL)cp $< $@
	@chmod 0644 $@

$(libdir)/%.a: $(OBJ_DIR)/%.a
	-@if [ ! -d $(libdir)  ]; then mkdir -p $(libdir); fi
	$(QUIET_INSTALL)cp $< $@
	@chmod 0644 $@

install: $(HEADERS_INST) $(libdir)/$(LIB)

clean:
	$(RM) -r $(OBJ_DIR)

distclean: clean
	$(RM) -r $(BUILD_DIR)

$(OBJ_DIR)/$(LIB): $(OBJECTS)
	$(QUIET_AR)$(AR) $(ARFLAGS) $@ $^
	$(QUIET_RANLIB)$(RANLIB) $@

$(OBJ_DIR)/%.o: %.cc $(OBJ_DIR)/.cflags | $$(@D)/.
	$(QUIET_CXX)$(CXX) $(CFLAGS) $(CXXFLAGS) -o $@ -c $<

.PRECIOUS: $(OBJ_DIR)/. $(OBJ_DIR)%/. $(includedir)/. $(includedir)%/.

$(OBJ_DIR)/.:
	$(QUIET)mkdir -p $@

$(OBJ_DIR)%/.:
	$(QUIET)mkdir -p $@

$(includedir)/.:
	$(QUIET)mkdir -p $@

$(includedir)%/.:
	$(QUIET)mkdir -p $@

TRACK_CFLAGS = $(subst ','\'',$(CXX) $(CFLAGS) $(CXXFLAGS))

$(OBJ_DIR)/.cflags: .force-cflags | $$(@D)/.
	@FLAGS='$(TRACK_CFLAGS)'; \
    if test x"$$FLAGS" != x"`cat $(OBJ_DIR)/.cflags 2>/dev/null`" ; then \
        echo "    * rebuilding abseil: new build flags or prefix"; \
        echo "$$FLAGS" > $(OBJ_DIR)/.cflags; \
    fi

.PHONY: .force-cflags
