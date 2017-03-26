export TARGET = iphone:9.2

CFLAGS = -I./ -Iwidgets/ -Iwidgets/Core/ -Iwidgets/Reachability/ -IAura/ -IEmpoleon/ -IMissionControl/ -IQuickAccess/ -IReachApp/ -ISwipeOver/ -IGestureSupport/ -IKeyboardSupport/ -IIntroTutorial/ -IMessaging/ -ITheming/ -O2
CFLAGS += -fobjc-arc

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libmultiplexercore
libmultiplexercore_FILES = Tweak.xm $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m) \
	$(wildcard widgets/*.xm) $(wildcard widgets/*.mm) $(wildcard widgets/*.m) \
	$(wildcard widgets/Core/*.xm) $(wildcard widgets/Core/*.mm) $(wildcard widgets/Core/*.m) \
	$(wildcard widgets/Reachability/*.xm) $(wildcard widgets/Reachability/*.mm) $(wildcard widgets/Reachability/*.m) \
	$(wildcard KeyboardSupport/*.xm) $(wildcard KeyboardSupport/*.mm) $(wildcard KeyboardSupport/*.m) \
	$(wildcard GestureSupport/*.xm) $(wildcard GestureSupport/*.mm) $(wildcard GestureSupport/*.m) \
	$(wildcard IntroTutorial/*.xm) $(wildcard IntroTutorial/*.mm) $(wildcard IntroTutorial/*.m) \
	$(wildcard Messaging/*.xm) $(wildcard Messaging/*.mm) $(wildcard Messaging/*.m) \
	$(wildcard DRM/*.xm) $(wildcard DRM/*.mm) $(wildcard DRM/*.m) \
	$(wildcard Theming/*.xm) $(wildcard Theming/*.mm) $(wildcard Theming/*.m) \
	$(wildcard Debugging/*.xm) $(wildcard Debugging/*.mm) $(wildcard Debugging/*.m)

libmultiplexercore_FRAMEWORKS = UIKit QuartzCore CoreGraphics CoreImage
libmultiplexercore_PRIVATE_FRAMEWORKS = GraphicsServices BackBoardServices AppSupport IOKit
libmultiplexercore_EXTRA_FRAMEWORKS = CydiaSubstrate
libmultiplexercore_LIBRARIES = rocketbootstrap applist

SUBPROJECTS = reachappfakephonemode reachappassertiondhooks reachappbackboarddhooks reachappsettings reachappflipswitch reachappfsdaemon

include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-libmultiplexercore-stage::
	@# create directory
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries$(ECHO_END)

	@# Create Link
	$(ECHO_NOTHING)ln -s /usr/lib/libmultiplexercore.dylib $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/MultiplexerCore.dylib$(ECHO_END)

	@# move Filter Plist
	$(ECHO_NOTHING)cp MultiplexerCore.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries$(ECHO_END)
