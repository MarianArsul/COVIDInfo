#!/bin/sh
#
# Create a univeral framework with device and simulator architectures.
#

# The name of the platform (iphoneos, iphonesimulator) whose product structure
# will be used as the base for the universal.
#
# If this is empty, the current platform will be used.
readonly UNIVERSAL_BASE_PLATFORM_NAME="iphoneos"

# Check if this script has been disabled.
check_script_disabled() {
	disabled=0
	
	if [ "${ACTION}" = "install" ]; then
		# Disabled for install/archive build
		echo "Universal framework script is disabled for "install" build"
		disabled=1
	fi
	
	if [ "${PDFTRON_CREATE_UNIVERSAL_FRAMEWORK:-YES}" = "NO" ]; then
		# Disabled - exit successfully
		echo "Universal framework script is disabled with environment variable "PDFTRON_CREATE_UNIVERSAL_FRAMEWORK"=NO"
		disabled=1
	fi
	
	if [ ${disabled:-0} -eq 1 ]; then
		# Disabled - exit successfully
		echo "Exiting successfully"
		exit 0
	fi
}

# Check if this script has already been invoked to prevent infinite recursion.
check_script_recursion() {
	if [ ${SCRIPT_INVOKED:-0} -eq 1 ]; then
		# Already invoked - exit successfully.
		exit 0
	fi

	export SCRIPT_INVOKED=1
}

# Ensure SDK_VERSION is set.
ensure_sdk_version() {
	SDK_VERSION="${SDK_VERSION:-$(echo "${SDK_NAME}" | grep -o '\d\{1,2\}\.\d\{1,2\}$')}"
}

# Build the corresponding platform and sdk name for the current platform and sdk.
set_corresponding_names() {
	if [ "${PLATFORM_NAME}" = "iphonesimulator" ]; then
		# Ensure CORRESPONDING_PLATFORM_NAME is set.
		CORRESPONDING_PLATFORM_NAME="${CORRESPONDING_DEVICE_PLATFORM_NAME:-iphoneos}"

		# Ensure CORRESPONDING_SDK_NAME is set.
		CORRESPONDING_SDK_NAME="${CORRESPONDING_DEVICE_SDK_NAME:-${CORRESPONDING_PLATFORM_NAME}${SDK_VERSION}}"
	else # PLATFORM_NAME = "iphoneos"
		# Ensure CORRESPONDING_PLATFORM_NAME is set.
		CORRESPONDING_PLATFORM_NAME="${CORRESPONDING_SIMULATOR_PLATFORM_NAME:-iphonesimulator}"

		# Ensure CORRESPONDING_SDK_NAME is set.
		CORRESPONDING_SDK_NAME="${CORRESPONDING_SIMULATOR_SDK_NAME:-${CORRESPONDING_PLATFORM_NAME}${SDK_VERSION}}"
	fi
}

# Set the platform names used for constructing the configuration build dirs.
set_effective_platform_names() {
	EFFECTIVE_PLATFORM_NAME="${EFFECTIVE_PLATFORM_NAME:--${PLATFORM_NAME}}"

	CORRESPONDING_EFFECTIVE_PLATFORM_NAME="-${CORRESPONDING_PLATFORM_NAME}"

	UNIVERSAL_EFFECTIVE_PLATFORM_NAME="-${UNIVERSAL_PLATFORM_NAME}"
}

# Set the configuration build dirs for each platform.
set_configuration_build_dirs() {
	CONFIGURATION_BUILD_DIR="${CONFIGURATION_BUILD_DIR:-${BUILD_DIR}/${CONFIGURATION}${EFFECTIVE_PLATFORM_NAME}}"

	CORRESPONDING_CONFIGURATION_BUILD_DIR="${BUILD_DIR}/${CONFIGURATION}${CORRESPONDING_EFFECTIVE_PLATFORM_NAME}"

	UNIVERSAL_CONFIGURATION_BUILD_DIR="${BUILD_DIR}/${CONFIGURATION}${UNIVERSAL_EFFECTIVE_PLATFORM_NAME}"

	# Resolve the configuration build dirs to specific platforms for convenience.
	if [ "${PLATFORM_NAME}" = "iphonesimulator" ]; then
		SIMULATOR_CONFIGURATION_BUILD_DIR="${CONFIGURATION_BUILD_DIR}"

		DEVICE_CONFIGURATION_BUILD_DIR="${CORRESPONDING_CONFIGURATION_BUILD_DIR}"
	else # PLATFORM_NAME = "iphoneos"
		SIMULATOR_CONFIGURATION_BUILD_DIR="${CORRESPONDING_CONFIGURATION_BUILD_DIR}"

		DEVICE_CONFIGURATION_BUILD_DIR="${CONFIGURATION_BUILD_DIR}"
	fi
}

