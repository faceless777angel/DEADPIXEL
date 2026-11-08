ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DEADPIXEL

DEADPIXEL_FILES = Tweak.x
DEADPIXEL_CFLAGS = -fobjc-arc
DEADPIXEL_FRAMEWORKS = UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
