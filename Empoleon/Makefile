CFLAGS = -I../ -I../Theming/ -I../GestureSupport/ -I../Aura/ -I../Empoleon/ -I../SwipeOver/ -I../Messaging/ -I../KeyboardSupport -I../MissionControl -O2
CFLAGS += -fobjc-arc
TARGET = iphone:9.3

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Empoleon
Empoleon_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
Empoleon_FRAMEWORKS = UIKit CoreGraphics
Empoleon_LIBRARIES = multiplexercore

include $(THEOS_MAKE_PATH)/tweak.mk
