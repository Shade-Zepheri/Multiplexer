ARCHS = armv7 armv7s arm64
CFLAGS = -I./ -Iwidgets/ -Iwidgets/Core/ -Iwidgets/Reachability/ -IAura/ -IEmpoleon/ -IMissionControl/ -IQuickAccess/ -IReachApp/ -ISwipeOver/ -IGestureSupport/ -IKeyboardSupport/ -IIntroTutorial/ -IMessaging/ -ITheming/ -O2
CFLAGS += -fobjc-arc
TARGET = iphone:9.2

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libmultiplexercore
libmultiplexercore_FILES = Tweak.xm $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m) \
	Empoleon/RADesktopManager.xm \
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
libmultiplexercore_LDFLAGS = -lrocketbootstrap -lapplist
libmultiplexercore_INSTALL_PATH = /usr/lib

include $(THEOS_MAKE_PATH)/library.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += reachappfakephonemode

SUBPROJECTS += reachappassertiondhooks
SUBPROJECTS += reachappbackboarddhooks

SUBPROJECTS += reachappsettings
SUBPROJECTS += reachappflipswitch
SUBPROJECTS += reachappfsdaemon


include $(THEOS_MAKE_PATH)/aggregate.mk
