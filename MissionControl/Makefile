ifeq ($(IPAD),1)
export THEOS_DEVICE_IP=192.168.254.4
export THEOS_DEVICE_PORT=22
endif

CFLAGS = -I../ -I../Theming/ -I../GestureSupport/ -I../Empoleon/
CFLAGS += -fobjc-arc
TARGET = iphone:9.3

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MissionControl
MissionControl_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
MissionControl_FRAMEWORKS = UIKit CoreGraphics
MissionControl_LIBRARIES = multiplexercore

include $(THEOS_MAKE_PATH)/tweak.mk
