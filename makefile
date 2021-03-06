# SGS-SDL makefile


include sgscript/core.mk


# SGS-SDL FLAGS
ifneq ($(target_os),windows)
	video=nod3d
	SDL2_CFLAGS = $(shell sdl2-config --cflags)
	SDL2_LIBS = $(shell sdl2-config --libs)
	XGM_LIBS = sgscript/bin/sgsxgmath.so
	ifneq ($(shell uname -s),Darwin)
		LINUXHACKPRE = -ln -s sgscript/bin/sgsxgmath.so sgsxgmath.so
		LINUXHACKPOST = -unlink sgsxgmath.so
	endif
else
	SDL2_CFLAGS = -Iext/include/SDL2
	SDL2_LIBS = -lSDL2main -lSDL2
	XGM_LIBS = -lsgsxgmath
endif

SGS_SDL_INSTALL_TOOL = $(call fnIF_OS,osx,install_name_tool \
	-change $(OUTDIR)/libsgs-sdl.so @rpath/libsgs-sdl.so $1,)

SS_OUTFILE=$(OUTDIR)/$(LIBPFX)sgs-sdl$(LIBEXT)
SS_OUTFLAGS=-L$(OUTDIR) -lsgs-sdl
CFLAGS=-Wall -Wshadow -Wpointer-arith -Wcast-align \
	$(call fnIF_RELEASE,-O3,-D_DEBUG -g) $(call fnIF_COMPILER gcc,-static-libgcc,) \
	$(call fnIF_ARCH,x86,-m32,$(call fnIF_ARCH,x64,-m64,)) -Isrc \
	$(call fnIF_OS,windows,,-fPIC -D_FILE_OFFSET_BITS=64) \
	$(call fnIF_OS,android,-DSGS_PF_ANDROID,)
SS_CFLAGS=$(CFLAGS) -Isgscript/src -Isgscript/ext $(SDL2_CFLAGS) $(FT2_CFLAGS) -Iext/include/freetype -Wno-comment
BINFLAGS=$(CFLAGS) $(OUTFLAGS) -lm \
	$(call fnIF_OS,android,-ldl -Wl$(comma)-rpath$(comma)'$$ORIGIN' -Wl$(comma)-z$(comma)origin,) \
	$(call fnIF_OS,windows,-lkernel32,) \
	$(call fnIF_OS,osx,-framework OpenGL -ldl -Wl$(comma)-rpath$(comma)'@executable_path/.',) \
	$(call fnIF_OS,linux,-ldl -lrt -Wl$(comma)-rpath$(comma)'$$ORIGIN' -Wl$(comma)-z$(comma)origin,)
MODULEFLAGS=$(BINFLAGS) -shared
EXEFLAGS=$(BINFLAGS)

_DEPS = ss_main.h ss_cfg.h
_OBJ = ss_main.o ss_script.o ss_sdl.o ss_render.o ss_image.o ss_render_gl.o

_SS3D_DEPS = ss3d_engine.h lodepng.h dds.h
_SS3D_OBJ = ss3d_engine.o ss3d_render_gl.o lodepng.o dds.o

ifneq ($(video),nod3d)
	SS_CFLAGS += -DSGS_SDL_HAS_DIRECT3D
	MODULEFLAGS += -Ld3dx -ld3dx9
	_OBJ += ss_render_d3d9.o
	_SS3D_OBJ += ss3d_render_d3d9.o
endif

DEPS = $(patsubst %,src/%,$(_DEPS))
OBJ = $(patsubst %,obj/%,$(_OBJ))

SS3D_DEPS = $(patsubst %,src/%,$(_SS3D_DEPS))
SS3D_OBJ = $(patsubst %,obj/%,$(_SS3D_OBJ))

ifeq ($(target_os),windows)
	PF_LINK = -Lext/lib-win32 -lOpenGL32 obj/libjpg.a obj/libpng.a obj/zlib.a obj/freetype.a
	PF_POST = $(fnCOPY_FILE) $(call fnFIX_PATH,ext/bin-win32/SDL2.dll bin) & \
	           $(fnCOPY_FILE) $(call fnFIX_PATH,sgscript/bin/sgscript.dll bin) & \
	           $(fnCOPY_FILE) $(call fnFIX_PATH,sgscript/bin/sgsxgmath.dll bin)
