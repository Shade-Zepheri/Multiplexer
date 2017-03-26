CFLAGS = -I../Messaging/ -O2
#CFLAGS += -fno-objc-arc

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachAppBackboarddHooks
ReachAppBackboarddHooks_FILES = Tweak.xm
ReachAppBackboarddHooks_PRIVATE_FRAMEWORKS = AppSupport IOKit
ReachAppBackboarddHooks_LIBRARIES = rocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk
