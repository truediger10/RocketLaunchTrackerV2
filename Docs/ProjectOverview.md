# RocketLaunchTrackerV2 — General Overview

## Mission & Scope
RocketLaunchTrackerV2 is a SwiftUI-based iOS app targeting **iOS 18** (built and tested with **Xcode 16+**). It focuses on:
- Fetching and displaying rocket launch data (dates, providers, mission details).
- Enhancing info with optional AI-based enrichment (e.g., “missionOverview,” “insights”).
- Maintaining a sleek, consistent UI inspired by modern spaceflight aesthetics.

## Key Principles
1. **SwiftUI First**  
   We leverage SwiftUI for core UI, focusing on concurrency (async/await) where possible. 
2. **Data-Driven**  
   - We fetch raw data from space APIs (e.g., SpaceDevs).
   - We store or enrich that data with local caching and optional AI calls.
3. **User-Centric UI**  
   - Emphasis on readable, visually appealing views.
   - Follows a dark theme, minimalistic design.

## Documents & References
1. **ImageStandardization.md**  
   - Defines how images are loaded, cached, and styled consistently.
   - Explains gradient overlays, fallback states, best practices for dimension handling.
2. **GrokStyleGuide.md**  
   - Summarizes color palette, typography, spacing, corner radii, etc.
3. **Other Files**  
   - `Styles.swift`: Central place for constants (cornerRadiusMedium, launchCardImageHeight, etc.).
   - `AIService.swift`: Where we handle GPT-based enrichment calls.

## High-Level Architecture
1. **Views**  
   - SwiftUI screens: LaunchListView, LaunchDetailView, SettingsView, etc.
2. **ViewModels**  
   - `LaunchViewModel`, etc. to manage data fetching and state.
3. **Models**  
   - `Launch`, `Rocket`, possibly an `Enrichment` struct for AI-generated fields.
4. **Additional Services**  
   - `NotificationManager`, `CacheManager`, `NetworkLayer`, etc.

## Style & UX 
- Dark backgrounds, bright accents for highlights.
- Minimal gradients, device-agnostic layouts.
- Cohesive brand identity (consistent corner radii, padding).
- See `GrokStyleGuide.md` for more details. 
- See `ImageStandardization.md` for image handling specifics.
- See `Styles.swift` for shared constants.

## Updating This Document
- Keep it broad; only update if major new features or pivots occur.
- Link to new docs as needed.
- Keep it concise and high-level.
- Update the version number at the top.

## GitHub Info
- Main repo for the project. https://github.com/truediger10/RocketLaunchTrackerV2