else
	PF_LINK = $(OUTDIR)/$(LIBPFX)jpg$(LIBEXT) \
				$(OUTDIR)/$(LIBPFX)png$(LIBEXT) \
				$(OUTDIR)/$(LIBPFX)zlib$(LIBEXT) \
				$(OUTDIR)/$(LIBPFX)freetype$(LIBEXT)
	PF_POST = $(call fnIF_OS,osx,$(fnCOPY_FILE) /usr/local/lib/libSDL2.dylib bin &,) \
				$(fnCOPY_FILE) sgscript/bin/libsgscript.so bin & \
				$(fnCOPY_FILE) sgscript/bin/sgsxgmath.so bin
endif

SGS_SDL_FLAGS = $(SS_CFLAGS) $(MODULEFLAGS) $(PF_LINK) -Lsgscript/bin $(SDL2_LIBS) $(FT2_LIBS) -lsgscript $(XGM_LIBS) $(PF_DEPS)
SGS_SDL_LAUNCHER_FLAGS = $(SS_CFLAGS) $(BINFLAGS) -L$(OUTDIR) -lsgs-sdl

SGS_CXX_FLAGS = -fno-exceptions -fno-rtti -static-libstdc++ -static-libgcc -fno-unwind-tables -fvisibility=hidden


# BUILD INFO
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),clean_obj)
ifneq ($(MAKECMDGOALS),clean_objbin)
$(info -------------------)
$(info SGS-SDL build info )
$(info -------------------)
$(info OS - $(cOS))
$(info ARCH - $(cARCH))
$(info COMPILER - $(cCOMPILER))
$(info TARGET - $(target_os)/$(target_arch))
$(info MODE - $(call fnIF_RELEASE,release,debug))
$(info OUT.LIB. - $(OUTFILE))
$(info TODO - $(MAKECMDGOALS))
$(info -------------------)
endif
endif
endif


# TARGETS
## the library (default target)
.PHONY: tools make launchers ss3d ss3dcull sgs-sdl box2d bullet

tools: launchers box2d bullet
make: tools
launchers: $(OUTDIR)/sgs-sdl-release$(BINEXT) $(OUTDIR)/sgs-sdl-debug$(BINEXT)
sgs-sdl: $(OUTDIR)/$(LIBPFX)sgs-sdl$(LIBEXT)
ss3d: $(OUTDIR)/$(LIBPFX)ss3d$(LIBEXT)
ss3dcull: $(OUTDIR)/$(LIBPFX)ss3dcull$(LIBEXT)
box2d: $(OUTDIR)/sgsbox2d$(LIBEXT)
bullet: $(OUTDIR)/sgsbullet$(LIBEXT)


# SGScript
sgscript/bin/sgsvm$(BINEXT):
	$(MAKE) -C sgscript vm
sgscript/bin/sgsxgmath$(LIBEXT):
	$(MAKE) -C sgscript xgmath
sgscript/bin/sgstest$(BINEXT):
	$(MAKE) -C sgscript build_test

# INPUT LIBRARIES
.PHONY: sgs-sdl-deps
ifeq ($(target_os),windows)
SGS_SDL_DEPS = obj/libjpg.a obj/libpng.a obj/zlib.a obj/freetype.a
obj/libjpg.a:
	$(CC) -o obj/libjpg1.o -c $(CFLAGS) ext/src/libjpg1.c
	$(CC) -o obj/libjpg2.o -c $(CFLAGS) ext/src/libjpg2.c
	$(CC) -o obj/libjpg3.o -c $(CFLAGS) ext/src/libjpg3.c
	ar -rcs obj/libjpg.a obj/libjpg1.o obj/libjpg2.o obj/libjpg3.o
obj/zlib.a:
	$(CC) -o obj/zlib1.o -c $(CFLAGS) ext/src/zlib1.c
	$(CC) -o obj/zlib2.o -c $(CFLAGS) ext/src/zlib2.c
	$(CC) -o obj/zlib3.o -c $(CFLAGS) ext/src/zlib3.c
	ar -rcs obj/zlib.a obj/zlib1.o obj/zlib2.o obj/zlib3.o
