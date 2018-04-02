CFLAGS = -fobjc-arc -I../ -I../Theming

include $(THEOS)/makefiles/common.mk

TOOL_NAME = ReachAppFSDaemon
ReachAppFSDaemon_FILES = main.m
ReachAppFSDaemon_PRIVATE_FRAMEWORKS = Foundation MobileCoreServices
ReachAppFSDaemon_CODESIGN_FLAGS = -Sentitlements.xml

include $(THEOS_MAKE_PATH)/tool.mk
