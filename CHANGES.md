# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
except that the first subsection is called `New` rather than `Added`. The release
workflow matches on `### New`; renaming it silently drops the section from the
release notes.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### New
- Each release ships `.deb`, `.rpm` and `.apk` packages for Debian 12 and 13, Ubuntu 22.04, 24.04 and 26.04, AlmaLinux 9 and 10, Fedora and Alpine 3.23 and 3.24, published to the package registry at gitea.oetiker.ch (owner `oposs`), and a source tarball. The package installs the service under `/opt/upload-service` and puts an example systemd unit under `/usr/share/doc/upload-service/examples/`.

### Changed
- `./configure` without `--prefix` installs to `/opt/upload-service` instead of `/opt/upload-service-<version>`.
- Only Mojolicious is bundled, at the current version on CPAN when the release is built. Mojo::Server::FastCGI and IO::Socket::SSL are no longer bundled; a service that listens on `https://` itself needs IO::Socket::SSL from the distribution (`libio-socket-ssl-perl`, `perl-IO-Socket-SSL`), which the packages recommend.
- The build downloads cpanminus over https instead of http, and curl no longer accepts an invalid certificate.

### Fixed
- An installation built from a git checkout showed version 0.0.0 at the bottom right of the upload page; it now shows the version it was built from.
- `make install` without `PERL5LIB` set no longer edits `bin/us.pl` in the source tree.

## 0.5.3 - 2026-10-23
### New
- The running version is shown at the bottom right of the upload page.

### Changed
- The upload page follows the browser language (German, French, English) and shows "Upload files" instead of "INBOX Account's INBOX".

## 0.5.2 - 2026-10-23
### Changed
- Rejected requests and finished uploads are logged with reason, client address and tag.

### Fixed
- File names with umlauts, brackets, "&" and similar characters are stored with those characters replaced instead of being rejected; before, the upload page retried such a file forever without showing an error.

## 0.4.0 - 2016-06-21
### New
- `US_TAGMODE` selects tag mode.

### Changed
- The build uses a new configure.