obj/libpng.a:
	$(CC) -o obj/libpng1.o -c $(CFLAGS) ext/src/libpng1.c -Iext/src/zlib
	ar -rcs obj/libpng.a obj/libpng1.o
obj/freetype.a:
	$(CC) -o obj/freetype1.o -c $(CFLAGS) ext/src/freetype1.c -Iext/include/freetype
	ar -rcs obj/freetype.a obj/freetype1.o
else
SGS_SDL_DEPS = $(OUTDIR)/$(LIBPFX)jpg$(LIBEXT) $(OUTDIR)/$(LIBPFX)zlib$(LIBEXT) $(OUTDIR)/$(LIBPFX)png$(LIBEXT) $(OUTDIR)/$(LIBPFX)freetype$(LIBEXT)
$(OUTDIR)/$(LIBPFX)jpg$(LIBEXT):
	$(CC) -o $@ $(CFLAGS) -shared ext/src/libjpg1.c ext/src/libjpg2.c ext/src/libjpg3.c
$(OUTDIR)/$(LIBPFX)zlib$(LIBEXT):
	$(CC) -o $@ $(CFLAGS) -shared ext/src/zlib1.c ext/src/zlib2.c ext/src/zlib3.c
$(OUTDIR)/$(LIBPFX)png$(LIBEXT): $(OUTDIR)/$(LIBPFX)zlib$(LIBEXT)
	$(CC) -o $@ $(CFLAGS) -shared ext/src/libpng1.c -Iext/src/zlib $^
	$(call fnIF_OS,osx,install_name_tool -change $(OUTDIR)/libzlib.so @rpath/libzlib.so $@,)
$(OUTDIR)/$(LIBPFX)freetype$(LIBEXT):
	$(CC) -o $@ $(CFLAGS) -shared ext/src/freetype1.c -Iext/include/freetype
endif
# - Box2D
obj/libbox2d.a:
	$(CXX) -o obj/libbox2d.o -c $(CFLAGS) $(SGS_CXX_FLAGS) -Wno-shadow ext/src/box2d1.cpp -Iext/src/box2d/Box2D
	ar -rcs $@ obj/libbox2d.o
# - Bullet
_BLTOBJ = bullet_LinearMath.o bullet_BulletCollision.o bullet_BulletDynamics.o
BLTOBJ = $(patsubst %,obj/%,$(_BLTOBJ))
obj/bullet_%.o: ext/src/bullet_%.cpp
	$(CXX) -o $@ -c $(CFLAGS) $(SGS_CXX_FLAGS) -Iext/src/bullet/src -Wno-unused-variable $<
obj/libbullet.a: $(BLTOBJ)
	ar -rcs $@ $^
obj/bullet_%.o: ext/src/bullet_%.cpp $(DEPS)


# MAIN LIBRARIES
$(OUTDIR)/sgs-sdl-release$(BINEXT): $(OUTDIR)/$(LIBPFX)sgs-sdl$(LIBEXT) src/ss_launcher.c
	$(LINUXHACKPRE)
	$(CC) -o $@ src/ss_launcher.c $(call fnIF_OS,windows,-mwindows,) $(SGS_SDL_LAUNCHER_FLAGS) -DSS_RELEASE -s
	$(LINUXHACKPOST)
	$(call SGS_SDL_INSTALL_TOOL,$@)
$(OUTDIR)/sgs-sdl-debug$(BINEXT): $(OUTDIR)/$(LIBPFX)sgs-sdl$(LIBEXT) src/ss_launcher.c
	$(LINUXHACKPRE)
	$(CC) -o $@ src/ss_launcher.c $(SGS_SDL_LAUNCHER_FLAGS) -s
	$(LINUXHACKPOST)
	$(call SGS_SDL_INSTALL_TOOL,$@)

$(OUTDIR)/$(LIBPFX)sgs-sdl$(LIBEXT): $(OBJ) $(SGS_SDL_DEPS) sgscript/bin/sgsxgmath$(LIBEXT)
	$(LINUXHACKPRE)
	$(CC) -o $@ $(OBJ) $(SGS_SDL_FLAGS)
	$(LINUXHACKPOST)
	$(PF_POST)
	$(call fnIF_OS,osx,install_name_tool -change $(OUTDIR)/libjpg.so @rpath/libjpg.so $@,)
	$(call fnIF_OS,osx,install_name_tool -change $(OUTDIR)/libpng.so @rpath/libpng.so $@,)
	$(call fnIF_OS,osx,install_name_tool -change $(OUTDIR)/libzlib.so @rpath/libzlib.so $@,)
	$(call fnIF_OS,osx,install_name_tool -change $(OUTDIR)/libfreetype.so @rpath/libfreetype.so $@,)
	$(call fnIF_OS,osx,install_name_tool -change $(OUTDIR)/libsgscript.so @rpath/libsgscript.so $@,)
	$(call fnIF_OS,osx,install_name_tool -change $(OUTDIR)/sgsxgmath.so @rpath/sgsxgmath.so $@,)

$(OUTDIR)/ss3d$(LIBEXT): $(SS3D_OBJ) $(OUTDIR)/$(LIBPFX)sgs-sdl$(LIBEXT) sgscript/bin/sgsxgmath$(LIBEXT)
	$(LINUXHACKPRE)
	$(CC) -o $@ $(SS3D_OBJ) $(SGS_SDL_FLAGS)
	$(LINUXHACKPOST)
	$(PF_POST)

$(OUTDIR)/ss3dcull$(LIBEXT): src/ss3dcull.cpp src/ss3dcull.hpp src/cppbc_ss3dcull.cpp $(OUTDIR)/ss3d$(LIBEXT) sgscript/bin/sgsxgmath$(LIBEXT)
	$(LINUXHACKPRE)
	$(CXX) -o $@ src/ss3dcull.cpp src/cppbc_ss3dcull.cpp $(SGS_SDL_FLAGS) -msse2 $(SGS_CXX_FLAGS) -I. $(OUTDIR)/ss3d$(LIBEXT)
	$(LINUXHACKPOST)

$(OUTDIR)/sgsbox2d$(LIBEXT): src/box2d.cpp src/box2d.hpp src/cppbc_box2d.cpp sgscript/bin/sgsxgmath$(LIBEXT) obj/libbox2d.a
	$(LINUXHACKPRE)
	$(CXX) -o $@ src/box2d.cpp src/cppbc_box2d.cpp $(SGS_SDL_FLAGS) $(SGS_CXX_FLAGS) -Wno-shadow -Iext/src/box2d/Box2D -Lobj -lbox2d
	$(LINUXHACKPOST)

$(OUTDIR)/sgsbullet$(LIBEXT): src/bullet.cpp src/bullet.hpp src/cppbc_bullet.cpp $(OUTDIR)/$(LIBPFX)sgscript$(LIBEXT) $(OUTDIR)/sgsxgmath$(LIBEXT) obj/libbullet.a
	$(LINUXHACKPRE)
	$(CXX) -o $@ src/bullet.cpp src/cppbc_bullet.cpp $(SGS_SDL_FLAGS) $(SGS_CXX_FLAGS) -Iext/src/bullet/src -Lobj -lbullet -Wno-unused-variable
	$(LINUXHACKPOST)

obj/ss_%.o: src/ss_%.c $(DEPS)
	$(CC) -c -o $@ $< $(SS_CFLAGS)

obj/ss3d_%.o: src/ss3d_%.c $(SS3D_DEPS)
	$(CC) -c -o $@ $< $(SS_CFLAGS)
obj/lodepng.o: src/lodepng.c src/lodepng.h
	$(CC) -c -o $@ $< $(SS_CFLAGS)
obj/dds.o: src/dds.c src/dds.h
	$(CC) -c -o $@ $< $(SS_CFLAGS)

src/cppbc_ss3dcull.cpp: src/ss3dcull.hpp sgscript/bin/sgsvm$(BINEXT)
	sgscript/bin/sgsvm -p sgscript/ext/cppbc.sgs src/ss3dcull.hpp -o $@ -iname ss3dcull.hpp
src/cppbc_box2d.cpp: src/box2d.hpp sgscript/bin/sgsvm$(BINEXT)
	sgscript/bin/sgsvm -p sgscript/ext/cppbc.sgs src/box2d.hpp -o $@ -iname box2d.hpp
