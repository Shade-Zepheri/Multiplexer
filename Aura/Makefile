ARCHS = armv7 armv7s arm64
CFLAGS = -I../ -I../Theming/ -O2
CFLAGS += -fobjc-arc
TARGET = iphone:9.3

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Aura
Aura_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
Aura_FRAMEWORKS = UIKit CoreGraphics
Aura_LDFLAGS = -L../.theos/obj/debug/
Aura_LIBRARIES = applist multiplexercore
IconIndicator.xm_CFLAGS = -fno-objc-arc
SpringBoard_UIAppCustomBackgroundModes.xm_CFLAGS = -fno-objc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
