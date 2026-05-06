import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var isFileImporterPresented: Bool = false
        var simulatorPicker: SimulatorPickerFeature.State?
        var tabs: IdentifiedArrayOf<BrowserTab.State> = []
        var selectedTabID: BrowserTab.State.ID?

        var selectedTab: BrowserTab.State? {
            guard let id = selectedTabID else { return nil }
            return tabs[id: id]
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case openButtonTapped
        case newTabButtonTapped
        case reloadMenuSelected
        case fileImported(URL)
        case fileImportFailed(String)
        case tabSelected(BrowserTab.State.ID)
        case tabCloseTapped(BrowserTab.State.ID)
        case closeCurrentTab
        case tabs(IdentifiedActionOf<BrowserTab>)
        case simulatorPicker(SimulatorPickerFeature.Action)
    }

    @Dependency(\.uuid) var uuid

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .openButtonTapped:
                state.isFileImporterPresented = true
                return .none

            case .newTabButtonTapped:
                state.simulatorPicker = SimulatorPickerFeature.State()
                return .none

            case .reloadMenuSelected:
                guard let id = state.selectedTabID else { return .none }
                return .send(.tabs(.element(id: id, action: .browser(.refreshRequested))))

            case let .fileImported(url):
                state.isFileImporterPresented = false
                state.simulatorPicker = nil
                let newTab = BrowserTab.State(id: uuid(), databaseURL: url)
                state.tabs.append(newTab)
                state.selectedTabID = newTab.id
                return .none

            case .fileImportFailed:
                state.isFileImporterPresented = false
                return .none

            case let .tabSelected(id):
                guard state.tabs[id: id] != nil else { return .none }
                state.selectedTabID = id
                return .none

            case let .tabCloseTapped(id):
                return closeTab(id: id, in: &state)

            case .closeCurrentTab:
                guard let id = state.selectedTabID else { return .none }
                return closeTab(id: id, in: &state)

            case .simulatorPicker(.databasePicked(let url)):
                return .send(.fileImported(url))

            case .simulatorPicker(.dismissTapped):
                state.simulatorPicker = nil
                return .none

            case .tabs, .simulatorPicker:
                return .none
            }
        }
        .forEach(\.tabs, action: \.tabs) {
            BrowserTab()
        }
        .ifLet(\.simulatorPicker, action: \.simulatorPicker) {
            SimulatorPickerFeature()
        }
    }

    private func closeTab(id: BrowserTab.State.ID, in state: inout State) -> Effect<Action> {
        guard let index = state.tabs.index(id: id) else { return .none }
        state.tabs.remove(id: id)
        if state.selectedTabID == id {
            if state.tabs.isEmpty {
                state.selectedTabID = nil
            } else {
                let newIndex = max(0, min(index, state.tabs.count - 1))
                state.selectedTabID = state.tabs[newIndex].id
            }
        }
        return .none
    }
}