src/cppbc_bullet.cpp: src/bullet.hpp sgscript/bin/sgsvm$(BINEXT)
	sgscript/bin/sgsvm -p sgscript/ext/cppbc.sgs src/bullet.hpp -o $@ -iname bullet.hpp

# UTILITY TARGETS
.PHONY: clean clean_deps clean_all, test, binarch
clean:
	-$(fnREMOVE_ALL) $(call fnFIX_PATH,obj/ss*.o bin/sgs*)
clean_deps:
	-$(fnREMOVE_ALL) $(call fnFIX_PATH,obj/*lib*.o bin/*.dylib bin/*.so bin/*.so.dSYM obj/*lib*.a obj/freetype*.o obj/freetype*.a)
clean_all: clean clean_deps
	$(MAKE) -C sgscript clean
test: sgscript/bin/sgstest$(BINEXT) $(OUTDIR)/sgsbox2d$(LIBEXT) $(OUTDIR)/sgsbullet$(LIBEXT)
	sgscript/bin/sgstest
binarch: sgscript/bin/sgsvm$(BINEXT)
	sgsvm build/prep.sgs



#
#
#
#
# DISABLES THE REST OF THE FILE
ifeq (0,1)
#
#
#
#





CC=gcc



ifeq ($(shell uname -s),Darwin)


# UTILITIES
ifdef SystemRoot
	fnREMOVE_ALL = del /S /Q
	fnCOPY_FILE = copy
	fnFIX_PATH = $(subst /,\,$1)
	cDEFAULT_PLATFORM=win-x86
	cOS=win
else
	fnREMOVE_ALL = rm -rf
	fnCOPY_FILE = cp
	fnFIX_PATH = $1
	ifeq ($(shell uname -s),Darwin)
		cDEFAULT_PLATFORM=osx-x64
		cOS=osx
	else
		cDEFAULT_PLATFORM=linux-x64
		cOS=linux
	endif
endif


# APP FLAGS
CFLAGS = -D_DEBUG -g -Wall -Wno-comment -DBUILDING_SGS_SDL
COMPATHS = -I/usr/local/opt/freetype/include/freetype2 -Isgscript/src -Isgscript/ext
LIBFLAGS = -Wl,-rpath,'@executable_path/.' -Lbin -lsgs-sdl
SS_LIB_OBJ = $(patsubst %,obj/ss_%.o,main script sdl render image render_gl)
SS_LIB_FLAGS = $(SS_LIB_OBJ) $(CFLAGS) -framework OpenGL -lfreetype -lm \
	-Wl,-rpath,'@executable_path/.' sgscript/bin/sgsxgmath.so \
	-lfreeimage -shared -lSDL2main -lSDL2 -Lsgscript/bin -lsgscript
SS_LAUNCHER_FLAGS = src/ss_launcher.c $(COMPATHS) $(LIBFLAGS) $(CFLAGS)
SS_INSTALL_TOOL = install_name_tool \
	-change bin/libsgs-sdl.so @rpath/libsgs-sdl.so \
	-change bin/sgsxgmath.so @rpath/sgsxgmath.so \
	-change bin/libsgscript.so @rpath/libsgscript.so


# TARGETS
.PHONY: bothlaunchers
bothlaunchers: bin/sgs-sdl-release bin/sgs-sdl-debug

bin/sgs-sdl-release: bin/libsgs-sdl.so src/ss_launcher.c
	$(CC) -o $@ $(SS_LAUNCHER_FLAGS) -DSS_RELEASE
	$(SS_INSTALL_TOOL) $@

bin/sgs-sdl-debug: bin/libsgs-sdl.so src/ss_launcher.c
	$(CC) -o $@ $(SS_LAUNCHER_FLAGS)
	$(SS_INSTALL_TOOL) $@

bin/libsgs-sdl.so: $(SS_LIB_OBJ)
	$(MAKE) -C sgscript xgmath
	$(CC) -o $@ $(SS_LIB_FLAGS)
	$(SS_INSTALL_TOOL) $@
	$(fnCOPY_FILE) $(call fnFIX_PATH,sgscript/bin/libsgscript.so bin)
	$(fnCOPY_FILE) $(call fnFIX_PATH,sgscript/bin/sgsxgmath.so bin)
	$(SS_INSTALL_TOOL) bin/sgsxgmath.so

obj/ss_%.o: src/ss_%.c src/ss_main.h src/ss_cfg.h
	$(CC) -c -o $@ $< $(COMPATHS) $(CFLAGS)

.PHONY: clean
clean:
	$(fnREMOVE_ALL) $(call fnFIX_PATH,obj/*.o bin/sgs*)

.PHONY: clean_all
clean_all: clean
	$(MAKE) -C sgscript clean



else


SRCDIR=src
LIBDIR=lib
EXTDIR=ext
OUTDIR=bin
OBJDIR=obj



ifdef SystemRoot
	RM = del /Q
	CP = copy
	FixPath = $(subst /,\,$1)
	WinOnly = $1
	LIBFLAGS =  -Lbin -lsgs-sdl
	PLATFLAGS = -lkernel32 -lOpenGL32 -ld3d9 -lmingw32 -lfreetype-6 -lsgsxgmath
	LINKPATHS = -Lsdl-win/lib -Lfreeimage -Lfreetype
	COMPATHS = -Isdl-win/include -Ifreetype/include
	LINUXHACKPRE =
	LINUXHACKPOST =
	PLATPOST = $(CP) $(call FixPath,sdl-win/bin/SDL2.dll bin) & \
	           $(CP) $(call FixPath,freeimage/FreeImage.dll bin) & \
	           $(CP) $(call FixPath,freetype/libfreetype-6.dll bin) & \
	           $(CP) $(call FixPath,sgscript/bin/sgscript.dll bin) & \
	           $(CP) $(call FixPath,sgscript/bin/sgsxgmath.dll bin)
	BINEXT=.exe
	LIBPFX=
	LIBEXT=.dll
else
	RM = rm -rf
	CP = cp
	FixPath = $1
	WinOnly =
	LINKPATHS = 
	ifeq ($(shell uname -s),Darwin)
		COMPATHS = -I/usr/local/opt/freetype/include/freetype2
		PLATFLAGS = -framework OpenGL -lfreetype -lm -Wl,-rpath,'@executable_path/.' sgsxgmath.so
		LIBFLAGS = -Wl,-rpath,'@executable_path/.' -L. -lsgs-sdl
		LINUXHACKPRE = -ln -s sgscript/bin/sgsxgmath.so sgsxgmath.so && ln -s bin/libsgs-sdl.so libsgs-sdl.so
		LINUXHACKPOST = -unlink sgsxgmath.so && unlink libsgs-sdl.so
	else
		COMPATHS = -I/usr/include/freetype2
		PLATFLAGS = -lGL -lfreetype -lm -Wl,-rpath,'$$ORIGIN' -Wl,-z,origin -l:sgsxgmath.so
		LIBFLAGS = -Wl,-rpath,'$$ORIGIN' -Wl,-z,origin -Wl,-rpath-link,bin -Lbin -lsgs-sdl
		LINUXHACKPRE = -ln -s sgscript/bin/sgsxgmath.so sgsxgmath.so
		LINUXHACKPOST = -unlink sgsxgmath.so
	endif
	PLATPOST = $(CP) $(call FixPath,sgscript/bin/libsgscript.so bin) & \
	           $(CP) $(call FixPath,sgscript/bin/sgsxgmath.so bin)
	BINEXT=
	LIBPFX=lib
	LIBEXT=.so
	video=nod3d
endif

ifeq ($(arch),64)
	ARCHFLAGS= -m64
else
	ifeq ($(arch),32)
		ARCHFLAGS= -m32
	else
		ARCHFLAGS=
	endif
endif

ifeq ($(mode),release)
	CFLAGS = -O3 -Wall $(ARCHFLAGS)
else
	mode = debug
	CFLAGS = -D_DEBUG -g -Wall $(ARCHFLAGS)
endif

_DEPS = ss_main.h ss_cfg.h
_OBJ = ss_main.o ss_script.o ss_sdl.o ss_render.o ss_image.o ss_render_gl.o

_SS3D_DEPS = ss3d_engine.h lodepng.h dds.h
_SS3D_OBJ = ss3d_engine.o ss3d_render_gl.o lodepng.o dds.o

ifneq ($(video),nod3d)
	VIDEOFLAGS = -DSGS_SDL_HAS_DIRECT3D -Ld3dx -ld3dx9
	_OBJ += ss_render_d3d9.o
	_SS3D_OBJ += ss3d_render_d3d9.o
endif

C2FLAGS = $(CFLAGS) $(VIDEOFLAGS) -DBUILDING_SGS_SDL


DEPS = $(patsubst %,$(SRCDIR)/%,$(_DEPS))
OBJ = $(patsubst %,$(OBJDIR)/%,$(_OBJ))
SS3D_DEPS = $(patsubst %,$(SRCDIR)/%,$(_SS3D_DEPS))
SS3D_OBJ = $(patsubst %,$(OBJDIR)/%,$(_SS3D_OBJ))

.PHONY: bothlaunchers
bothlaunchers: $(OUTDIR)/sgs-sdl-release$(BINEXT) $(OUTDIR)/sgs-sdl-debug$(BINEXT)

.PHONY: ss3d
ss3d: $(OUTDIR)/$(LIBPFX)ss3d$(LIBEXT)

$(OUTDIR)/sgs-sdl-release$(BINEXT): $(OUTDIR)/$(LIBPFX)sgs-sdl$(LIBEXT) src/ss_launcher.c
	$(LINUXHACKPRE)
	gcc -o $@ src/ss_launcher.c $(call WinOnly,-mwindows) $(COMPATHS) $(LIBFLAGS) -Isgscript/src -Isgscript/ext $(C2FLAGS) -DSS_RELEASE -s
	$(LINUXHACKPOST)
$(OUTDIR)/sgs-sdl-debug$(BINEXT): $(OUTDIR)/$(LIBPFX)sgs-sdl$(LIBEXT) src/ss_launcher.c
	$(LINUXHACKPRE)
	gcc -o $@ src/ss_launcher.c $(COMPATHS) $(LIBFLAGS) -Isgscript/src -Isgscript/ext $(C2FLAGS) -s
	$(LINUXHACKPOST)

$(OUTDIR)/$(LIBPFX)sgs-sdl$(LIBEXT): $(OBJ)
	$(MAKE) -C sgscript xgmath
	$(LINUXHACKPRE)
	gcc -o $@ $(OBJ) $(C2FLAGS) -Lsgscript/bin $(LINKPATHS) $(PLATFLAGS) \
		-lSDL2main -lSDL2 -lsgscript -lfreeimage -shared
	$(LINUXHACKPOST)
	$(PLATPOST)

$(OUTDIR)/$(LIBPFX)ss3d$(LIBEXT): $(SS3D_OBJ) $(OUTDIR)/$(LIBPFX)sgs-sdl$(LIBEXT)
	$(MAKE) -C sgscript xgmath
	$(LINUXHACKPRE)
	gcc -o $@ $(SS3D_OBJ) $(C2FLAGS) -Lsgscript/bin $(LINKPATHS) $(PLATFLAGS) \
		-lsgscript -shared
	$(LINUXHACKPOST)
	$(PLATPOST)

$(OBJDIR)/ss_%.o: $(SRCDIR)/ss_%.c $(DEPS)
	$(CC) -c -o $@ $< $(COMPATHS) -Isgscript/src -Isgscript/ext $(C2FLAGS) -Wno-comment

$(OBJDIR)/ss3d_%.o: $(SRCDIR)/ss3d_%.c $(SS3D_DEPS)
	$(CC) -c -o $@ $< $(COMPATHS) -Isgscript/src -Isgscript/ext $(C2FLAGS) -Wno-comment
$(OBJDIR)/lodepng.o: $(SRCDIR)/lodepng.c $(SRCDIR)/lodepng.h
	$(CC) -c -o $@ $< $(COMPATHS) -Isgscript/src -Isgscript/ext $(C2FLAGS) -Wno-comment
$(OBJDIR)/dds.o: $(SRCDIR)/dds.c $(SRCDIR)/dds.h
	$(CC) -c -o $@ $< $(COMPATHS) -Isgscript/src -Isgscript/ext $(C2FLAGS) -Wno-comment

.PHONY: clean
clean:
	$(RM) $(call FixPath,$(OBJDIR)/*.o $(OUTDIR)/sgs*)

.PHONY: clean_all
clean_all: clean
	$(MAKE) -C sgscript clean



endif



endif

