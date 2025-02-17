import SwiftUI

struct QEColorSchemePickerRow: View {
    enum Options: String, CaseIterable, Identifiable {
        var id: String {
            rawValue
        }
        
        case light
        case dark
        case system
        
        var colorScheme: UIUserInterfaceStyle {
            switch self {
            case .light:
                .light
            case .dark:
                .dark
            case .system:
                .unspecified
            }
        }
    }

    @Binding var selectedScheme: UIUserInterfaceStyle
    @State private var options: Options = .system
    
    var body: some View {
        HStack {
            Text("Color Scheme")
            Spacer()
            Picker("Color Scheme", selection: $options) {
                ForEach(Options.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: options) { newValue in
                self.selectedScheme = newValue.colorScheme
            }
        }

    }
}

#Preview {
    QEColorSchemePickerRow(selectedScheme: .constant(.unspecified))
}
