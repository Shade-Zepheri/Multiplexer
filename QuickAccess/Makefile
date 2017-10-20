ifeq ($(IPAD),1)
export THEOS_DEVICE_IP=192.168.254.4
export THEOS_DEVICE_PORT=22
endif

CFLAGS = -I../ -I../Theming/
CFLAGS += -fobjc-arc
TARGET = iphone:9.3

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = QuickAccess
QuickAccess_FILES = $(wildcard *.x)
QuickAccess_FRAMEWORKS = UIKit CoreGraphics
QuickAccess_EXTRA_FRAMEWORKS = MultiplexerCore

include $(THEOS_MAKE_PATH)/tweak.mk
