# Malieum · SpeechBridge Branding

[한국어](README.md) | [English](README.en.md) | [All documents](../README.en.md)

- Korean name: **말이음**
- English name: **SpeechBridge**
- Korean description: **마비말장애 말하기 연습**
- English description: **Speech Practice for Adults with Dysarthria**
- Korean tagline: **생활에 필요한 말, 내 속도로 연습해요.**
- English tagline: **Everyday words, at your own pace.**

## Scope

The in-app title and startup screen follow the app language setting. iOS, Android, and macOS launcher names follow the device language: Korean “말이음,” with “SpeechBridge” as the English default. Changing the in-app language does not rename the OS launcher. The web installation name is SpeechBridge; the full introductory name is “말이음 · SpeechBridge.” Default Windows/Linux window titles are SpeechBridge.

Updated iOS, Android, macOS, web, and Windows icons; the Linux window icon; the startup icon; and brand names in the README, promotional document, and user guides. Package names, bundle IDs, and storage keys remain unchanged. The macOS build output is now SpeechBridge.app.

## Icon source and regeneration

[Vector source](../../assets/branding/app-icon.svg) · [Preview](../../assets/branding/app-icon.png)

A deep-teal background, light speech bubble, and three rounded sound bars. No lettering is included, so the shape remains recognizable at small sizes. The bars do not represent a score or improvement chart.

Run `tools/branding/generate_icons.cjs` with Node.js and sharp installed to generate platform PNGs. iOS uses an opaque square; macOS and legacy Android icons use a rounded shape; web maskable icons shrink the symbol into the safe area. Windows ICO was exported from the same PNG using Pillow's ICO support with 16, 24, 32, 48, 64, 128, and 256px sizes.

Trademark registration, app-store release, and name-conflict checks are not part of this change.

## Validation

Flutter static analysis and two startup/language-setting tests passed. After a successful macOS debug build, verified the executable name, unchanged bundle ID, Korean/English InfoPlist resources, and bundled icon. iOS, Android, Windows, and Linux settings/assets were changed, but their physical-device builds/runs were not verified.
