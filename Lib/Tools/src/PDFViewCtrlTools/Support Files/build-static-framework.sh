#!/bin/sh
#
# Build the static framework.
#

# Check if this script has already been invoked to prevent infinite recursion.
check_script_recursion() {
	if [ "${PDFTRON_STATIC_FRAMEWORK_SCRIPT_INVOKED:-NO}" = "YES" ]; then
		# Already invoked - exit successfully.
	    exit 0
	fi

	export PDFTRON_STATIC_FRAMEWORK_SCRIPT_INVOKED="YES"
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
}

# Set the configuration build dirs for each platform.
set_configuration_build_dirs() {
	CONFIGURATION_BUILD_DIR="${CONFIGURATION_BUILD_DIR:-${BUILD_DIR}/${CONFIGURATION}${EFFECTIVE_PLATFORM_NAME}}"

	CORRESPONDING_CONFIGURATION_BUILD_DIR="${BUILD_DIR}/${CONFIGURATION}${CORRESPONDING_EFFECTIVE_PLATFORM_NAME}"
}

# Set the built product dirs for each platform.
set_built_product_dirs() {
	set_configuration_build_dirs

	BUILT_PRODUCTS_DIR="${BUILT_PRODUCTS_DIR:-${CONFIGURATION_BUILD_DIR}}"

	CORRESPONDING_BUILT_PRODUCTS_DIR="${CORRESPONDING_CONFIGURATION_BUILD_DIR}"
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

# Set the executable name, with prefix and extension, created for each platform.
set_executable_name() {
	if [ -z "${EXECUTABLE_NAME}" ]; then
		EXECUTABLE_NAME="${EXECUTABLE_PREFIX:-lib}${PRODUCT_NAME}.${EXECUTABLE_EXTENSION:-a}"
	fi
}

# Ensure all necessary global variables are set.
ensure_global_variables() {
	ensure_sdk_version
	set_corresponding_names

	set_effective_platform_names
	set_built_product_dirs
	
	set_full_product_name
	set_executable_name
}

build_corresponding_platform() {
	xcrun xcodebuild \
		-project "${PROJECT_FILE_PATH}" \
		-target "${TARGET_NAME}" \
		-configuration "${CONFIGURATION}" \
		-sdk "${CORRESPONDING_SDK_NAME}" \
		BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" SYMROOT="${SYMROOT}" \
		OBJROOT="${OBJROOT}/DependentBuilds" \
		"${ACTION}"
}

# Create a universal binary with device and simulator architectures.
create_universal_binary() {
	xcrun lipo \
		"${BUILT_PRODUCTS_DIR}/${EXECUTABLE_NAME}" \
		"${CORRESPONDING_BUILT_PRODUCTS_DIR}/${EXECUTABLE_NAME}" \
		-create -output "${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}/Versions/A/${PRODUCT_NAME}"
}

build_framework() {
	echo "Building the corresponding platform: ${CORRESPONDING_PLATFORM_NAME}"
	build_corresponding_platform

	echo "Creating a universal binary"
	create_universal_binary
	
	# Copy the universal binary to the corresponding platform to have a complete framework in both.
	cp -a "${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}/Versions/A/${PRODUCT_NAME}" "${CORRESPONDING_BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}/Versions/A/${PRODUCT_NAME}"
}

main() {
	# Fail on all errors.
	set -e
	set -o pipefail

	# Debugging
	set -x

	# Avoid recursively calling this script.
	echo "Checking if script has already been invoked"
	check_script_recursion

	echo "Ensuring build settings and locations are set"
	ensure_global_variables

	echo "Building framework"
	build_framework
}

main "$@"