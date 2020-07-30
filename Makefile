# Make Target:
# ------------
# The Makefile provides the following targets to make:
#   $ make           compile and link
#   $ make objs      compile only (no linking)
#   $ make docs      build documentation (requires doxygen)
#   $ make clean     clean objects and the executable file
#   $ make help      get the usage of the makefile


THISDIR := $(realpath .)

EXECUTABLE = test

UNAME    := $(shell uname)

CPPFLAGS =

LDFLAGS =   \
       -L /usr/local/lib \
       -L /usr/lib

ifeq ($(UNAME), Linux)
LDFLAGS +=  \
       -Wl,-rpath,/usr/local/lib

endif


LIBS =   \
     -lpapi

INCLUDES  += 

OBJDIR  = $(THISDIR)/obj
BINDIR  = $(THISDIR)/bin
SRCDIR  = $(THISDIR)/src
INCDIR  = $(THISDIR)/include

ifeq ($(shell uname), Linux)
BOOST_INCLUDE_PATH ?= /usr/include/boost
BOOST_LIBRARY_PATH ?= /usr/lib/x86_64-linux-gnu
else
BOOST_INCLUDE_PATH ?= /usr/local/opt/boost/include
BOOST_LIBRARY_PATH ?= /usr/local/opt/boost/lib
endif

## Implicit Section: change the following only when necessary.
CXX      = clang++ 
C14FLAGS = -std=c++14 
CXXFLAGS = -g -O2 -fPIC -Wall $(C14FLAGS) -static
SRCDIRS  = $(shell find $(SRCDIR) -type d)
INCFLAGS = -I $(INCDIR) -I $(SRCDIR)/proto $(INCLUDES)

## Stable Section: usually no need to be changed. 
SHELL   = /bin/sh
SOURCES = $(wildcard $(addsuffix /*.cc,$(SRCDIRS)))
OBJS    = $(patsubst $(SRCDIR)/%,$(OBJDIR)/%,$(SOURCES:.cc=.o))
DEPS    = $(OBJS:.o=.d)

## Define some useful variables.
CDP = clang++
DEP_OPT = -MM -MP
DEPEND  = $(CDP) $(CPPFLAGS) $(C14FLAGS) $(INCFLAGS) $(DEP_OPT)
COMPILE = $(CXX) $(CPPFLAGS) $(CXXFLAGS) $(INCFLAGS) 
LINK    = $(CXX) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS)
AR      = ar
ARFLAGS = cvq
ARCHIVE = $(AR) $(ARFLAGS)

## Define variables for use with proto
PROTO            = protoc
PROTO_GENDIR     = $(SRCDIR)/proto
PROTO_GENTMPDIR  = $(SRCDIR)/proto_tmp
PROTO_DIR        = $(THISDIR)/proto
PROTO_FLAGS      = --proto_path=$(PROTO_DIR) --cpp_out=$(PROTO_GENTMPDIR)
PROTO_SRCDIRS    = $(shell find $(PROTO_DIR) -type d 2>/dev/null)
PROTO_SOURCES    = $(wildcard $(addsuffix /*.proto,$(PROTO_SRCDIRS)))
PROTO_GENERATE   = $(PROTO) $(PROTO_FLAGS)

.PHONY: all objs clean distclean help show

# Delete the default suffixes
.SUFFIXES:

$(OBJDIR)/%.d: $(SRCDIR)/%.cc 
	@mkdir -p $(dir $@)
	@/bin/echo -n $(dir $@) > $@
	@$(DEPEND) $< >> $@ 2>/dev/null || rm $@

all: $(BINDIR)/$(EXECUTABLE)

$(BINDIR)/$(EXECUTABLE): $(OBJS)
	@echo "Building $@"
	@mkdir -p $(dir $@)
	@$(LINK) $(OBJS) $(LIBS) -o "$@"

objs: $(OBJS) 

$(OBJDIR)/%.o: $(SRCDIR)/%.cc
	@echo "Compiling $@"
	@$(COMPILE) -c $< -o $@

gen: $(PROTO_SOURCES)
	@mkdir -p $(PROTO_GENDIR)
	@mkdir -p $(PROTO_GENTMPDIR)
	@for file in $^; do $(PROTO_GENERATE) $$file; done
	@$(RM) -f $$(find $(PROTO_GENTMPDIR) -name "*.skeleton.cc")
	@rsync -r -c -q $(PROTO_GENTMPDIR)/* $(PROTO_GENDIR)
	@$(RM) -fr $(PROTO_GENTMPDIR)

docs:
	@doxygen doc/doxy.conf

ifneq ($(DEPS),)
  sinclude $(DEPS)
endif

clean:
	@$(RM) -r $(OBJDIR) $(BINDIR)
	@$(RM) -r docs/html
	@$(RM) -r $(PROTO_GENDIR)

help:
	@echo 'Usage: make [TARGET]'
	@echo 'TARGETS:'
	@echo '  all       (=make) compile and link.'
	@echo '  objs      compile only (no linking).'
	@echo '  tags      create tags for Emacs editor.'
	@echo '  clean     clean objects and the executable file.'
	@echo '  show      show variables (for debug use only).'
	@echo '  help      print this message.'

show:
	@echo 'THISDIR     :' $(THISDIR)
	@echo 'LIBRARY     :' $(LIBRARY)
	@echo 'SRCDIRS     :' $(SRCDIRS)
	@echo 'SOURCES     :' $(SOURCES)
	@echo 'OBJS        :' $(OBJS)
	@echo 'DEPS        :' $(DEPS)
	@echo 'DEPEND      :' $(DEPEND)
	@echo 'COMPILE     :' $(COMPILE)
	@echo 'link        :' $(LINK)



