#CFLAGS += -fno-objc-arc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachAppBackboarddHooks
ReachAppBackboarddHooks_FILES = Tweak.x
ReachAppBackboarddHooks_PRIVATE_FRAMEWORKS = AppSupport IOKit
ReachAppBackboarddHooks_LIBRARIES = rocketbootstrap
ReachAppBackboarddHooks_CFLAGS = -I../Messaging/

include $(THEOS_MAKE_PATH)/tweak.mk
