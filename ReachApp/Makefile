ARCHS = armv7 armv7s arm64
CFLAGS = -I../ -I../Aura/ -I../Empoleon/ -I../widgets/ -I../widgets/Core/ -I../widgets/Reachability/ -I../Theming/ -I../Messaging/ -I../GestureSupport/ -I../KeyboardSupport/ -O2
CFLAGS += -fobjc-arc
TARGET = iphone:9.3

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachApp
ReachApp_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
ReachApp_FRAMEWORKS = UIKit CoreGraphics
ReachApp_LIBRARIES = multiplexercore
ReachApp_LDFLAGS = -L../.theos/obj/debug/

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
