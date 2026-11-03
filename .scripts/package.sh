#!/bin/bash

latest_release_number () {
    # Github cli to get the latest release
    gh release list --repo $1 --limit 1 |
    # Regex to find the version number, assumes semantic versioning
    grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' |
    # Take the first match in the regex
    head -1 || echo '0.0.0'
}

xcframework_name () {
    # Filter out path and extension to get the framework name
    # Ex. xcframework_name "FirebaseFirestore/leveldb-library.xcframework" = "leveldb-library"
    echo $1 | sed -E 's/.*\/|\.xcframework|\.xcframework\.zip//g'
}

resource_name () {
    # Filter out path to get the file name
    # Ex. file_name "FirebaseFirestore/Resources/gRPCCertificates-Cpp.bundle" = "gRPCCertificates-Cpp.bundle"
    echo $1 | sed -E 's/.*\///g'
}

library_name () {
    # Filter out path to get the folder name
    # Ex. library_name "FirebaseAnalytics/FirebaseInstallations.xcframework" = "FirebaseAnalytics"
    echo $1 | sed -E 's/\/|\/.*\.xcframework|\/.*\.xcframework\.zip//g'
}

excludes () {
    # Files other than xcframeworks will not be included in the package
    echo "$1" | grep -v -E ".xcframework"
}

trim_empty_lines () {
    # Delete all empty lines in a file
    # Portable in-place edit (GNU and BSD sed both accept a suffix)
    sed -i.bak '/^$/d' $1 && rm -f $1.bak
}

