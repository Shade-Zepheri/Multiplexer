ARCHS = armv7 armv7s arm64
CFLAGS = -I../ -I../Theming/ -I../GestureSupport/ -I../Empoleon/ -O2
CFLAGS += -fobjc-arc
TARGET = iphone:9.3

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MissionControl
MissionControl_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
MissionControl_FRAMEWORKS = UIKit CoreGraphics
MissionControl_LIBRARIES = multiplexercore
MissionControl_LDFLAGS = -L../.theos/obj/debug/

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
