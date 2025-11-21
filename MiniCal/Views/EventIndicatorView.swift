import SwiftUI

struct EventIndicatorView: View {
    let eventIndicators: [EventColor]
    let maxVisibleIndicators: Int

    init(eventIndicators: [EventColor], maxVisible: Int = 3) {
        self.eventIndicators = eventIndicators
        self.maxVisibleIndicators = maxVisible
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(eventIndicators.prefix(maxVisibleIndicators).enumerated()), id: \.offset) { index, color in
                indicatorCircle(color: color, index: index)
            }

            if eventIndicators.count > maxVisibleIndicators {
                additionalEventsIndicator
            }
        }
    }

    // MARK: - Individual Indicator
    private func indicatorCircle(color: EventColor, index: Int) -> some View {
        Circle()
            .fill(color.swiftUIColor)
            .frame(width: 6, height: 6)
            .scaleEffect(1.0)
            .animation(
                .easeInOut(duration: 0.3).delay(Double(index) * 0.1),
                value: true
            )
    }

    // MARK: - Additional Events Indicator
    private var additionalEventsIndicator: some View {
        let additionalCount = eventIndicators.count - maxVisibleIndicators

        return Group {
            if additionalCount > 0 {
                Text("+\(additionalCount)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Multi Event Indicator View
struct MultiEventIndicatorView: View {
    let eventCount: Int
    let colors: [EventColor]
    let layout: EventIndicatorLayout

    init(eventCount: Int, colors: [EventColor] = [], layout: EventIndicatorLayout = .horizontal) {
        self.eventCount = eventCount
        self.colors = colors
        self.layout = layout
    }

    var body: some View {
        Group {
            if eventCount == 0 {
                EmptyIndicatorView()
            } else if eventCount <= 3 {
                SmallIndicatorView(count: eventCount, colors: colors)
            } else {
                LargeIndicatorView(count: eventCount, colors: colors, layout: layout)
            }
        }
    }

    // MARK: - Empty Indicator
    private struct EmptyIndicatorView: View {
        var body: some View {
            EmptyView()
        }
    }

    // MARK: - Small Indicator (1-3 events)
    private struct SmallIndicatorView: View {
        let count: Int
        let colors: [EventColor]

        var body: some View {
            HStack(spacing: 2) {
                ForEach(0..<min(count, 3), id: \.self) { index in
                    let color = index < colors.count ? colors[index] : .blue
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }

    // MARK: - Large Indicator (4+ events)
    private struct LargeIndicatorView: View {
        let count: Int
        let colors: [EventColor]
        let layout: EventIndicatorLayout

        var body: some View {
            Group {
                switch layout {
                case .horizontal:
                    horizontalLayout
                case .vertical:
                    verticalLayout
                case .circular:
                    circularLayout
                case .stacked:
                    stackedLayout
                }
            }
        }

        private var horizontalLayout: some View {
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    let color = index < colors.count ? colors[index] : .blue
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 6, height: 6)
                }
                if count > 3 {
                    Text("+\(count - 3)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }

        private var verticalLayout: some View {
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    let color = index < colors.count ? colors[index] : .blue
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 6, height: 6)
                }
                if count > 3 {
                    Text("+\(count - 3)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }

        private var circularLayout: some View {
            ZStack {
                if count <= 7 {
                    circularDotLayout(radius: 12)
                } else {
                    compactCircularLayout()
                }
            }
        }

        private func circularDotLayout(radius: CGFloat) -> some View {
            ZStack {
                ForEach(0..<min(count, colors.count), id: \.self) { index in
                    let color = index < colors.count ? colors[index] : .blue
                    let angle = Double(index) * (2 * .pi / Double(min(count, colors.count)))
                    let x = cos(angle) * radius
                    let y = sin(angle) * radius

                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 6, height: 6)
                        .offset(x: x, y: y)
                }

                if count > colors.count {
                    Text("+\(count - colors.count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(4)
                }
            }
        }

        private func compactCircularLayout() -> some View {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)

                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }

        private var stackedLayout: some View {
            VStack(spacing: 0) {
                ForEach(0..<min(3, count), id: \.self) { index in
                    let color = index < colors.count ? colors[index] : .blue
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 6, height: 6)
                        .offset(y: CGFloat(index) * -4)
                }
            }
            .frame(height: 18)
            .clipped()
        }
    }
}

// MARK: - Event Indicator Layout
enum EventIndicatorLayout {
    case horizontal
    case vertical
    case circular
    case stacked
}

// MARK: - Animated Event Indicator
struct AnimatedEventIndicatorView: View {
    @State private var isAnimating = false
    let eventCount: Int
    let colors: [EventColor]

    init(eventCount: Int, colors: [EventColor] = []) {
        self.eventCount = eventCount
        self.colors = colors
    }

    var body: some View {
        MultiEventIndicatorView(
            eventCount: eventCount,
            colors: colors,
            layout: .horizontal
        )
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(
            .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Event Indicator with Tooltip
struct EventIndicatorWithTooltip: View {
    let eventIndicators: [EventColor]
    let tooltipText: String

    @State private var showTooltip = false

    var body: some View {
        ZStack {
            EventIndicatorView(eventIndicators: eventIndicators)
                .onHover { hovering in
                    showTooltip = hovering
                }

            if showTooltip {
                VStack {
                    Spacer()
                    Text(tooltipText)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .transition(.opacity)
                }
                .offset(y: -35)
                .zIndex(1)
            }
        }
    }
}

// MARK: - Preview
struct EventIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Single indicator
            EventIndicatorView(eventIndicators: [.blue])
                .padding()

            // Multiple indicators
            EventIndicatorView(eventIndicators: [.red, .blue, .green, .orange])
                .padding()

            // Multi event indicator
            MultiEventIndicatorView(
                eventCount: 5,
                colors: [.red, .blue, .green, .orange, .purple],
                layout: .horizontal
            )
            .padding()

            // Large event count
            MultiEventIndicatorView(
                eventCount: 12,
                colors: [.blue],
                layout: .horizontal
            )
            .padding()

            // Circular layout
            MultiEventIndicatorView(
                eventCount: 6,
                colors: [.red, .blue, .green, .orange, .purple, .pink],
                layout: .circular
            )
            .frame(width: 60, height: 60)
            .padding()

            // Animated indicator
            AnimatedEventIndicatorView(
                eventCount: 3,
                colors: [.red, .blue, .green]
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}