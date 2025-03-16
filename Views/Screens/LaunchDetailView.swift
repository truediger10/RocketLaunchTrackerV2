import SwiftUI
import MapKit

/// A detailed screen showing comprehensive information about a single launch, including images, maps, and enrichment.
struct LaunchDetailView: View {
    private let id: String
    @ObservedObject var viewModel: LaunchViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Local UI state
    @State private var cachedImageData: Data?
    @State private var isFavorite: Bool
    @State private var notificationsEnabled: Bool
    @State private var expandedSection: String? = "insights"
    @State private var showShareSheet = false
    @State private var dragOffset: CGFloat = 0
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
    )
    @State private var showCopiedFeedback: Bool = false
    @State private var copiedText: String = ""
    @State private var showMap: Bool = false
    
    /// Initialize with a known launch object to avoid repeated fetches.
    init(launch: Launch, viewModel: LaunchViewModel) {
        self.id = launch.id
        self.viewModel = viewModel
        self._isFavorite = State(initialValue: launch.isFavorite)
        self._notificationsEnabled = State(initialValue: launch.notificationsEnabled)
    }
    
    /// Retrieves the latest state of the launch from the view model, or uses a placeholder if not found.
    private var launch: Launch {
        if let foundLaunch = viewModel.launches.first(where: { $0.id == id }) {
            return foundLaunch
        } else {
            // Provide a fallback if the launch isn't in the current list
            return Launch(
                id: id,
                name: "Unknown Mission",
                net: Date(),
                provider: "Unknown",
                location: "Unknown",
                padLatitude: nil,
                padLongitude: nil,
                missionOverview: nil,
                insights: nil,
                image: nil,
                rocketName: "Unknown Rocket",
                isFavorite: false,
                notificationsEnabled: false,
                status: nil,
                missionName: "Unknown Mission",
                probability: nil,
                url: nil,
                slug: nil,
                launchDesignator: nil,
                windowStart: nil,
                windowEnd: nil,
                webcastLive: nil,
                mission: nil
            )
        }
    }
    
    /// A helper for formatting and retrieving data about the launch.
    private var info: LaunchInfoDisplay {
        LaunchInfoDisplay(launch: launch)
    }
    
    var body: some View {
        ZStack {
            // Background
            Styles.spaceBackgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: Styles.spacingLarge) {
                    // Launch image with standardized styling
                    GeometryReader { geometry in
                        ZStack(alignment: .bottom) {
                            LaunchImageView(
                                launchId: launch.id,
                                url: launch.image,
                                style: .detailView,
                                fallbackMessage: "Image Unavailable"
                            )
                            .frame(width: geometry.size.width)
                            
                            // Gradient overlay at bottom
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.7),
                                    Color.black.opacity(0)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 120)
                            
                            // Mission name and provider overlaid on image
                            VStack(alignment: .leading, spacing: Styles.spacingTiny) {
                                Text(info.missionName)
                                    .font(Styles.titleFont)
                                    .foregroundColor(Styles.textPrimary)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                
                                Text(info.provider)
                                    .font(Styles.bodyFont)
                                    .foregroundColor(Styles.textSecondary)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Styles.paddingStandard)
                        }
                    }
                    .frame(height: 260)
                    
                    // Countdown timer - Made more prominent
                    ZStack {
                        RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                            .fill(Color.black.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                .stroke(Styles.primaryAccent.opacity(0.3), lineWidth: Styles.hairlineBorder)
                            )
                            .shadow(color: Styles.primaryAccent.opacity(0.1), radius: 10, x: 0, y: 4)
                            
                        CountdownTimer(targetDate: launch.net, isCompact: false, enablePulseUnderOneHour: true)
                            .padding(.vertical, Styles.paddingSmall)
                    }
                    .padding(.horizontal, Styles.paddingStandard)
                    .padding(.top, Styles.paddingMedium)
                    
                    // Launch details
                    VStack(alignment: .leading, spacing: Styles.spacingMedium) {
                        sectionHeader(title: "DETAILS", icon: "info.circle.fill")
                        
                        VStack(spacing: Styles.spacingMedium) {
                            detailRow(icon: "calendar", label: "Date", value: info.launchDate)
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                            
                            detailRow(icon: "clock", label: "Time", value: info.launchTime)
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                            
                            detailRow(icon: "paperplane", label: "Vehicle", value: info.rocketType)
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                            
                            // Location row with map icon
                            HStack(spacing: Styles.spacingMedium) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(Styles.primaryAccent)
                                    .frame(width: 20)
                                
                                Text("Location")
                                    .font(Styles.bodyFont)
                                    .foregroundColor(Styles.textSecondary)
                                    .frame(width: 80, alignment: .leading)
                                
                                Text(info.location)
                                    .font(Styles.bodyFont)
                                    .foregroundColor(Styles.textPrimary)
                                
                                Spacer()
                                
                                // Map button - only show if coordinates are available
                                if launch.padLatitude != nil && launch.padLongitude != nil {
                                    Button(action: {
                                        showMap = true
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }) {
                                        Image(systemName: "map")
                                            .foregroundColor(Styles.primaryAccent)
                                            .font(.system(size: Styles.iconSizeSmall))
                                            .frame(width: 30, height: 30)
                                            .background(
                                                Circle()
                                                    .fill(Styles.primaryAccent.opacity(0.1))
                                            )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                            
                            if let probability = launch.probability {
                                HStack(spacing: Styles.spacingMedium) {
                                    Image(systemName: "percent")
                                        .foregroundColor(Styles.primaryAccent)
                                        .frame(width: 20)
                                    
                                    Text("Probability")
                                        .font(Styles.bodyFont)
                                        .foregroundColor(Styles.textSecondary)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    // Enhanced probability display
                                    HStack(spacing: Styles.spacingTiny) {
                                        Text("\(probability)%")
                                            .font(Styles.bodyFont)
                                            .foregroundColor(Styles.textPrimary)
                                        
                                        // Progress bar for visual representation
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Styles.cardSurface)
                                                .frame(width: 60, height: 8)
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(probabilityColor(for: probability))
                                                .frame(width: 60 * CGFloat(probability) / 100.0, height: 8)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                            }
                        }
                        .padding(Styles.paddingStandard)
                        .glassmorphicCard()
                        .animation(Styles.spring, value: info.status)
                    }
                    .padding(.horizontal, Styles.paddingStandard)
                    .padding(.top, Styles.paddingStandard)
                    
                    // ENRICHMENT DATA DISPLAY: Mission Overview Section
                    // This displays the AI-generated mission overview text
                    // The data comes from either the Grok API or fallback generation
                    if let overview = launch.missionOverview {
                        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
                            sectionHeader(title: "MISSION OVERVIEW", icon: "doc.text.fill")
                            
                            // Display in an expandable/collapsible section for better UX
                            expandableSection(
                                title: "Mission Details",
                                sectionKey: "overview",
                                content: {
                                    Text(overview)
                                        .font(Styles.bodyFont)
                                        .foregroundColor(Styles.textPrimary)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.top, Styles.paddingSmall)
                                }
                            )
                        }
                        .padding(.horizontal, Styles.paddingStandard)
                        .padding(.top, Styles.paddingStandard)
                    }
                    
                    // ENRICHMENT DATA DISPLAY: Key Insights Section
                    // This displays the AI-generated bullet points with interesting facts
                    // The insights array comes from either the Grok API or fallback generation
                    if let insights = launch.insights, !insights.isEmpty {
                        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
                            sectionHeader(title: "KEY INSIGHTS", icon: "lightbulb.fill")
                            
                            // Display in an expandable/collapsible section with consistent styling
                            expandableSection(
                                title: "Mission Insights",
                                sectionKey: "insights",
                                content: {
                                    // List all insights as bullet points
                                    VStack(alignment: .leading, spacing: Styles.spacingMedium) {
                                        ForEach(insights, id: \.self) { insight in
                                            HStack(alignment: .top, spacing: Styles.spacingSmall) {
                                                // Bullet point icon
                                                Image(systemName: "circle.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(Styles.primaryAccent)
                                                    .padding(.top, 6)
                                                
                                                // Insight text with proper wrapping
                                                Text(insight)
                                                    .font(Styles.bodyFont)
                                                    .foregroundColor(Styles.textPrimary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                    }
                                    .padding(.top, Styles.paddingSmall)
                                }
                            )
                        }
                        .padding(.horizontal, Styles.paddingStandard)
                        .padding(.top, Styles.paddingStandard)
                    }
                    
                    // Add some extra space at the bottom
                    Spacer(minLength: 50)
                }
                .offset(y: max(0, dragOffset))
            }
            .animation(Styles.easeInOut, value: expandedSection)
            // Improved gesture handling - vertical swipe to dismiss with haptic feedback
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height * 0.5
                            
                            // Add subtle haptic feedback based on drag distance
                            if dragOffset > 60 && dragOffset < 70 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 120 {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dismiss()
                        } else {
                            withAnimation(Styles.spring) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .sheet(isPresented: $showMap) {
                if let latitude = launch.padLatitude, let longitude = launch.padLongitude {
                    NavigationView {
                        ZStack {
                            Color.black.edgesIgnoringSafeArea(.all)
                            
                            VStack(spacing: 0) {
                                // Map view
                                Map(initialPosition: .region(MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                                ))) {
                                    // A marker showing the exact location
                                    Marker(launch.location, coordinate: CLLocationCoordinate2D(
                                        latitude: latitude,
                                        longitude: longitude
                                    ))
                                    .tint(Styles.primaryAccent)
                                }
                                .mapStyle(.standard(elevation: .realistic))
                                .edgesIgnoringSafeArea(.top)
                                .mapControls {
                                    MapUserLocationButton()
                                }
                                
                                // Location details panel
                                VStack(spacing: Styles.spacingMedium) {
                                    Text(launch.location)
                                        .font(.system(size: Styles.fontLarge, weight: Styles.weightMedium))
                                        .foregroundColor(Styles.textPrimary)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, Styles.paddingMedium)
                                    
                                    // Coordinates display
                                    VStack(spacing: Styles.spacingSmall) {
                                        // Latitude display
                                        coordinateDisplay(
                                            label: "LAT",
                                            value: String(format: "%.6f°", latitude),
                                            color: Styles.primaryAccent
                                        )
                                        
                                        // Longitude display
                                        coordinateDisplay(
                                            label: "LNG",
                                            value: String(format: "%.6f°", longitude),
                                            color: Styles.highlightAccent
                                        )
                                        
                                        // Copy button
                                        Button(action: {
                                            let coordString = String(format: "%.6f, %.6f", latitude, longitude)
                                            UIPasteboard.general.string = coordString
                                            withAnimation(Styles.spring) {
                                                showCopiedFeedback = true
                                                copiedText = "Coordinates copied!"
                                            }
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            
                                            // Hide the feedback after a delay
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                withAnimation {
                                                    showCopiedFeedback = false
                                                }
                                            }
                                        }) {
                                            HStack {
                                                Text("Copy Coordinates")
                                                    .font(Styles.buttonFont)
                                                    .foregroundColor(Styles.textPrimary)
                                                
                                                Image(systemName: "doc.on.doc")
                                                    .font(.system(size: Styles.iconSizeSmall))
                                                    .foregroundColor(Styles.primaryAccent)
                                            }
                                            .padding(.horizontal, Styles.paddingMedium)
                                            .padding(.vertical, Styles.paddingSmall)
                                            .background(
                                                Capsule()
                                                    .fill(Styles.cardSurface)
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                                                    )
                                            )
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                    .padding(.vertical, Styles.paddingMedium)
                                }
                                .padding(.horizontal, Styles.paddingStandard)
                                .background(Styles.baseBackground)
                            }
                        }
                        .navigationTitle("Launch Location")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showMap = false
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // ENRICHMENT DATA FLOW: This is a key part of the enrichment process
                
                // Step 1: When view appears, ensure we have at least fallback enrichment data
                // This calls viewModel.enrichSpecificLaunch which immediately provides fallback data
                // to prevent empty sections
                print("🔄 UI FLOW: LaunchDetailView appeared for launch \(id) - applying immediate fallback enrichment")
                viewModel.enrichSpecificLaunch(id: id)
                
                // Step 2: In parallel, start async process to get real enrichment data from API
                // This calls viewModel.ensureLaunchEnriched which triggers GrokService API call
                // When data arrives, the UI will update automatically through @ObservedObject
                print("🌐 UI FLOW: Starting async enrichment request for launch \(id)")
                Task {
                    await viewModel.ensureLaunchEnriched(launchId: id)
                    print("✅ UI FLOW: Async enrichment completed for launch \(id)")
                }
            }
            
            // Fixed back and action buttons
            VStack {
                HStack {
                    // Back button with better tap area
                    Button(action: {
                        dismiss()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: Styles.iconSizeMedium, weight: .semibold))
                            .foregroundColor(Styles.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Styles.elevatedSurface.opacity(0.8))
                                    .overlay(
                                        Circle()
                                            .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                                    )
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Spacer()
                    
                 // Action buttons
                    HStack(spacing: Styles.spacingMedium) {
                        // NotificationButton component
                        NotificationButton(
                            launch: launch,
                            isCompact: true,
                            onStatusChanged: { isEnabled in
                                notificationsEnabled = isEnabled
                            }
                        )
                        
                        // FavoriteButton component
                        FavoriteButton(
                            launch: launch,
                            isCompact: true,
                            onStatusChanged: { isFav in
                                isFavorite = isFav
                            }
                        )
                        
                        // ShareButton component
                        ShareButton(
                            launch: launch,
                            isCompact: true
                        )
                    }
                }
                .padding(.horizontal, Styles.paddingStandard)
                .padding(.top, 8) // Adjust based on safe area
                
                Spacer()
            }
            
            // Pull indicator at the top
            if dragOffset > 0 {
                VStack {
                    Capsule()
                        .fill(Styles.textPrimary.opacity(min(0.5, dragOffset * 0.003)))
                        .frame(width: 40, height: 5)
                        .padding(.top, Styles.paddingMedium)
                    Spacer()
                }
            }
            
            // Feedback overlay for user actions
            if showCopiedFeedback {
                VStack {
                    Spacer()
                    
                    CopyFeedbackView(text: copiedText)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, Styles.paddingLarge)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    // Action button with consistent styling
    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: Styles.iconSizeSmall))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Styles.elevatedSurface.opacity(0.8))
                        .overlay(
                            Circle()
                                .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // Standardized section header with icon
    private func sectionHeader(title: String, icon: String? = nil) -> some View {
        HStack(spacing: Styles.spacingSmall) {
            if let iconName = icon {
                Image(systemName: iconName)
                    .foregroundColor(Styles.primaryAccent)
                    .font(.system(size: Styles.fontTiny))
            }
            
            Text(title)
                .font(.system(size: Styles.fontTiny, weight: Styles.weightMedium))
                .tracking(1.2)
                .foregroundColor(Styles.textTertiary)
        }
        .padding(.horizontal, Styles.paddingTiny)
        .padding(.bottom, Styles.paddingTiny)
    }
    
    // Expandable section with consistent styling
    private func expandableSection<Content: View>(
        title: String,
        sectionKey: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Button(action: {
            withAnimation(Styles.spring) {
                expandedSection = (expandedSection == sectionKey) ? nil : sectionKey
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack(alignment: .leading, spacing: Styles.spacingSmall) {
                HStack {
                    Text(title)
                        .font(Styles.subheaderFont)
                        .foregroundColor(Styles.textPrimary)
                    
                    Spacer()
                    
                    // Animated rotation for chevron
                    Image(systemName: "chevron.down")
                        .foregroundColor(Styles.textSecondary)
                        .font(.system(size: Styles.fontSmall))
                        .rotationEffect(Angle(degrees: expandedSection == sectionKey ? 180 : 0))
                        .animation(Styles.spring, value: expandedSection)
                }
                
                if expandedSection == sectionKey {
                    content()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(Styles.paddingStandard)
            .glassmorphicCard()
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    /// Constructs a row of icon, label, and value, used in the detail sections.
    func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Styles.spacingMedium) {
            Image(systemName: icon)
                .foregroundColor(Styles.primaryAccent)
                .frame(width: Styles.iconSizeMedium)
            
            Text(label)
                .font(Styles.bodyFont)
                .foregroundColor(Styles.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(Styles.bodyFont)
                .foregroundColor(Styles.textPrimary)
            
            Spacer()
        }
    }
    
    /// Enhanced coordinate display component with label and value
    func coordinateDisplay(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: Styles.fontSmall, weight: .bold))
                .foregroundColor(color)
                .frame(width: 40, alignment: .center)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                )
            
            Text(value)
                .font(Styles.captionFont)
                .foregroundColor(Styles.textPrimary)
                .padding(.leading, 4)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    /// A visual copy feedback component
    struct CopyFeedbackView: View {
        let text: String
        
        var body: some View {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Styles.statusSuccess)
                    .font(.system(size: Styles.iconSizeMedium))
                
                Text(text)
                    .font(Styles.bodyFont)
                    .foregroundColor(Styles.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, Styles.paddingMedium)
            .padding(.vertical, Styles.paddingSmall)
            .background(
                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                    .fill(Styles.cardSurface)
                    .shadow(color: Styles.cardShadow, radius: Styles.shadowRadiusMedium, x: 0, y: 4)
            )
            .padding(.horizontal, Styles.paddingLarge)
        }
    }
    
    /// Returns color based on probability value
    func probabilityColor(for value: Int) -> Color {
        if value >= 80 {
            return Styles.statusSuccess
        } else if value >= 50 {
            return Styles.statusWarning
        } else {
            return Styles.statusError
        }
    }
    
    /// Returns a textual representation of how much time remains until launch.
    var timeUntilLaunch: String {
        let timeRemaining = launch.net.timeIntervalSinceNow
        if timeRemaining <= 0 {
            return "Launched"
        }
        let days = Int(timeRemaining / 86400)
        let hours = Int(timeRemaining.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes = Int(timeRemaining.truncatingRemainder(dividingBy: 3600) / 60)
        
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m until launch"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m until launch"
        } else {
            return "\(minutes)m until launch"
        }
    }
}