ifeq ($(IPAD),1)
export THEOS_DEVICE_IP=192.168.254.5
export THEOS_DEVICE_PORT=22
endif

CFLAGS = -I../ -I../Theming/ -I../GestureSupport/ -I../Empoleon/ -I../Messaging/ -I../KeyboardSupport -I../MissionControl
CFLAGS += -fobjc-arc
TARGET = iphone:9.3

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SwipeOver
SwipeOver_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
SwipeOver_FRAMEWORKS = UIKit CoreGraphics
SwipeOver_LIBRARIES = multiplexercore

include $(THEOS_MAKE_PATH)/tweak.mk
