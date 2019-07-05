VERSION_MAJOR	= 4
VERSION_MINOR	= 5
VERSION_RELEASE	= 0

VERSION		= $(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_RELEASE)

# This dylib will support anything linked against COMPAT_VERSION through VERSION
COMPAT_VERSION	= $(VERSION_MAJOR)

CC		= gcc
CFLAGS		= -c -g -O2 -Wall -fvisibility=hidden -DXMP_SYM_VISIBILITY -Wno-unused-but-set-variable -Wno-unused-result -Wno-array-bounds -DPACKAGE_NAME=\"\" -DPACKAGE_TARNAME=\"\" -DPACKAGE_VERSION=\"\" -DPACKAGE_STRING=\"\" -DPACKAGE_BUGREPORT=\"\" -DPACKAGE_URL=\"\" -DSTDC_HEADERS=1 -DHAVE_SYS_TYPES_H=1 -DHAVE_SYS_STAT_H=1 -DHAVE_STDLIB_H=1 -DHAVE_STRING_H=1 -DHAVE_MEMORY_H=1 -DHAVE_STRINGS_H=1 -DHAVE_INTTYPES_H=1 -DHAVE_STDINT_H=1 -DHAVE_UNISTD_H=1 -DHAVE_LIBM=1 -DHAVE_LOCALTIME_R=1 -DHAVE_ROUND=1 -DHAVE_POWF=1 -D_REENTRANT -DLIBXMP_CORE_PLAYER
CFLAGS_SHARED	= -fPIC
CFLAGS_STATIC	= -DBUILDING_STATIC
LD		= gcc
LDFLAGS		= 
LIBS		= -lm 
RANLIB		= ranlib
INSTALL		= /usr/bin/install -c
DESTDIR		=
prefix		= /usr/local
exec_prefix	= /usr/local
datarootdir	= ${prefix}/share
BINDIR		= ${exec_prefix}/bin
LIBDIR		= ${exec_prefix}/lib
MANDIR		= ${datarootdir}/man/man3
INCLUDEDIR	= ${prefix}/include/libxmp-lite
LD_VERSCRIPT	= -Wl,--version-script,libxmp.map
SHELL		= /bin/sh

DIST		= libxmp-lite-$(VERSION)
DFILES		= README INSTALL Changelog install-sh configure configure.ac \
		  config.sub config.guess Makefile.in libxmp-lite.pc.in \
		  Makefile.vc Makefile.os2 libxmp.map
DDIRS		= include src loaders os2 test
V		= 0
LIB		= libxmp-lite.a
SOLIB		= libxmp-lite.so
SHLIB		= $(SOLIB).$(VERSION)
SONAME		= $(SOLIB).$(VERSION_MAJOR)
DLL		= libxmp-lite.dll
IMPLIB		= libxmp-lite.dll.a
DYLIB		= libxmp-lite.$(VERSION_MAJOR).dylib
GCLIB		= libxmp-lite-gc.a
DYLIB_COMPAT	= -compatibility_version,$(COMPAT_VERSION),

DARWIN_VERSION	= 

# https://github.com/cmatsuoka/libxmp/issues/1
ifneq ($(DARWIN_VERSION),)
  ifeq ($(shell test $(DARWIN_VERSION) -lt 9 && echo true), true)
    DYLIB_COMPAT=
  endif
endif

all: static shared

include include/libxmp-lite/Makefile
include src/Makefile
include src/loaders/Makefile
include src/os2/Makefile
include test/Makefile

LOBJS = $(OBJS:.o=.lo)

GCOBJS = $(OBJS:.o=.gco)

CFLAGS += -Iinclude/libxmp-lite -Isrc

.SUFFIXES: .c .o .lo .a .so .dll .in .gco .gcda .gcno

.c.o:
	@CMD='$(CC) $(CPPFLAGS) $(CFLAGS_STATIC) $(CFLAGS) -o $*.o $<'; \
	if [ "$(V)" -gt 0 ]; then echo $$CMD; else echo CC $*.o ; fi; \
	eval $$CMD

