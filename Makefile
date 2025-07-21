#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=u-boot
PKG_VERSION:=2017.09
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=default
PKG_SOURCE:=u-boot-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=https://oss.cooluc.com/source
PKG_HASH:=0ed4ece5c2ec3b68649eceafda1365053f306ebc9deaf72483d985a173c38720

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

PKG_MAINTAINER:=sbwml <admin@cooluc.com>

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/u-boot.mk
include ../arm-trusted-firmware-rockchip/atf-version.mk

define U-Boot/Default
  BUILD_TARGET:=rockchip
  UENV:=default
  HIDDEN:=1
endef

# RK3576 boards

define U-Boot/Default/rk3576
  BUILD_SUBTARGET:=armv8
  DEPENDS:=+PACKAGE_u-boot-$(1):trusted-firmware-a-rk3576
  SOC:=rk3576
  ATF:=$(RK3576_ATF)
  DDR:=$(RK3576_DDR)
endef

define U-Boot/nanopi-r76s-rk3576
  $(U-Boot/Default/rk3576)
  NAME:=FriendlyARM NanoPi R76S
  BUILD_DEVICES:=friendlyarm_nanopi-r76s
endef

UBOOT_TARGETS := nanopi-r76s-rk3576

UBOOT_CONFIGURE_VARS += USE_PRIVATE_LIBGCC=yes

UBOOT_MAKE_FLAGS += \
  IDB_SOC=$(SOC) \
  TPL_BIN=$(STAGING_DIR_IMAGE)/$(DDR) \
  u-boot.itb idbloader.img

define Build/Configure
	$(call Build/Configure/U-Boot)

	$(SED) 's/CONFIG_TOOLS_LIBCRYPTO=y/# CONFIG_TOOLS_LIBCRYPTO is not set/' $(PKG_BUILD_DIR)/.config
	$(SED) 's#CONFIG_MKIMAGE_DTC_PATH=.*#CONFIG_MKIMAGE_DTC_PATH="$(PKG_BUILD_DIR)/scripts/dtc/dtc"#g' $(PKG_BUILD_DIR)/.config
	echo 'CONFIG_IDENT_STRING=" OpenWrt"' >> $(PKG_BUILD_DIR)/.config
	$(CP) $(STAGING_DIR_IMAGE)/$(ATF) $(PKG_BUILD_DIR)/bl31.elf
endef

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	dd if=/dev/zero of=$(PKG_BUILD_DIR)/u-boot-rockchip.bin bs=512 count=16320
	dd if=$(PKG_BUILD_DIR)/idbloader.img of=$(PKG_BUILD_DIR)/u-boot-rockchip.bin conv=notrunc
	dd if=$(PKG_BUILD_DIR)/u-boot.itb of=$(PKG_BUILD_DIR)/u-boot-rockchip.bin seek=16320 conv=notrunc
	$(CP) $(PKG_BUILD_DIR)/u-boot-rockchip.bin $(STAGING_DIR_IMAGE)/$(BUILD_VARIANT)-u-boot-rockchip.bin
endef

define Package/u-boot/install/default
endef

$(eval $(call BuildPackage/U-Boot))
