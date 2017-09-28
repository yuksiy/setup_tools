# System Configuration
srcdir = .

prefix ?= /usr/local
exec_prefix ?= $(prefix)

scriptbindir ?= $(prefix)/bin
datadir ?= $(scriptbindir)
datarootdir ?= $(prefix)/share

bindir ?= $(exec_prefix)/bin
libdir ?= $(exec_prefix)/lib
sbindir ?= $(exec_prefix)/sbin

sysconfdir ?= $(prefix)/etc
docdir ?= $(datarootdir)/doc/$(PROJ)
infodir ?= $(datarootdir)/info
mandir ?= $(datarootdir)/man
localstatedir ?= $(prefix)/var

CHECK_SCRIPT_SH = /bin/sh -n

INSTALL = /usr/bin/install -p
INSTALL_PROGRAM = $(INSTALL)
INSTALL_SCRIPT = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644


# Inference Rules

# Macro Defines
PROJ = setup_tools
VER = 1.0.0
TAG = v$(VER)

TAR_SORT_KEY ?= 6,6

SUBDIRS-TEST-SCRIPTS-SH = \

SUBDIRS-TEST = \
				$(SUBDIRS-TEST-SCRIPTS-SH) \

SUBDIRS = \
				$(SUBDIRS-TEST) \

PROGRAMS = \

SCRIPTS-SH = \
				setup_common_function.sh \
				setup_fil.sh \
				setup_fil_list.sh \
				setup_fil_list_function.sh \
				setup_pkg_list.sh \
				setup_pkg_list_function.sh \

SCRIPTS-OTHER = \

SCRIPTS = \
				$(SCRIPTS-SH) \
				$(SCRIPTS-OTHER) \

DATA = \

DOC = \
				LICENSE \
				README.md \
				README_file_list.md \
				README_pkg_list.md \
				examples/README.md \
				examples/dot.setup_fil.DebianX.X.conf \
				examples/dot.setup_fil.FedoraXX.conf \
				examples/dot.setup_fil_list.DebianX.X.conf \
				examples/dot.setup_fil_list.FedoraXX.conf \
				examples/dot.setup_pkg_list.conf \
				examples/file_list_remote.ods \
				examples/file_list_remote.txt \
				examples/pkg_list_remote.ods \
				examples/pkg_list_remote.txt \

# Target List
test-recursive \
:
	@target=`echo $@ | sed s/-recursive//`; \
	list='$(SUBDIRS-TEST)'; \
	for subdir in $$list; do \
		echo "Making $$target in $$subdir"; \
		echo " (cd $$subdir && $(MAKE) $$target)"; \
		(cd $$subdir && $(MAKE) $$target); \
	done

all: \
				$(PROGRAMS) \
				$(SCRIPTS) \
				$(DATA) \

# Check
check: check-SCRIPTS-SH

check-SCRIPTS-SH:
	@list='$(SCRIPTS-SH)'; \
	for i in $$list; do \
		echo " $(CHECK_SCRIPT_SH) $$i"; \
		$(CHECK_SCRIPT_SH) $$i; \
	done

# Test
test:
	$(MAKE) test-recursive

# Install
install: install-SCRIPTS install-DATA install-DOC

install-SCRIPTS:
	@list='$(SCRIPTS)'; \
	for i in $$list; do \
		dir="`dirname \"$(DESTDIR)$(scriptbindir)/$$i\"`"; \
		if [ ! -d "$$dir/" ]; then \
			echo " mkdir -p $$dir/"; \
			mkdir -p $$dir/; \
		fi;\
		echo " $(INSTALL_SCRIPT) $$i $(DESTDIR)$(scriptbindir)/$$i"; \
		$(INSTALL_SCRIPT) $$i $(DESTDIR)$(scriptbindir)/$$i; \
	done

install-DATA:
	@list='$(DATA)'; \
	for i in $$list; do \
		dir="`dirname \"$(DESTDIR)$(datadir)/$$i\"`"; \
		if [ ! -d "$$dir/" ]; then \
			echo " mkdir -p $$dir/"; \
			mkdir -p $$dir/; \
		fi;\
		echo " $(INSTALL_DATA) $$i $(DESTDIR)$(datadir)/$$i"; \
		$(INSTALL_DATA) $$i $(DESTDIR)$(datadir)/$$i; \
	done

install-DOC:
	@list='$(DOC)'; \
	for i in $$list; do \
		dir="`dirname \"$(DESTDIR)$(docdir)/$$i\"`"; \
		if [ ! -d "$$dir/" ]; then \
			echo " mkdir -p $$dir/"; \
			mkdir -p $$dir/; \
		fi;\
		echo " $(INSTALL_DATA) $$i $(DESTDIR)$(docdir)/$$i"; \
		$(INSTALL_DATA) $$i $(DESTDIR)$(docdir)/$$i; \
	done

# Pkg
pkg:
	@$(MAKE) DESTDIR=$(CURDIR)/$(PROJ)-$(VER).$(ENVTYPE) install; \
	tar cvf ./$(PROJ)-$(VER).$(ENVTYPE).tar ./$(PROJ)-$(VER).$(ENVTYPE) > /dev/null; \
	tar tvf ./$(PROJ)-$(VER).$(ENVTYPE).tar 2>&1 | sort -k $(TAR_SORT_KEY) | tee ./$(PROJ)-$(VER).$(ENVTYPE).tar.list.txt; \
	gzip -f ./$(PROJ)-$(VER).$(ENVTYPE).tar; \
	rm -fr ./$(PROJ)-$(VER).$(ENVTYPE)

# Dist
dist:
	@git archive --format=tar --prefix=$(PROJ)-$(VER)/ $(TAG) > ../$(PROJ)-$(VER).tar; \
	tar tvf ../$(PROJ)-$(VER).tar 2>&1 | sort -k $(TAR_SORT_KEY) | tee ../$(PROJ)-$(VER).tar.list.txt; \
	gzip -f ../$(PROJ)-$(VER).tar
