ARCHS = armv7 armv7s arm64
CFLAGS = -I../ -I../Theming/ -O2
CFLAGS += -fobjc-arc
TARGET = iphone:9.3

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = QuickAccess
QuickAccess_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
QuickAccess_FRAMEWORKS = UIKit CoreGraphics
QuickAccess_LIBRARIES = multiplexercore
QuickAccess_LDFLAGS = -L../.theos/obj/debug/

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
