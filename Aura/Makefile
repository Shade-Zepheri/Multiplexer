ifeq ($(IPAD),1)
export THEOS_DEVICE_IP=192.168.254.6
export THEOS_DEVICE_PORT=22
endif

CFLAGS = -I../ -I../Theming/
CFLAGS += -fobjc-arc
TARGET = iphone:9.3

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Aura
Aura_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
Aura_FRAMEWORKS = UIKit CoreGraphics
Aura_LIBRARIES = applist multiplexercore
SpringBoard_UIAppCustomBackgroundModes.xm_CFLAGS = -fno-objc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
