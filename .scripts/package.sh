#!/bin/bash

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
    # Run cleanup on exit
    trap "rm -rf \"$scratch\"" EXIT
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
    # A draft left by an interrupted upload does not count as published.
    local published
    published=$(gh release list --repo $xcframeworks_repo --limit 100 --exclude-drafts \
        --json tagName --jq '.[].tagName') || { echo "Cannot list $xcframeworks_repo releases. Exiting." >&2; exit 1; }
    local releases
    releases=$(gh release list --repo $firebase_repo --limit 20 --exclude-drafts --exclude-pre-releases \
        --json tagName --jq '.[].tagName') || { echo "Cannot list $firebase_repo releases. Exiting." >&2; exit 1; }
    echo "$releases" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' |
    while read -r version; do
        if [[ $(printf '%s\n%s\n' "$version_floor" "$version" | sort -V | head -1) != "$version_floor" ]]; then continue; fi
        if echo "$published" | grep -qxF "$(release_tag $version)"; then continue; fi
        echo "$version"
    done | sort -V
}

publish_version () {
    local version=$1
    local sources="Sources"
    local package="Package.swift"
    local branch="release/$latest"

    if git -C "$repo_root" ls-remote --exit-code --tags origin "refs/tags/$latest" > /dev/null; then
        # An earlier run pushed the tag but did not finish the release. The
        # build is reproducible, so the rebuilt manifest must match the tag's.
        echo "Tag $latest exists. Checking it matches this build..."
        git -C "$repo_root" fetch -q --depth 1 origin "refs/tags/$latest:refs/tags/$latest"
        if ! git -C "$repo_root" show "$latest:$package" | cmp -s - "$scratch/$package"; then
            echo "Tag $latest holds a different Package.swift than this build. Exiting."
            exit 1
        fi
        local is_draft
        is_draft=$(gh release view "$latest" --repo $xcframeworks_repo --json isDraft --jq .isDraft 2>/dev/null || echo missing)
        if [[ $is_draft == false ]]; then
            echo "$latest is already published. Nothing to do."
            return
        fi
        if [[ $is_draft == true ]]; then
            echo "Removing the unfinished draft release for $latest..."
            gh release delete "$latest" --repo $xcframeworks_repo --yes
        fi
    else
        # Commit in a throwaway worktree so the caller's checkout is never touched
        local tree="$scratch/tree"
        git -C "$repo_root" worktree add -q --detach "$tree" "$base_commit"
        (
            cd "$tree"
            rm -rf "$sources" "$package"
            cp -R "$scratch/$sources" "$sources"
            cp "$scratch/$package" "$package"
            git checkout -q -b "$branch"
            git add -A "$sources" "$package"
            git commit -q -m "Package Firebase $version from Google's Firebase.zip (sha256 $(cat $scratch/firebase_zip_sha256))"
            git tag "$latest"
            # Branch and tag land together or not at all
            git push -q --atomic origin "$branch" "$latest"
        )
        git -C "$repo_root" worktree remove --force "$tree"
    fi

    {
        echo "Firebase $version, packaged from Google's official Firebase.zip."
        echo
        echo "- Source: https://github.com/firebase/firebase-ios-sdk/releases/tag/$version"
        echo "- Firebase.zip sha256: $(cat $scratch/firebase_zip_sha256)"
        echo "- The zips are reproducible: \`bash .scripts/package.sh --dry-run $version\` rebuilds them; the checksums must match Package.swift."
    } > "$scratch/notes.md"
    gh release create "$latest" --repo $xcframeworks_repo --verify-tag --title "Firebase $version" \
        --notes-file "$scratch/notes.md" $scratch/dist/*.xcframework.zip
    echo "Published $latest"
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

    if [[ $dry_run ]]; then
        # Leave the result outside git so a dry run never touches the checkout
        local out="$repo_root/dry-run/$latest"
        rm -rf "$out"; mkdir -p "$out"
        cp -R "$scratch/$sources" "$scratch/$package" "$out"
        echo "Dry run: built $latest into $out, nothing pushed."
    else
        echo "Publishing $latest..."
        publish_version $version
    fi
    rm -rf "$scratch"
}

# Exit when any command fails
set -e
set -o pipefail
# Byte-for-byte the same manifest on every machine (glob and ls order)
export LC_ALL=C

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
        *)
            if [[ ! $arg =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "Not a Firebase version: $arg. Usage: package.sh [--dry-run] [X.Y.Z]"
                exit 1
            fi
            requested=$arg ;;
    esac
done

if [[ -n $requested ]]; then
    build_version $requested
    echo "Done."
    exit 0
fi

mark_pulled_releases () {
    # A Firebase release Google pulled (deleted, or turned into a pre-release
    # or draft) stays here for the record but is marked pre-release, so
    # frontend-monorepo's bump job never picks it.
    local live
    live=$(gh release list --repo $firebase_repo --limit 100 --exclude-drafts --exclude-pre-releases \
        --json tagName --jq '.[].tagName') || { echo "Cannot list $firebase_repo releases. Exiting." >&2; exit 1; }
    local ours
    ours=$(gh release list --repo $xcframeworks_repo --limit 100 --exclude-drafts --exclude-pre-releases \
        --json tagName --jq '.[].tagName') || { echo "Cannot list $xcframeworks_repo releases. Exiting." >&2; exit 1; }
    local oldest_live
    oldest_live=$(echo "$live" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | head -1) || true
    if [[ -z $oldest_live ]]; then echo "No live $firebase_repo releases listed. Exiting." >&2; exit 1; fi
    echo "$ours" | grep -E -- '-triumph\.[0-9]+$' | while read -r tag; do
        local version=${tag%%-triumph.*}
        # Only judge versions inside the window the upstream list covers
        if [[ $(printf '%s\n%s\n' "$oldest_live" "$version" | sort -V | head -1) != "$oldest_live" ]]; then continue; fi
        if ! echo "$live" | grep -qxF "$version"; then
            echo "Firebase $version is no longer a live release upstream. Marking $tag as a pre-release."
            gh release edit "$tag" --repo $xcframeworks_repo --prerelease
        fi
    done
}

if [[ -z $dry_run ]]; then
    mark_pulled_releases
fi

versions=$(pending_versions)
if [[ -z $versions ]]; then
    echo "Up to date: every Firebase release since $version_floor is published."
    exit 0
fi

# Build each version in its own process: set -e stays in force inside it, and
# one failed version does not block the newer ones. The run still fails at the
# end when any version failed, so the failure shows in Actions.
failed=""
for version in $versions; do
    bash "$0" ${dry_run:+--dry-run} "$version" || failed="$failed $version"
done
if [[ -n $failed ]]; then
    echo "Failed to build:$failed"
    exit 1
fi
echo "Done."
