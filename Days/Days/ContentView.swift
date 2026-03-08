import SwiftUI

struct ContentView: View {
    @Environment(DaysTimelineViewModel.self) private var viewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        ZStack {
            GrowthBackgroundView(level: viewModel.backgroundLevel)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    switch viewModel.presentation {
                    case .loading:
                        loadingView
                    case .quiet(let presentation):
                        quietView(presentation)
                    case .timeline(let presentation):
                        timelineView(presentation, noteDraft: $bindableViewModel.noteDraft)
                    case .error(let message):
                        errorView(message)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.handleScenePhaseChange(.active)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.handleScenePhaseChange(.active)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            viewModel.handleScenePhaseChange(.inactive)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            viewModel.handleScenePhaseChange(.background)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("사이")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            Text("앱 밖에서 흐른 시간을 조용히 되돌려줍니다.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private var loadingView: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.white.opacity(0.08))
            .overlay {
                ProgressView()
                    .tint(.white)
                    .padding(32)
            }
            .frame(height: 220)
    }

    private func quietView(_ presentation: QuietPresentation) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(presentation.title)
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .fixedSize(horizontal: false, vertical: true)

            Text(presentation.message)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(6)

            Label("첫 방문을 기억했습니다.", systemImage: "sparkles")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.cyan.opacity(0.85))
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func timelineView(_ presentation: TimelinePresentation, noteDraft: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text(presentation.headline)
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .fixedSize(horizontal: false, vertical: true)

                Text(presentation.subtitle)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.92))

                Text(presentation.visitCountLine)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.72))
            }

            if let translatedLine = presentation.translatedLine {
                insightRow(systemName: "sparkles", text: translatedLine)
            }

            if let rhythmLine = presentation.rhythmLine {
                insightRow(systemName: "waveform.path", text: rhythmLine)
            }

            if presentation.statCards.isEmpty == false {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(presentation.statCards) { card in
                        StatCardView(card: card)
                    }
                }
            }

            noteCard(noteDraft: noteDraft, savedWords: presentation.savedWords)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func noteCard(noteDraft: Binding<String>, savedWords: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("이번 사이를 한 단어로 남겨두기")
                .font(.headline)

            HStack(spacing: 12) {
                TextField("피곤 / 여행 / 겨울", text: noteDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit {
                        if viewModel.canSaveNote {
                            viewModel.saveCurrentNote()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.white.opacity(0.08))
                    )

                Button("남기기") {
                    viewModel.saveCurrentNote()
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan.opacity(0.75))
                .disabled(viewModel.canSaveNote == false)
            }

            if savedWords.isEmpty == false {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(savedWords, id: \.self) { word in
                            Text(word)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(.white.opacity(0.08))
                                )
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.top, 4)
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("기록이 잠시 흐려졌어요.")
                .font(.title2.weight(.semibold))

            Text(message)
                .foregroundStyle(.white.opacity(0.78))

            Button("다시 불러오기") {
                viewModel.reload()
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.18))
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func insightRow(systemName: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemName)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.cyan.opacity(0.9))
                .frame(width: 18)

            Text(text)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct StatCardView: View {
    let card: StatCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.65))

            Text(card.value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.07))
        )
    }
}
