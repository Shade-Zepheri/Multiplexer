ARCHS = armv7 armv7s arm64
CFLAGS = -I../ -I../Theming/ -I../GestureSupport/ -I../Aura/ -I../Empoleon/ -I../SwipeOver/ -I../Messaging/ -I../KeyboardSupport -I../MissionControl -O2
CFLAGS += -fobjc-arc
TARGET = iphone:9.3

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Empoleon
Empoleon_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
Empoleon_FRAMEWORKS = UIKit CoreGraphics
Empoleon_LIBRARIES = multiplexercore
Empoleon_LDFLAGS = -L$(THEOS_OBJ_DIR)

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
