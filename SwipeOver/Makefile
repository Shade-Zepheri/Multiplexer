ARCHS = armv7 armv7s arm64

CFLAGS = -I../ -I../Theming/ -I../GestureSupport/ -I../Empoleon/ -I../Messaging/ -I../KeyboardSupport -I../MissionControl -O2
CFLAGS += -fobjc-arc
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SwipeOver
SwipeOver_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
SwipeOver_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
