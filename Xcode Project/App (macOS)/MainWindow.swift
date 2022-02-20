import SwiftUI
import Combine

struct MainWindow: View {
    @StateObject private var pump = Pump()
    @ScaledMetric private var windowWidth: CGFloat = 400
    @ScaledMetric private var lineHeight: CGFloat = 20
    @State private var clientConfigurationIDValid = false
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                HStack(spacing: 20) {
                    Spacer()
                    
                    if self.pump.countSuccesses > 0 {
                        Label("Pumped \(self.pump.countSuccesses) GB", systemImage: "checkmark.circle")
                    }
                    
                    if self.pump.countFailures > 0 {
                        Label("\(self.pump.countFailures) Fails", systemImage: "xmark.circle")
                    }
                }
                .symbolRenderingMode(.multicolor)
                .frame(maxWidth: .infinity, minHeight: self.lineHeight, maxHeight: self.lineHeight)
                .padding(.top, -self.lineHeight)
                .padding([.trailing, .bottom])
                .animation(.default, value: self.pump.countSuccesses)
                .animation(.default, value: self.pump.countFailures)
            }
            
            GroupBox {
                TextField("Client Configuration ID", text: self.$pump.clientConfigurationID)
                    .multilineTextAlignment(.center)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
                    .disabled(self.pump.working)
                    .padding()
                    .onReceive(Just(pump.clientConfigurationID)) { newValue in self.clientConfigurationIDValid = UUID(uuidString: newValue) != nil }
                
                HStack(alignment: .top) {
                    Group {
                        if self.pump.requesting {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.5)
                                    .frame(width: self.lineHeight, height: self.lineHeight)
                                Text("Pumping")
                            }
                        } else {
                            Text(self.pump.working ? "Next pump in \(Int(ceil(self.pump.coolDownTimeRemaining)))s" : "")
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(self.pump.working ? "Stop" : "Start Pumping!") {
                        if self.pump.working {
                            self.pump.stop()
                        } else {
                            self.pump.start()
                        }
                    }
                    .disabled(!self.clientConfigurationIDValid)
                }
                .frame(height: self.lineHeight)
                .padding([.horizontal, .bottom])
            }
            .padding([.horizontal, .bottom])
        }
        .frame(width: self.windowWidth)
        .task {
            if let clientConfigurationID = iCloudKeyValueStorage.string(for: .clientConfigurationID) {
                self.pump.clientConfigurationID = clientConfigurationID
            }
        }
    }
}
