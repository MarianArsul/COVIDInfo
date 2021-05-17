#!/bin/sh
#
# Update localizable .strings files.
#

# Custom localized string routine.
readonly GENSTRINGS_ROUTINE="PTLocalizedString"

# Intermediate output directory for .strings files.
readonly STRINGS_TEMP_DIR="${DERIVED_FILE_DIR}/localized-strings"

# Output strings file to the en.lproj directory.
readonly STRINGS_DEST_DIR="${SRCROOT}/Tools/en.lproj"

# Clean the script temp dir from previous runs. 
prepare_script_temp_dir() {
	if [ -d "${STRINGS_TEMP_DIR}" ]; then
		rm -rf "${STRINGS_TEMP_DIR}"
	fi

	mkdir -p "${STRINGS_TEMP_DIR}"
}

# Run genstrings(1) over all Objective-C[++] files.
run_genstrings() {
	echo "Running genstrings over all source files"
    exclude_files=(PTToolsUtil.m) # array of files to exclude from genstrings
    find "${SRCROOT}" -type f \( ${exclude_files[@]/#/ ! -name } -name \*.m -o -name \*.mm \) -print0 \
        | xargs -0 genstrings -q -s "${GENSTRINGS_ROUTINE}" -o "${STRINGS_TEMP_DIR}"
}

# Use iconv(1) to convert a strings file ($1) from UTF-16 to UTF-8 encoding.
# NOTE: The input file is overwritten.
convert_strings_file_encoding() {
    strings_file="$1"
    if [ -z "${strings_file}" ]; then
        return 0
    fi

    echo "Converting generated strings file to UTF-8 encoding: ${strings_file}"

    temp_strings_file="$(mktemp -t "$(basename "${strings_file}")")"

    iconv -f UTF-16 -t UTF-8 "${strings_file}" > "${temp_strings_file}"

    # Overwrite strings file (preserving existing permissions, etc.).
    cp "${temp_strings_file}" "${strings_file}"
}

# Move strings files that have changed into the destination directory.
move_modified_strings_files() {
	echo "Moving generated strings files into destination directory: ${STRINGS_DEST_DIR}"

	find "${STRINGS_TEMP_DIR}" -type f -name \*.strings -print | while IFS= read -r strings_file; do
		# Convert the strings file before moving.
		convert_strings_file_encoding "${strings_file}"

	    dest_file="${STRINGS_DEST_DIR}/$(basename "${strings_file}")"

	    # Only move strings file if contents are different.
	    if ! cmp -s "${strings_file}" "${dest_file}"; then
	        mv "${strings_file}" "${dest_file}"
	    fi
	done
}

main() {
	# Fail on all errors.
	set -e
	set -o pipefail

	prepare_script_temp_dir

	run_genstrings

	move_modified_strings_files
}

main "$@"
