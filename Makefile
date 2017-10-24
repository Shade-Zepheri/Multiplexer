export TARGET = iphone:9.2

ifeq ($(IPAD),1)
export THEOS_DEVICE_IP=192.168.254.7
export THEOS_DEVICE_PORT=22
endif

CFLAGS = -I./ -Iwidgets/ -Iwidgets/Core/ -Iwidgets/Reachability/ -IAura/ -IEmpoleon/ -IQuickAccess/ -IReachApp/ -IGestureSupport/ -IKeyboardSupport/ -IIntroTutorial/ -IMessaging/ -ITheming/
CFLAGS += -fobjc-arc -flto=thin

INSTALL_TARGET_PROCESSES = Preferences

ifeq ($(RESPRING),1)
INSTALL_TARGET_PROCESSES += SpringBoard
endif

include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = MultiplexerCore
MultiplexerCore_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.x) $(wildcard *.m) \
	$(wildcard widgets/*.xm) $(wildcard widgets/*.mm) $(wildcard widgets/*.m) \
	$(wildcard widgets/Core/*.xm) $(wildcard widgets/Core/*.mm) $(wildcard widgets/Core/*.m) \
	$(wildcard widgets/Reachability/*.xm) $(wildcard widgets/Reachability/*.mm) $(wildcard widgets/Reachability/*.x) $(wildcard widgets/Reachability/*.m) \
	$(wildcard KeyboardSupport/*.mm) $(wildcard KeyboardSupport/*.x) $(wildcard KeyboardSupport/*.m) \
	$(wildcard GestureSupport/*.xm) $(wildcard GestureSupport/*.x) $(wildcard GestureSupport/*.m) \
	$(wildcard IntroTutorial/*.x) \
	$(wildcard Messaging/*.x) \
	$(wildcard DRM/*.x) \
	$(wildcard Theming/*.m) \
	$(wildcard Debugging/*.x)

MultiplexerCore_FRAMEWORKS = UIKit QuartzCore CoreGraphics
MultiplexerCore_PRIVATE_FRAMEWORKS = FrontBoardServices BackBoardServices IOKit
MultiplexerCore_EXTRA_FRAMEWORKS = CydiaSubstrate

SUBPROJECTS = reachappfakephonemode reachappassertiondhooks reachappbackboarddhooks reachappsettings reachappflipswitch reachappfsdaemon

include $(THEOS_MAKE_PATH)/framework.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-MultiplexerCore-stage::
	@# create directory
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries$(ECHO_END)

	@# Create Link
	$(ECHO_NOTHING)ln -s /Library/Frameworks/MultiplexerCore.framework/MultiplexerCore $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/MultiplexerCore.dylib$(ECHO_END)

	@# move Filter Plist
	$(ECHO_NOTHING)cp MultiplexerCore.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries$(ECHO_END)
