ifeq ($(IPAD),1)
export THEOS_DEVICE_IP=192.168.254.7
export THEOS_DEVICE_PORT=22
endif

CFLAGS = -I../ -I../Theming/
CFLAGS += -fobjc-arc -Wno-deprecated-declarations
TARGET = iphone:10.1

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Aura
Aura_FILES = $(wildcard *.xm) $(wildcard *.x)
Aura_FRAMEWORKS = UIKit CoreGraphics
Aura_EXTRA_FRAMEWORKS = MultiplexerCore
Aura_LIBRARIES = applist
SpringBoard_UIAppCustomBackgroundModes.x_CFLAGS = -fno-objc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