# Set the product name, with extension, created for each platform.
# The wrapper name is used preferentially over the product name.
#
# The default product suffix is ".framework".
set_full_product_name() {
	if [ -z "${FULL_PRODUCT_NAME+x}" ]; then
		FULL_PRODUCT_NAME="${WRAPPER_NAME:-${PRODUCT_NAME}}${WRAPPER_SUFFIX:-.${WRAPPER_EXTENSION:-framework}}"
	fi
}

# Ensure all necessary global variables are set.
ensure_global_variables() {
	ensure_sdk_version
	set_corresponding_names

	UNIVERSAL_PLATFORM_NAME="universal"

	set_effective_platform_names
	set_configuration_build_dirs
	set_full_product_name
}

# Build the same target with the corresponding platform.
#
# NOTE:
# If SYMROOT is not explicitly specified, the corresponding platform product
# may be output to $(PROJECT_DIR)/build, despite the Xcode global settings or
# the per-user project settings. (BUILD_DIR, CONFIGURATION_BUILD_DIR, and other
# build location settings are all derived from SYMROOT)
build_corresponding_platform() {
	echo "Building corresponding platform \"${CORRESPONDING_PLATFORM_NAME}\""

	xcodebuild \
		-project "${PROJECT_FILE_PATH}" \
		-target "${TARGET_NAME}" \
		-sdk "${CORRESPONDING_SDK_NAME}" \
		-configuration "${CONFIGURATION}" \
		SYMROOT="${SYMROOT}" \
		OBJROOT="${OBJROOT}/DependentBuilds" \
		"${ACTION}"
}

# Prepare the universal platform with a clean copy of the specified platform product.
# This sets up the correct structure in the universal product.
prepare_universal_platform() {
	# Clean the universal configuration build directory.
	if [ -d "${UNIVERSAL_CONFIGURATION_BUILD_DIR}" ]; then
		rm -rf "${UNIVERSAL_CONFIGURATION_BUILD_DIR}"
	fi

	mkdir "${UNIVERSAL_CONFIGURATION_BUILD_DIR}"

	# Determine the platform whose product will be used as the base for the universal.
	case "${UNIVERSAL_BASE_PLATFORM_NAME}" in
		"iphoneos")
			# Use the device platform configuration build dir.
			UNIVERSAL_BASE_CONFIGURATION_BUILD_DIR="${DEVICE_CONFIGURATION_BUILD_DIR}"
			;;
		"iphonesimulator")
			# Use the simulator platform configuration build dir.
			UNIVERSAL_BASE_CONFIGURATION_BUILD_DIR="${SIMULATOR_CONFIGURATION_BUILD_DIR}"
			;;
		*)
			# Default: use the current platform configuration build dir.
			UNIVERSAL_BASE_CONFIGURATION_BUILD_DIR="${CONFIGURATION_BUILD_DIR}"
			;;
	esac

	# Copy the specified device platform product to the universal platform.
	cp -R "${UNIVERSAL_BASE_CONFIGURATION_BUILD_DIR}/${FULL_PRODUCT_NAME}" "${UNIVERSAL_CONFIGURATION_BUILD_DIR}/"
}

# Create a universal binary with device and simulator architectures.
create_universal_binary() {
	echo "Creating universal framework binary"
	
	xcrun lipo \
		"${CONFIGURATION_BUILD_DIR}/${FULL_PRODUCT_NAME}/${EXECUTABLE_NAME}" \
		"${CORRESPONDING_CONFIGURATION_BUILD_DIR}/${FULL_PRODUCT_NAME}/${EXECUTABLE_NAME}" \
		-create -output "${UNIVERSAL_CONFIGURATION_BUILD_DIR}/${FULL_PRODUCT_NAME}/${EXECUTABLE_NAME}"
}

main() {
	# Fail on all errors.
	set -e
	set -o pipefail

	check_script_disabled

	# Ensure this script is not called recursively by the same target.
	check_script_recursion

	ensure_global_variables

	build_corresponding_platform

	prepare_universal_platform

	create_universal_binary
}

main "$@"