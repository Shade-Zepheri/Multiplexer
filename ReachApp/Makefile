ifeq ($(IPAD),1)
export THEOS_DEVICE_IP=192.168.254.4
export THEOS_DEVICE_PORT=22
endif

CFLAGS = -I../ -I../Aura/ -I../Empoleon/ -I../widgets/ -I../widgets/Core/ -I../widgets/Reachability/ -I../Theming/ -I../Messaging/ -I../GestureSupport/ -I../KeyboardSupport/
CFLAGS += -fobjc-arc
TARGET = iphone:10.1

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachApp
ReachApp_FILES = $(wildcard *.x) $(wildcard *.m)
ReachApp_FRAMEWORKS = UIKit CoreGraphics
ReachApp_EXTRA_FRAMEWORKS = MultiplexerCore

include $(THEOS_MAKE_PATH)/tweak.mk
