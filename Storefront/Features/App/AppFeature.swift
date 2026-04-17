import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var isFileImporterPresented: Bool = false
        var browser: BrowserFeature.State?
        var simulatorPicker: SimulatorPickerFeature.State?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case openButtonTapped
        case simulatorButtonTapped
        case reloadMenuSelected
        case fileImported(URL)
        case fileImportFailed(String)
        case closeDocument
        case browser(BrowserFeature.Action)
        case simulatorPicker(SimulatorPickerFeature.Action)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .openButtonTapped:
                state.isFileImporterPresented = true
                return .none

            case .simulatorButtonTapped:
                state.simulatorPicker = SimulatorPickerFeature.State()
                return .none

            case .reloadMenuSelected:
                guard state.browser != nil else { return .none }
                return .send(.browser(.refreshRequested))

            case let .fileImported(url):
                state.isFileImporterPresented = false
                state.simulatorPicker = nil
                state.browser = BrowserFeature.State(databaseURL: url)
                return .none

            case .fileImportFailed:
                state.isFileImporterPresented = false
                return .none

            case .closeDocument:
                state.browser = nil
                return .none

            case .simulatorPicker(.databasePicked(let url)):
                return .send(.fileImported(url))

            case .simulatorPicker(.dismissTapped):
                state.simulatorPicker = nil
                return .none

            case .browser, .simulatorPicker:
                return .none
            }
        }
        .ifLet(\.browser, action: \.browser) {
            BrowserFeature()
        }
        .ifLet(\.simulatorPicker, action: \.simulatorPicker) {
            SimulatorPickerFeature()
        }
    }
}
