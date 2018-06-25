include $(THEOS)/makefiles/common.mk

TOOL_NAME = ReachAppFSDaemon
ReachAppFSDaemon_FILES = main.m
ReachAppFSDaemon_FRAMEWORKS = MobileCoreServices
ReachAppFSDaemon_CFLAGS = -I../ -I../Theming -fobjc-arc
ReachAppFSDaemon_CODESIGN_FLAGS = -Sentitlements.xml

include $(THEOS_MAKE_PATH)/tool.mk
