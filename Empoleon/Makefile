ifeq ($(IPAD),1)
export THEOS_DEVICE_IP=192.168.254.4
export THEOS_DEVICE_PORT=22
endif

CFLAGS = -I../ -I../Theming/ -I../GestureSupport/ -I../Aura/ -I../Empoleon/ -I../SwipeOver/ -I../Messaging/ -I../KeyboardSupport -I../MissionControl
CFLAGS += -fobjc-arc
TARGET = iphone:9.3

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Empoleon
Empoleon_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.x)
Empoleon_FRAMEWORKS = UIKit CoreGraphics
Empoleon_EXTRA_FRAMEWORKS = MultiplexerCore

include $(THEOS_MAKE_PATH)/tweak.mk