.c.lo:
	@CMD='$(CC) $(CPPFLAGS) $(CFLAGS_SHARED) $(CFLAGS) -o $*.lo $<'; \
	if [ "$(V)" -gt 0 ]; then echo $$CMD; else echo CC $*.lo ; fi; \
	eval $$CMD

.c.gco:
	@CMD='$(CC) $(CPPFLAGS) $(CFLAGS_STATIC) $(CFLAGS) -O0 -fno-inline -fprofile-arcs -ftest-coverage -o $*.gco $<'; \
	if [ "$(V)" -gt 0 ]; then echo $$CMD; else echo CC $*.gco ; fi; \
	eval $$CMD

static: lib/$(LIB)

shared: lib/$(SHLIB)

coverage: lib/$(GCLIB)

dll: lib/$(DLL)

dylib: lib/$(DYLIB)

lib/$(LIB): $(OBJS)
	@mkdir -p lib
	@CMD='$(AR) r $@ $(OBJS)'; \
	if [ "$(V)" -gt 0 ]; then echo $$CMD; else echo AR $@ ; fi; \
	eval $$CMD
	$(RANLIB) $@

lib/$(SHLIB): $(LOBJS)
	@mkdir -p lib
	@CMD='$(LD) $(LDFLAGS) -shared -Wl,-soname,$(SONAME) $(LD_VERSCRIPT) -o $@ $(LOBJS) $(LIBS)'; \
	if [ "$(V)" -gt 0 ]; then echo $$CMD; else echo LD $@ ; fi; \
	eval $$CMD
	ln -sf $(SHLIB) lib/$(SONAME)
	ln -sf $(SONAME) lib/$(SOLIB)

lib/$(DLL): $(LOBJS)
	@mkdir -p lib
	@CMD='$(LD) $(LDFLAGS) -shared -Wl,--output-def,lib/libxmp-lite.def,--out-implib,lib/$(IMPLIB) -o $@ $(LOBJS) $(LIBS)'; \
	if [ "$(V)" -gt 0 ]; then echo $$CMD; else echo LD $@ ; fi; \
	eval $$CMD

# From http://stackoverflow.com/questions/15905310:
# The version number checks that dyld performs are limited to ensuring that
# the compatibility version of the library being loaded is higher than the
# compatibility version of the library that was used at build time.

lib/$(DYLIB): $(LOBJS)
	@mkdir -p lib
	@CMD='$(LD) $(LDFLAGS) -dynamiclib -Wl,-headerpad_max_install_names,-undefined,dynamic_lookup,$(DYLIB_COMPAT)-current_version,$(VERSION),-install_name,$(prefix)/lib/$(DYLIB) -o $@ $(LOBJS) $(LIBS)'; \
	if [ "$(V)" -gt 0 ]; then echo $$CMD; else echo LD $@ ; fi; \
	eval $$CMD
	ln -sf $(DYLIB) lib/libxmp-lite.dylib

lib/$(GCLIB): $(GCOBJS)
	@mkdir -p lib
	@CMD='$(AR) r $@ $(GCOBJS)'; \
	if [ "$(V)" -gt 0 ]; then echo $$CMD; else echo AR $@ ; fi; \
	eval $$CMD
	$(RANLIB) $@

clean:
	@rm -f $(OBJS) $(LOBJS) lib/lib*
	@rm -f $(GCOBJS) $(OBJS:.o=.gcno) $(OBJS:.o=.gcda)

