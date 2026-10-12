TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TelegramBGDownloader

TelegramBGDownloader_FILES = Tweak.x
TelegramBGDownloader_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
