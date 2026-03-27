import SwiftUI

struct ContentView: View {
    @Environment(DaysTimelineViewModel.self) private var viewModel

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
                            onSaveReflection: viewModel.saveCurrentReflection
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
    }
}
