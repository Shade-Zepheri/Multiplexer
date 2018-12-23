include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ReachAppSettings
ReachAppSettings_FILES = $(shell find $(THEOS)/include/SettingsKit -name '*.m') $(wildcard *.x) $(wildcard *.m) ../PDFImageOptions.m ../PDFImage.m ../RALocalizer.m ../RASettings.m $(wildcard ../Theming/*.m)
ReachAppSettings_INSTALL_PATH = /Library/PreferenceBundles
ReachAppSettings_FRAMEWORKS = UIKit MessageUI Social QuartzCore CoreGraphics
ReachAppSettings_PRIVATE_FRAMEWORKS = Preferences
ReachAppSettings_EXTRA_FRAMEWORKS = CydiaSubstrate
ReachAppSettings_LIBRARIES = applist
ReachAppSettings_CFLAGS = -I../ -I../Aura/ -I../Theming/ -I../QuickAccess -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)rsync -a -v --ignore-existing $(THEOS)/include/SettingsKit/Resources/*.png $(THEOS_STAGING_DIR)/Library/PreferenceBundles/ReachAppSettings.bundle/$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ReachAppSettings.plist$(ECHO_END)
