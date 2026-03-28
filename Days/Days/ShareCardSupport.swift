import SwiftUI
import UIKit

struct ShareSheetItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum ShareCardExportError: LocalizedError {
    case failedToRender
    case failedToEncode

    var errorDescription: String? {
        switch self {
        case .failedToRender, .failedToEncode:
            return "공유용 카드를 준비하지 못했어요. 잠시 후 다시 시도해 주세요."
        }
    }
}

@MainActor
enum ShareCardExporter {
    static func exportCard(for presentation: TimelinePresentation) throws -> URL {
        let data = try pngData(for: presentation)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("days-share-\(UUID().uuidString).png")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    static func pngData(for presentation: TimelinePresentation) throws -> Data {
        let renderer = ImageRenderer(
            content: ShareCardView(presentation: presentation)
        )
        renderer.scale = 3

        guard let image = renderer.uiImage else {
            throw ShareCardExportError.failedToRender
        }

        guard let data = image.pngData() else {
            throw ShareCardExportError.failedToEncode
        }

        return data
    }
}

struct ShareCardView: View {
    let presentation: TimelinePresentation

    private enum Metrics {
        static let width: CGFloat = 360
        static let height: CGFloat = 720
    }

    var body: some View {
        ZStack {
            GrowthBackgroundView(level: presentation.backgroundLevel + 2)

            VStack(alignment: .leading, spacing: 28) {
                header
                headlineSection
                insightSection

                if let latestRecordedEntry = presentation.latestRecordedEntry {
                    latestRecordSection(entry: latestRecordedEntry)
                }

                Spacer()

                footer
            }
            .padding(32)
        }
        .frame(width: Metrics.width, height: Metrics.height)
        .overlay(alignment: .center) {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(DaysTheme.Colors.cardStroke, lineWidth: 1)
                .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("사이")
                    .font(DaysTheme.Typography.brand)
                    .foregroundStyle(DaysTheme.Colors.primaryText)

                Text("앱 밖에서 흐른 시간을 조용히 되돌려줍니다.")
                    .font(DaysTheme.Typography.caption)
                    .foregroundStyle(DaysTheme.Colors.subduedText)
            }

            Spacer()

            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(DaysTheme.Colors.accent)
                .padding(14)
                .background(
                    Circle()
                        .fill(DaysTheme.Colors.cardInnerFill)
                )
        }
    }

    private var headlineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(presentation.headline)
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundStyle(DaysTheme.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(presentation.subtitle)
                .font(DaysTheme.Typography.section)
                .foregroundStyle(DaysTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(presentation.visitCountLine)
                .font(DaysTheme.Typography.callout)
                .foregroundStyle(DaysTheme.Colors.subduedText)
        }
    }

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let translatedLine = presentation.translatedLine {
                shareInsightRow(icon: "sparkles", text: translatedLine)
            }

            if let rhythmLine = presentation.rhythmLine {
                shareInsightRow(icon: "waveform.path", text: rhythmLine)
            }
        }
    }

    private func latestRecordSection(entry: LatestRecordedEntryPresentation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 남긴 기록")
                .font(DaysTheme.Typography.caption)
                .foregroundStyle(DaysTheme.Colors.tertiaryText)

            Text(entry.word)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(DaysTheme.Colors.primaryText)

            if entry.reflection.isEmpty == false {
                Text(entry.reflection)
                    .font(DaysTheme.Typography.callout)
                    .foregroundStyle(DaysTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: DaysTheme.Layout.cardCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: DaysTheme.Layout.cardCornerRadius, style: .continuous)
                        .stroke(DaysTheme.Colors.cardStroke, lineWidth: 1)
                )
        )
    }

    private var footer: some View {
        HStack {
            Text("from 사이")
                .font(DaysTheme.Typography.caption)
                .foregroundStyle(DaysTheme.Colors.tertiaryText)

            Spacer()

            Text("oozoofrog")
                .font(DaysTheme.Typography.caption)
                .foregroundStyle(DaysTheme.Colors.tertiaryText)
        }
    }

    private func shareInsightRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.callout.weight(.semibold))
                .foregroundStyle(DaysTheme.Colors.accent)
                .frame(width: 18)

            Text(text)
                .font(DaysTheme.Typography.callout)
                .foregroundStyle(DaysTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