template_replace () {
    local file=$(cat $1)
    # Replace the template with the contents of the replacement file
    local result=${file//"$2"/"$(trim_empty_lines $3; cat $3)"}
    # Write the result back to the original file
    rm -f $1; touch $1; printf "$result" >> $1
}

create_scratch () {
    # Create temporary directory
    scratch=$(mktemp -d)
    if [[ $debug ]]; then open $scratch; fi
    # Run cleanup on exit
    trap "if [[ \$debug ]]; then read -p \"\"; fi; rm -rf \"$scratch\"" EXIT
}

rename_frameworks () {
    local prefix="$1"
    for i in */*.xcframework; do (
        local name=$(xcframework_name $i)
        cd "$i/../"; mv "$name.xcframework" "$prefix$name.xcframework"
    ) & done;
    wait
}

zip_frameworks () {
    for i in */*.xcframework; do (
        local name=$(xcframework_name $i)
        cd "$i/../"
        # Reproducible archive: fixed timestamps, sorted entries, no extra
        # attributes (-X), symlinks kept (-y). The same Firebase.zip always
        # yields the same checksums, so anyone can re-run and verify a release.
        find "$name.xcframework" -exec env TZ=UTC touch -h -t 198001010000 {} +
        find "$name.xcframework" -print | LC_ALL=C sort | zip -qyX -@ "$name.xcframework.zip"
    ) & done;
    wait
    # Background jobs do not trip set -e, so check every framework got a zip
    for i in */*.xcframework; do
        if [ ! -f "$i.zip" ]; then echo "Missing zip for $i. Exiting."; exit 1; fi
    done
}

prepare_files_for_distribution () {
    local dist="$1"
    # Create the distribution folder
    mkdir $dist
    # Copy unzipped frameworks for testing (Package.swift using local binaries)
    for i in */*.xcframework; do cp -rf $i $dist; done
    # Copy zipped frameworks for release (these will be uploaded to remote)
    for i in */*.xcframework.zip; do cp -f $i $dist; done
}

generate_sources () {
    local sources="$1"
    # Create the sources folder
    mkdir $sources
    # Create the sources for the umbrella header and modulemap
    mkdir "$sources/Firebase"
    cp -f "Firebase.h" "$sources/Firebase"
    cp -f "module.modulemap" "$sources/Firebase"
    touch "$sources/Firebase/dummy.m" # SPM requires at least one source file
    # Create a source folder for each library target
    for i in */; do
        local name="$(library_name $i)";
        mkdir "$sources/${name}"
        touch "$sources/$name/dummy.swift" # SPM requires at least one source file
        # Copy resources for the target to the source folder
        if [ -d "$i/Resources" ]; then
            cp -rf "$i/Resources" "$sources/$name"
        fi
        # Copy any non-resource/non-xcframework files
        for f in ${i}*; do if [[ $(excludes $f) ]]; then
            # Copy file(s) to sources
            if [[ -d $f ]]; then
                cp -rf $f "$sources/$name"
            else
                cp -f $f "$sources/$name"
            fi
        fi; done;
    done;
}

write_library () {
    local library=$(library_name $1)
    local output="$2"
    local comma="$3"

    # Write to file
    touch $output
    printf "$comma
    .library(
      name: \"$library\",
      targets: [\"${library}Target\"]
    )" >> $output
}

conditional_dependency () {
    local name=$(xcframework_name "$1")
    local output="$2"
    # Check xcframework folder for platform specific architectures
    local ios=$(ls "$name.xcframework" | grep "ios-" >/dev/null && echo ".iOS")
    local tvos=$(ls "$name.xcframework" | grep "tvos-" >/dev/null && echo ".tvOS")
    local macos=$(ls "$name.xcframework" | grep "macos-" >/dev/null && echo ".macOS")
    # Get array of platforms
    local platforms=($ios $tvos $macos)
    # Join platforms with comma and space separation
    local joined=$( echo ${platforms[*]} | sed 's/ /, /g' )
    if [ "$joined" == ".iOS, .tvOS, .macOS" ]; then
        # Supports all platforms, conditional not needed
        echo "\"$name\""
    else
        # Create conditional dependency from target and platforms
        echo ".target(name: \"$name\", condition: .when(platforms: [$joined]))"
    fi
}

write_target () {
    local library=$(library_name $1)
    local output=$2
    local comma=$3
    local target="${library}Target"
    local dependencies=$(ls -1A $library | grep .xcframework.zip)
    local excludes=$(excludes "$(ls -1A $library)")
    # Write to file
    touch $output
    printf "$comma
    .target(
      name: \"$target\",
      dependencies: [
        \"Firebase\"" >> $output
    # All targets depend on the core FirebaseAnalytics binaries
    if [ $target != "FirebaseAnalyticsTarget" ]; then printf ",
        \"FirebaseAnalyticsTarget\"" >> $output
    fi
    # Library specific dependencies are expected to be inside the $library folder
    echo "$dependencies" | while read -r dependency; do printf ",
        $(cd $library; conditional_dependency $dependency)" >> $output
    done; printf "\n      ]" >> $output;
    # Path
    printf ",\n      path: \"Sources/$library\"" >> $output
    # Non-resource, non-xcframework files
    if [[ $excludes ]]; then
        printf ",\n      exclude: [" >> $output
        comma=""; echo "$excludes" | while read -r exclude; do printf "$comma
        \"$exclude\"" >> $output; comma=",";
        done; printf "\n      ]" >> $output;
    fi
    
    # Resources are expected to be inside the $library/Resources folder
    # Note: disabling because these resources will not be in the main bundle
    # https://github.com/akaffenberger/firebase-ios-sdk-xcframeworks/issues/23
    # if [ -d "$library/Resources" ]; then
    #    printf ",\n      resources: [" >> $output
    #    comma=""; for i in "$library/Resources/*"; do printf "$comma
    #    .process(\"Resources/$(resource_name $i)\")" >> $output; comma=","
    #    done; printf "\n      ]" >> $output;
    # fi
    
    # Closing bracket
    printf "\n    )" >> $output
}

write_binary () {
    local file=$1
    local repo=$2
    local version=$3
    local output=$4
    local comma=$5

    # Get the checksum
    touch Package.swift # checksum command requires a package file
    local checksum=$(swift package compute-checksum "$file")
    local name=$(xcframework_name $file)
    local library=$(library_name $file)

    # Write to file
    touch $output
    printf "$comma
    .binaryTarget(
      name: \"$name\",
      url: \"$repo/releases/download/$version/$name.xcframework.zip\",
      checksum: \"$checksum\"
    )" >> $output
}

write_local_binary () {
    local name=$(xcframework_name "$1")
    local dist=$2
    local output=$3
    local comma=$4

    # Write to file
    touch $output
    printf "$comma
    .binaryTarget(
      name: \"$name\",
      path: \"$dist/$name.xcframework\"
    )" >> $output
}

generate_swift_package () {
    local package="$1"
    local template="$2"
    local dist="$3"
    local repo="$4"
    local local_dist="$5"
    local libraries="libraries.txt"
    local targets="targets.txt"
    local binaries="binaries.txt"
    # Create package file
    cp -f $template $package
    # Create libraries
    comma=""; for i in */; do write_library $i $libraries $comma && comma=","; done
    # Create targets that define each library's dependencies and resources
    comma=""; for i in */; do write_target $i $targets $comma && comma=","; done
    # Create binary targets
    if [[ -n $local_dist ]]; then
        echo "Creating local Package.swift for testing..."
        # Create locally pathed binary targets, useful for testing/validating
        comma=""; for i in $dist/*.xcframework; do write_local_binary $i $local_dist $binaries $comma && comma=","; done
    else
        echo "Creating release Package.swift..."
        # Create remote binary targets, these will be hosted on a github release
        comma=""; for i in $dist/*.xcframework.zip; do write_binary $i $repo $latest $binaries $comma && comma=","; done
    fi
    # Replace the templates with the generated values
    template_replace $package "// GENERATE LIBRARIES" $libraries; rm -f $libraries
    template_replace $package "// GENERATE TARGETS" $targets; rm -f $targets
    template_replace $package "// GENERATE BINARIES" $binaries; rm -f $binaries
}

find_and_extract_firebase_zip() {
    echo "Looking for downloaded Firebase zip..."
    
    # Find the zip file and ensure it's called Firebase.zip
    zip_file=$(find . -name "*.zip" | head -n 1)
    
    if [ -n "$zip_file" ]; then
        echo "Found downloaded zip file: $zip_file"
        if [[ $zip_file != "./Firebase.zip" ]]; then mv "$zip_file" "Firebase.zip"; fi
        unzip -q Firebase.zip
    else
        echo "No downloaded zip file found in root directory. Exiting."
        exit 1
    fi
    
    # If there's no Firebase folder at the root, look for a relevant zip file and unzip it
    if [ ! -d "Firebase" ]; then
        echo "Firebase directory not found in root. Looking for zip file in subdirectories..."
        # Look for Firebase zip files in subdirectories (excluding carthage)
        for dir in */; do
            if [ -d "$dir" ] && [ "$dir" != "carthage/" ]; then
                firebase_zip=$(find "$dir" -name "Firebase*.zip" | head -n 1)
                if [ -n "$firebase_zip" ]; then
                    echo "Found Firebase zip in $dir: $firebase_zip"
                    unzip -q "$firebase_zip"
                    break
                fi
            fi
        done
        # Did we find the right Firebase directory?
        if [ ! -d "Firebase" ]; then
            echo "Firebase directory not found in any subdirectory. Exiting."
            exit 1
        fi
    fi
    
    echo "Firebase zip found and extracted successfully"
}

download_firebase_zip () {
    local version=$1
    # GitHub records a sha256 digest for every release asset at upload time.
    # Fail closed when it is missing or does not match the downloaded file.
    local expected=$(gh api "repos/$firebase_repo/releases/tags/$version" \
        --jq '.assets[] | select(.name == "Firebase.zip") | .digest' | sed 's/^sha256://')
    if [[ -z $expected ]]; then
        echo "No sha256 digest published for Firebase.zip $version. Exiting."
        exit 1
    fi
    gh release download "$version" --pattern 'Firebase.zip' --repo $firebase_repo
    local actual=$(sha256sum Firebase.zip 2>/dev/null || shasum -a 256 Firebase.zip)
    actual=${actual%% *}
    if [[ $actual != "$expected" ]]; then
        echo "Firebase.zip sha256 $actual does not match the published digest $expected. Exiting."
        exit 1
    fi
    echo "Firebase.zip $version sha256 $actual matches the published digest"
    firebase_zip_sha256=$actual
}

release_tag () {
    # Our builds carry a suffix so they never collide with tags copied from the
    # community mirror before we built our own (12.16.0, 12.19.3 and older).
    echo "$1-triumph.1"
}

pending_versions () {
    # Firebase releases at or above the floor that we have not published yet.
    local published=$(gh release list --repo $xcframeworks_repo --limit 100 --json tagName --jq '.[].tagName')
    gh release list --repo $firebase_repo --limit 20 --exclude-drafts --exclude-pre-releases \
        --json tagName --jq '.[].tagName' |
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' |
    while read -r version; do
        if [[ $(printf '%s\n%s\n' "$version_floor" "$version" | sort -V | head -1) != "$version_floor" ]]; then continue; fi
        if echo "$published" | grep -qxF "$(release_tag $version)"; then continue; fi
        echo "$version"
    done | sort -V
}

build_version () {
    local version=$1
    latest=$(release_tag $version) # write_binary reads $latest as the release tag
    local distribution="dist"
    local sources="Sources"
    local package="Package.swift"
    echo "Building Firebase $version as $latest..."

    # Generate files in a temporary directory
    # Use subshell to return to original directory when finished with scratchwork
    create_scratch
    (
        cd $scratch
        echo "Downloading Firebase $version..."
        download_firebase_zip $version
        echo "$firebase_zip_sha256" > firebase_zip_sha256
        find_and_extract_firebase_zip
        echo "Preparing xcframeworks for distribution..."
        cd Firebase
        rename_frameworks "_"
        zip_frameworks
        echo "Creating distribution files..."
        prepare_files_for_distribution "../$distribution"
        echo "Creating source files..."
        generate_sources "../$sources"
        if [[ $(uname) == Darwin ]]; then
            # Create test package using local binaries and make sure it builds
            generate_swift_package "../$package" "$scripts/package_template.swift" "../$distribution" $xcframeworks_url $distribution
            echo "Validating..."
            (cd ..; swift package dump-package > /dev/null)
            (cd ..; swift build)
        fi
        # Create release package using remote binaries and make sure the Package.swift file is parseable
        generate_swift_package "../$package" "$scripts/package_template.swift" "../$distribution" $xcframeworks_url ''
        echo "Validating..."
        (cd ..; swift package dump-package > /dev/null)
    )

    echo "Moving files to repo..."
    cd "$repo_root"
    git checkout -q -f --detach "$base_commit"
    rm -rf "$sources" "$package"
    cp -R "$scratch/$sources" "$sources"
    cp "$scratch/$package" "$package"

    if [[ $dry_run ]]; then
        echo "Dry run: built $latest in $repo_root, nothing pushed."
        rm -rf "$scratch"
        return
    fi

    echo "Publishing $latest..."
    local branch="release/$latest"
    git checkout -q -b "$branch"
    git add -A "$sources" "$package"
    git commit -q -m "Package Firebase $version from Google's Firebase.zip (sha256 $(cat $scratch/firebase_zip_sha256))"
    git push -q origin "$branch"
    git tag "$latest"
    git push -q origin "$latest"
    {
        echo "Firebase $version, packaged from Google's official Firebase.zip."
        echo
        echo "- Source: https://github.com/firebase/firebase-ios-sdk/releases/tag/$version"
        echo "- Firebase.zip sha256: $(cat $scratch/firebase_zip_sha256)"
        echo "- The zips are reproducible: re-run \`.scripts/package.sh --dry-run $version\` and compare checksums with Package.swift."
    } > "$scratch/notes.md"
    gh release create "$latest" --repo $xcframeworks_repo --verify-tag --title "Firebase $version" \
        --notes-file "$scratch/notes.md" $scratch/dist/*.xcframework.zip
    echo "Published $latest"
    rm -rf "$scratch"
}

# Exit when any command fails
set -e
set -o pipefail

# Repos
firebase_repo="firebase/firebase-ios-sdk"
xcframeworks_repo="${GITHUB_REPOSITORY:-triumpharcade/firebase-ios-sdk-xcframeworks}"
xcframeworks_url="https://github.com/$xcframeworks_repo"
# Oldest Firebase version we build; earlier tags came from the community mirror
version_floor="12.19.3"

scripts=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$scripts/.." && pwd)
base_commit=$(git -C "$repo_root" rev-parse HEAD)

# Args: [--dry-run] [<firebase version>]
dry_run=""
requested=""
for arg in "$@"; do
    case $arg in
        --dry-run) dry_run=1 ;;
        *) requested=$arg ;;
    esac
done

if [[ -n $requested ]]; then
    versions=$requested
else
    versions=$(pending_versions)
fi

if [[ -z $versions ]]; then
    echo "Up to date: every Firebase release since $version_floor is published."
    exit 0
fi

for version in $versions; do
    build_version $version
done

echo "Done."
