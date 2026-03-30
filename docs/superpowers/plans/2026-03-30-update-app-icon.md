# Update App Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current app icon with the new `FDL_icon.png`.

**Architecture:** Update the `AppIcon.appiconset` asset catalog by generating the required icon sizes and updating the `Contents.json` file.

**Tech Stack:** macOS `sips` tool for image processing, Swift/Xcode asset catalog.

---

### Task 1: Generate Icon Sizes

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-1024.png`
- Create: `FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-512.png`
- Create: `FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-256.png`
- Create: `FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-128.png`
- Create: `FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-64.png`
- Create: `FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-32.png`
- Create: `FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-16.png`

- [ ] **Step 1: Resize and save icon images**

```bash
sips -z 1024 1024 FDL_icon.png --out FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-1024.png
sips -z 512 512 FDL_icon.png --out FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-512.png
sips -z 256 256 FDL_icon.png --out FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-256.png
sips -z 128 128 FDL_icon.png --out FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-128.png
sips -z 64 64 FDL_icon.png --out FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-64.png
sips -z 32 32 FDL_icon.png --out FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-32.png
sips -z 16 16 FDL_icon.png --out FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/icon-16.png
```

- [ ] **Step 2: Commit**

```bash
git add FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/*.png
git commit -m "feat: generate app icon sizes from FDL_icon.png"
```

### Task 2: Update Contents.json

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] **Step 1: Update Contents.json with new image filenames**

```json
{
  "images" : [
    {
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "tinted"
        }
      ],
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "filename" : "icon-16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon-32.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon-32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon-64.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon-128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon-256.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon-256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon-512.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon-512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon-1024.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 2: Verify build**

Run: `xcodebuild -scheme FitnessDeviceLab -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add FitnessDeviceLab/FitnessDeviceLab/Assets.xcassets/AppIcon.appiconset/Contents.json
git commit -m "feat: update AppIcon Contents.json with new icon filenames"
```
