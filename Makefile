TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TelegramBGDownloader

TelegramBGDownloader_FILES = Tweak.x
TelegramBGDownloader_CFLAGS = -fobjc-arc
TelegramBGDownloader_FRAMEWORKS = UIKit Foundation AVFoundation

INSTALL_TARGET_PROCESSES = Telegram

include $(THEOS_MAKE_PATH)/tweak.mk
