import SwiftUI

struct ScreenHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("사이")
                .font(DaysTheme.Typography.brand)
                .accessibilityIdentifier("brand.title")

            Text("앱 밖에서 흐른 시간을 조용히 되돌려줍니다.")
                .font(DaysTheme.Typography.callout)
                .foregroundStyle(DaysTheme.Colors.subduedText)
        }
        .accessibilityElement(children: .contain)
    }
}

struct LoadingCardView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: DaysTheme.Layout.cardCornerRadius, style: .continuous)
            .fill(DaysTheme.Colors.cardFill)
            .overlay {
                ProgressView()
                    .tint(DaysTheme.Colors.primaryText)
                    .padding(32)
            }
            .frame(height: 220)
            .accessibilityIdentifier("journey.loading")
    }
}

struct QuietCardView: View {
    let presentation: QuietPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(presentation.title)
                .font(DaysTheme.Typography.hero)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("quiet.title")

            Text(presentation.message)
                .font(DaysTheme.Typography.body)
                .foregroundStyle(DaysTheme.Colors.secondaryText)
                .lineSpacing(6)

            Label("첫 방문을 기억했습니다.", systemImage: "sparkles")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(DaysTheme.Colors.accent.opacity(0.92))
        }
        .padding(DaysTheme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DaysCardBackground())
    }
}

struct TimelineCardView: View {
    let presentation: TimelinePresentation
    @Binding var noteDraft: String
    let canSaveNote: Bool
    let onSave: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: DaysTheme.Layout.gridSpacing),
        GridItem(.flexible(), spacing: DaysTheme.Layout.gridSpacing)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeroTimeCard(
                headline: presentation.headline,
                subtitle: presentation.subtitle,
                visitCountLine: presentation.visitCountLine
            )

            if let translatedLine = presentation.translatedLine {
                InsightRow(systemName: "sparkles", text: translatedLine)
            }

            if let rhythmLine = presentation.rhythmLine {
                InsightRow(systemName: "waveform.path", text: rhythmLine)
            }

            if presentation.statCards.isEmpty == false {
                LazyVGrid(columns: columns, spacing: DaysTheme.Layout.gridSpacing) {
                    ForEach(presentation.statCards) { card in
                        StatCardView(card: card)
                    }
                }
            }

            WordNoteCardView(
                noteDraft: $noteDraft,
                canSaveNote: canSaveNote,
                savedWords: presentation.savedWords,
                onSave: onSave
            )
        }
        .padding(DaysTheme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DaysCardBackground())
    }
}

private struct HeroTimeCard: View {
    let headline: String
    let subtitle: String
    let visitCountLine: String

    var body: some View {
        VStack(alignment: .leading, spacing: DaysTheme.Layout.rowSpacing) {
            Text(headline)
                .font(DaysTheme.Typography.hero)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("timeline.headline")

            Text(subtitle)
                .font(DaysTheme.Typography.section)
                .foregroundStyle(DaysTheme.Colors.primaryText.opacity(0.92))

            Text(visitCountLine)
                .font(DaysTheme.Typography.callout)
                .foregroundStyle(DaysTheme.Colors.subduedText)
        }
    }
}

private struct WordNoteCardView: View {
    @Binding var noteDraft: String
    let canSaveNote: Bool
    let savedWords: [String]
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("이번 사이를 한 단어로 남겨두기")
                .font(.headline)

            HStack(spacing: DaysTheme.Layout.gridSpacing) {
                TextField("피곤 / 여행 / 겨울", text: $noteDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(onSave)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: DaysTheme.Layout.inputCornerRadius, style: .continuous)
                            .fill(DaysTheme.Colors.cardFill)
                    )
                    .accessibilityIdentifier("note.input")

                Button("남기기", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .tint(DaysTheme.Colors.accent.opacity(0.9))
                    .disabled(canSaveNote == false)
                    .accessibilityIdentifier("note.save")
            }

            if savedWords.isEmpty == false {
                ScrollView(.horizontal) {
                    HStack(spacing: DaysTheme.Layout.chipSpacing) {
                        ForEach(savedWords, id: \.self) { word in
                            Text(word)
                                .font(DaysTheme.Typography.chip)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(DaysTheme.Colors.cardFill)
                                )
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.top, 4)
    }
}

struct ErrorCardView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("기록이 잠시 흐려졌어요.")
                .font(.title2.weight(.semibold))
                .accessibilityIdentifier("error.title")

            Text(message)
                .foregroundStyle(DaysTheme.Colors.secondaryText)

            Button("다시 불러오기", action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(DaysTheme.Colors.primaryText.opacity(0.18))
                .accessibilityIdentifier("error.retry")
        }
        .padding(DaysTheme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DaysCardBackground())
    }
}

private struct InsightRow: View {
    let systemName: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: DaysTheme.Layout.rowSpacing) {
            Image(systemName: systemName)
                .font(.callout.weight(.semibold))
                .foregroundStyle(DaysTheme.Colors.accent.opacity(0.94))
                .frame(width: 18)

            Text(text)
                .font(DaysTheme.Typography.callout)
                .foregroundStyle(DaysTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct StatCardView: View {
    let card: StatCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.title)
                .font(DaysTheme.Typography.caption)
                .foregroundStyle(DaysTheme.Colors.tertiaryText)

            Text(card.value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(DaysTheme.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: DaysTheme.Layout.innerCornerRadius, style: .continuous)
                .fill(DaysTheme.Colors.cardInnerFill)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.title) \(card.value)")
    }
}

private struct DaysCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: DaysTheme.Layout.cardCornerRadius, style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: DaysTheme.Layout.cardCornerRadius, style: .continuous)
                    .stroke(DaysTheme.Colors.cardStroke, lineWidth: 1)
            )
    }
}