install: all
	@mkdir -p $(DESTDIR)$(BINDIR) $(DESTDIR)$(LIBDIR) $(DESTDIR)$(INCLUDEDIR)
	@if [ -f lib/$(LIB) ]; then \
		echo "Installing $(LIB)..."; \
		$(INSTALL) -m644 lib/$(LIB) $(DESTDIR)$(LIBDIR); \
	fi
	@if [ -f lib/$(DYLIB) ]; then \
		echo "Installing $(DYLIB)..."; \
		$(INSTALL) -m755 lib/$(DYLIB) $(DESTDIR)$(LIBDIR); \
		ln -sf $(DYLIB) $(DESTDIR)$(LIBDIR)/libxmp-lite.dylib; \
	fi
	@if [ -f lib/$(DLL) ]; then \
		echo "Installing $(DLL)..."; \
		$(INSTALL) -m644 lib/$(DLL) $(DESTDIR)$(BINDIR); \
		$(INSTALL) -m644 lib/$(IMPLIB) $(DESTDIR)$(LIBDIR); \
	fi
	@if [ -f lib/$(SHLIB) ]; then \
		echo "Installing $(SHLIB)..."; \
		$(INSTALL) -m644 lib/$(SHLIB) $(DESTDIR)$(LIBDIR); \
		ln -sf $(SHLIB) $(DESTDIR)$(LIBDIR)/$(SONAME); \
		ln -sf $(SONAME) $(DESTDIR)$(LIBDIR)/$(SOLIB); \
	fi
	@echo "Installing xmp.h..."
	@$(INSTALL) -m644 include/libxmp-lite/xmp.h $(DESTDIR)$(INCLUDEDIR)
	@echo "Installing libxmp-lite.pc..."
	@mkdir -p $(DESTDIR)$(LIBDIR)/pkgconfig
	@$(INSTALL) -m644 libxmp-lite.pc $(DESTDIR)$(LIBDIR)/pkgconfig/

depend:
	@echo Building dependencies...
	@echo > $@
	@for i in $(OBJS) $(T_OBJS); do \
	    c="$${i%.o}.c"; l="$${i%.o}.lo"; \
	    $(CC) $(CFLAGS) -MM $$c | \
		sed "s!^.*\.o:!$$i $$l:!" >> $@ ; \
	done
	    
dist: version-prepare dist-prepare vc-prepare os2-prepare dist-jni dist-subdirs

dist-jni:
	mkdir $(DIST)/jni
	cp jni/Android.mk jni/Application.mk $(DIST)/jni

dist-prepare:
	./config.status
	rm -Rf $(DIST) $(DIST).tar.gz
	mkdir -p $(DIST)
	cp -RPp $(DFILES) $(DIST)/

vc-prepare:
	@echo Generate Makefile.vc
	@sed -e 's!@OBJS@!$(subst /,\\,$(OBJS:.o=.obj))!' Makefile.vc.in > Makefile.vc

os2-prepare:
	@echo Generate Makefile.os2
	@sed -e 's!@OBJS@!$(OBJS:.o=.obj)!' Makefile.os2.in > Makefile.os2

dist-subdirs: $(addprefix dist-,$(DDIRS))
	chmod -R u+w $(DIST)/*
	tar cvf - $(DIST) | gzip -9c > $(DIST).tar.gz
	rm -Rf $(DIST)
	ls -l $(DIST).tar.gz

distcheck:
	rm -Rf $(DIST)
	tar xf $(DIST).tar.gz
	(cd $(DIST); ./configure --enable-static --prefix=`pwd`/test-install; make; make check; make install; find test-install)


devcheck:
	$(MAKE) -C test-dev

covercheck: coverage
	$(MAKE) -C test-dev covercheck

coverclean:
	rm -f $(OBJS:.o=.gco) $(OBJS:.o=.gcno) $(OBJS:.o=.gcda)
	$(MAKE) -C test-dev coverclean

$(OBJS): Makefile

$(LOBJS): Makefile

version-prepare:
	sed -i -e '/^Version: /s/:.*/: $(VERSION)/g' libxmp-lite.pc.in
	vercode=`printf "0x%02x%02x%02x" $(VERSION_MAJOR) $(VERSION_MINOR) $(VERSION_RELEASE)`; \
	sed -i -e "s/\(^#define XMP_VERSION\).*/\1 \"$(VERSION)\"/;s/\(^#define XMP_VERCODE\).*/\1 $$vercode/;s/\(^#define XMP_VER_MAJOR\).*/\1 $(VERSION_MAJOR)/;s/\(^#define XMP_VER_MINOR\).*/\1 $(VERSION_MINOR)/;s/\(^#define XMP_VER_RELEASE\).*/\1 $(VERSION_RELEASE)/" include/libxmp-lite/xmp.h
	./config.status

sinclude depend
