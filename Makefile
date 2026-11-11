TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

# RootHide (Relaxin / RootHide Bootstrap) package scheme.
# Requires roothide/theos: https://github.com/roothide/theos
# To build a rootless (Dopamine) package instead, override on the command line:
#   make package THEOS_PACKAGE_SCHEME=rootless
THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TelegramBGDownloader

TelegramBGDownloader_FILES = Tweak.x
TelegramBGDownloader_CFLAGS = -fobjc-arc
TelegramBGDownloader_FRAMEWORKS = UIKit Foundation AVFoundation

INSTALL_TARGET_PROCESSES = Telegram

include $(THEOS_MAKE_PATH)/tweak.mk
