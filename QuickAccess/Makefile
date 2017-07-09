ifeq ($(IPAD),1)
export THEOS_DEVICE_IP=192.168.254.5
export THEOS_DEVICE_PORT=22
endif

CFLAGS = -I../ -I../Theming/
CFLAGS += -fobjc-arc
TARGET = iphone:9.3

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = QuickAccess
QuickAccess_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
QuickAccess_FRAMEWORKS = UIKit CoreGraphics MultiplexerCore

include $(THEOS_MAKE_PATH)/tweak.mk
