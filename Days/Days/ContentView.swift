import SwiftUI

struct ContentView: View {
    @Environment(DaysTimelineViewModel.self) private var viewModel
    @State private var shareSheetItem: ShareSheetItem?
    @State private var shareErrorMessage: String?

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        ZStack {
            GrowthBackgroundView(level: viewModel.backgroundLevel)

            ScrollView {
                VStack(alignment: .leading, spacing: DaysTheme.Layout.cardSpacing) {
                    ScreenHeaderView()

                    switch viewModel.presentation {
                    case .loading:
                        LoadingCardView()
                    case .quiet(let presentation):
                        QuietCardView(presentation: presentation)
                    case .timeline(let presentation):
                        TimelineCardView(
                            presentation: presentation,
                            wordDraft: $bindableViewModel.wordDraft,
                            reflectionDraft: $bindableViewModel.reflectionDraft,
                            canSaveWord: viewModel.canSaveWord,
                            canSaveReflection: viewModel.canSaveReflection,
                            showsReflectionComposer: viewModel.showsReflectionComposer,
                            canStartReflection: viewModel.canStartReflection,
                            onSaveWord: viewModel.saveCurrentWord,
                            onStartReflection: viewModel.beginReflectionEntry,
                            onSkipReflection: viewModel.skipReflectionEntry,
                            onSaveReflection: viewModel.saveCurrentReflection,
                            onShare: { presentShareSheet(for: presentation) }
                        )
                    case .error(let message):
                        ErrorCardView(message: message, onRetry: viewModel.reload)
                    }
                }
                .padding(.horizontal, DaysTheme.Layout.screenHorizontalPadding)
                .padding(.top, DaysTheme.Layout.topPadding)
                .padding(.bottom, DaysTheme.Layout.bottomPadding)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.45), value: viewModel.presentation)
        .animation(.easeInOut(duration: 0.8), value: viewModel.backgroundLevel)
        .sheet(item: $shareSheetItem) { item in
            ActivityShareSheet(items: [item.url])
        }
        .alert("공유 카드를 만들지 못했어요.", isPresented: shareErrorBinding) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(shareErrorMessage ?? "잠시 후 다시 시도해 주세요.")
        }
    }

    private var shareErrorBinding: Binding<Bool> {
        Binding(
            get: { shareErrorMessage != nil },
            set: { newValue in
                if newValue == false {
                    shareErrorMessage = nil
                }
            }
        )
    }

    private func presentShareSheet(for presentation: TimelinePresentation) {
        do {
            let url = try ShareCardExporter.exportCard(for: presentation)
            shareSheetItem = ShareSheetItem(url: url)
        } catch {
            shareErrorMessage = error.localizedDescription
        }
    }
}
