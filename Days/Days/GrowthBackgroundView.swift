import SwiftUI

struct GrowthBackgroundView: View {
    let level: Int

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                LinearGradient(
                    colors: [
                        DaysTheme.Colors.backgroundStart,
                        DaysTheme.Colors.backgroundMid,
                        DaysTheme.Colors.backgroundEnd
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ForEach(0..<level, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DaysTheme.Colors.primaryText.opacity(0.12),
                                    DaysTheme.Colors.accent.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: circleSize(for: index), height: circleSize(for: index))
                        .blur(radius: 6)
                        .position(position(for: index, in: size))
                }
            }
            .overlay(DaysTheme.Colors.shadow)
            .ignoresSafeArea()
        }
    }

    private func circleSize(for index: Int) -> CGFloat {
        CGFloat(64 + (index % 5) * 26)
    }

    private func position(for index: Int, in size: CGSize) -> CGPoint {
        let xProgress = (sin(Double(index) * 1.71) + 1) / 2
        let yProgress = (cos(Double(index) * 1.13) + 1) / 2

        return CGPoint(
            x: max(40, size.width * CGFloat(xProgress)),
            y: max(80, size.height * CGFloat(yProgress))
        )
    }
}
