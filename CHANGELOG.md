# Changelog

I will attempt to document all notable changes to this project in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [2.5.2] - 2022-01-05

### Fixed

- Better parsing of default values for arrays and structs

## [2.5.0] - 2021-03-24

### Added

- Parameter `attemptMerge` which attempts to merge the generated CFC function documentation into the existing documentation file. Use with caution and inspect resulting file.

## [2.0.0] - 2021-01-26

### Added

- A changelog
- Parameter `methodOrder` which determines the order in which the functions are output

### Changed

- Order of parameters changed, with the addition of `methodOrder`. It was placed before `generateFile`. If calling the command with positional arguments, including `generateFile`, you may need to refactor.

## [1.0.3] - 2020-11-23

### Added

- Initial release
