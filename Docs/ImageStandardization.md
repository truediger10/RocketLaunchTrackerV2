# RocketLaunchTrackerV2: Image Standardization Documentation

## Overview

The image standardization system in RocketLaunchTrackerV2 provides consistent image presentation throughout the app. It handles loading, caching, styling, and fallback states for images in various contexts such as launch cards, detail views, and rocket galleries.

## Key Components

### 1. `StandardLaunchImage`

The primary component for displaying images with predefined styles. It abstracts the complexity of image styling and provides a consistent API.

```swift
StandardLaunchImage(
    launchId: "unique-id",
    url: someImageURL,
    style: .launchCard,  // Choose from predefined styles
    fallbackMessage: "Custom message when image unavailable"
)
```

### 2. `CachedAsyncImage`

Handles asynchronous image loading with caching and provides loading/error states.

### 3. `LaunchImageLoader`

Manages image downloading and memory caching, preventing redundant network requests.

### 4. `CacheManager`

Provides disk-based caching to persist images between app launches.

## Image Styles

The system supports several predefined styles through the `ImageStyle` enum:

| Style | Usage | Dimensions | Special Features |
|-------|-------|------------|-----------------|
| `.launchCard` | In launch list items | Height: `Styles.launchCardImageHeight` | Standard gradient overlay |
| `.detailView` | In detail screens | Height: `Styles.detailImageHeight` | Enhanced gradient overlay |
| `.rocketCard` | In rocket galleries | Width: `Styles.rocketCardWidth`<br>Height: `Styles.rocketCardHeight` | Standard gradient overlay |
| `.preferenceView` | In preference views | Height: `Styles.preferenceImageHeight` | Standard gradient overlay |
| `.custom(height, width, aspectRatio)` | For custom needs | Custom dimensions | Standard gradient overlay |

## Implementation Details

### Container Structure

The image component uses a multi-layer structure:

```
GeometryReader
└── ZStack (alignment: .bottom)
    ├── CachedAsyncImage (actual image content)
    └── Gradient Overlay (conditional)
```

### GeometryReader Usage

`GeometryReader` is used at multiple levels to ensure:
1. Images respect their container boundaries
2. Gradient overlays align precisely with image edges
3. Consistent dimensions across different device sizes

### Gradient Overlays

Two types of gradient overlays are used:

1. **Standard Overlay**: Applied to most image styles
   ```swift
   LinearGradient(
       gradient: Gradient(colors: [
           Color.black.opacity(0.8),
           Color.black.opacity(0.5),
           Color.black.opacity(0.2),
           Color.clear
       ]),
       startPoint: .bottom,
       endPoint: .top
   )
   ```

2. **Enhanced Overlay**: Used in detail views
   ```swift
   LinearGradient(
       gradient: Gradient(colors: [
           Color.black.opacity(0.8),
           Color.black.opacity(0.5),
           Color.black.opacity(0.2),
           Color.clear
       ]),
       startPoint: .bottom,
       endPoint: .center
   )
   ```

### Fallback Views

When images fail to load, fallback views are displayed with:
- Consistent styling matching the requested image style
- Custom message support
- Appropriate icon
- Matching gradient overlay (if applicable)

## Best Practices

### 1. Using StandardLaunchImage

Always use `StandardLaunchImage` rather than direct `Image` views for consistency:

```swift
// CORRECT
StandardLaunchImage(
    launchId: launch.id,
    url: launch.image,
    style: .launchCard
)

// INCORRECT
Image(uiImage: someImage)
    .resizable()
    .aspectRatio(contentMode: .fill)
```

### 2. Container Management

When using `StandardLaunchImage` within complex layouts, ensure proper container management:

```swift
// In list views or cards
GeometryReader { geometry in
    StandardLaunchImage(
        launchId: launch.id,
        url: launch.image,
        style: .launchCard
    )
    .frame(width: geometry.size.width)
}
.frame(height: Styles.launchCardImageHeight)
```

### 3. Padding Consistency

Apply padding to the container of `StandardLaunchImage`, not to the component itself:

```swift
// CORRECT
VStack {
    StandardLaunchImage(...)
}
.padding(.horizontal, 20)

// INCORRECT
VStack {
    StandardLaunchImage(...)
        .padding(.horizontal, 20)
}
```

## Common Issues and Fixes

### 1. Images Overflowing Containers

**Issue**: Images extend beyond their intended boundaries.

**Fix**: Wrap in GeometryReader and apply frame constraints:
```swift
GeometryReader { geometry in
    StandardLaunchImage(...)
    .frame(width: geometry.size.width)
}
.frame(height: desiredHeight)
```

### 2. Misaligned Gradient Overlays

**Issue**: Gradient overlay doesn't align with the bottom of the image.

**Fix**: Ensure proper ZStack alignment and check overlay positioning:
```swift
ZStack(alignment: .bottom) {
    // Image content
    
    // Gradient at bottom
    VStack {
        Spacer()
        gradientView
    }
}
```

### 3. Inconsistent Aspect Ratios

**Issue**: Images appear stretched or squished.

**Fix**: Verify the `contentMode` parameter (default is `.fill`):
```swift
StandardLaunchImage(
    launchId: id,
    url: url,
    style: style,
    contentMode: .fit  // Change to .fit if needed
)
```

## Extending the System

### Adding a New Image Style

1. Add a new case to the `ImageStyle` enum in `StandardLaunchImage`:
```swift
enum ImageStyle {
    // Existing styles
    case newStyle
    
    // Update computed properties
    var dimensions: (height: CGFloat, width: CGFloat?, cornerRadius: CGFloat) {
        switch self {
            // Existing cases
            case .newStyle:
                return (height: 100, width: 200, cornerRadius: Styles.cornerRadiusMedium)
        }
    }
    
    var usesEnhancedGradient: Bool {
        switch self {
            // Existing cases
            case .newStyle:
                return false
        }
    }
}
```

2. Update the global style constants in `Styles.swift`:
```swift
// Add constants for the new style
static let newStyleHeight: CGFloat = 100
static let newStyleWidth: CGFloat = 200
```

## Performance Considerations

1. **Memory Usage**: Images are cached in memory for quick access but will be purged under memory pressure.

2. **Disk Cache**: Images are stored on disk to persist between app launches, with automatic cleanup for old entries.

3. **Preloading**: Critical images (e.g., upcoming launches) are preloaded to improve perceived performance.

4. **Progressive Loading**: Consider adding a resizing pipeline to load lower resolution thumbnails first for large lists.

## Testing Image Handling

Test image standardization in these scenarios:

1. **Poor Network Conditions**: Slow or intermittent connectivity
2. **Missing Images**: URLs that return 404 errors
3. **Various Device Sizes**: Particularly narrow screens and iPads
4. **Memory Pressure**: System memory warnings
5. **Dark/Light Mode**: If your app supports light mode
