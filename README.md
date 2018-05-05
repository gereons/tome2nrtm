# TOME2NRTM

TOME2NRTM is a converter from TOME export files to NRTM json files, so that you can upload them to ABR.

Let me unwrap those acronyms:

[TOME](https://www.fantasyflightgames.com/en/more/organized-play/tome/) is the browser-based "Tournament Organizer Management Engine" by [Fantasy Flight Games](https://www.fantasyflightgames.com), suitable for running tournaments for the competitive games sold by FFG.

[NRTM](https://itunes.apple.com/app/nrtm/id695468874) is the "NetRunner Tournament Manager" app for iOS that I wrote specifically to support running [Android: Netrunner](https://www.fantasyflightgames.com/en/products/android-netrunner-the-card-game/) tournaments.

NRTM has built-in export capabilities that produce data about a tournament in a structured JSON format, according to [this schema](http://steffens.org/nrtm/nrtm-schema.json).

[ABR](https://alwaysberunning.net) is a fan-run website that tries to collect information about as many Netrunner tournaments as possible, and NRTM can upload its data directly to this website.

TOME, unfortunately, lacks such a feature. This is where TOME2NRTM comes in: you can take the export data that TOME generates, convert it to a format that ABR understands, namely NRTM's json, and then upload the result to ABR.

## Building and running

TOME2NRTM is written in Swift 4.1, this means you can run it either on a Mac (free download of Apple's development platform, Xcode 9.3 (or newer) is required), or on any Linux system that has either [Docker](https://docker.io) or the [current snapshot](https://swift.org/download/#snapshots) of the Swift tools for Linux installed.

### on a Mac

* clone this repo
* `cd tome2nrtm`
* `swift build`
* this produces a binary that you can run using `./.build/debug/tome2nrtm`
* or, run with `swift run tome2nrtm inputfile`

If you want to play with TOME2NRTM in Xcode, you can let the Swift Package Manager create an Xcode project for you by running `swift package generate-xcodeproj`.

### on Linux, using Docker

* clone this repo
* `cd tome2nrtm`
* `docker build -t tome2nrtm .`
* `docker run --rm -ti -v /path/to/your/tome-file.txt:/tome.txt tome2nrtm /tome.txt`  

### before you get started...

Please note that ABR has pretty strict requirements about what it expects in its input files. Players **must** have valid factions and identities, and while ABR understands things like "Reina" or "Palana", it does not know what "ETF" or "CTM" are supposed to mean.

Also note that TOME has no way of keeping track of which side won a game, whereas NRTM does make a distinction between "runner split" and "corp split". The converter simply assigns match points starting with the runner side, i.e. all 3:3 results are recorded as runner splits.
