import SwiftUI
import AudioToolbox // Pre zvuk

struct ContentView: View {
    @State private var totalSeconds = 60
    @State private var totalSeries = 5
    @State private var currentSecond = 60
    @State private var currentSeries = 1

    @State private var timerRunning = false
    @State private var showSettings = false
    @State private var timer: Timer? = nil

    var body: some View {
        HStack {
            VStack {
                Text("\(currentSecond) s")
                    .font(.system(size: 60))
                    .padding()
                Button(timerRunning ? "Pauza" : "Štart") {
                    if timerRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }
                .padding(.bottom, 20)

                Button("Reset") {
                    totalSeconds = 60
                    totalSeries = 5
                    resetTimer()
                }
            }
            .frame(minWidth: 300)

            VStack {
                Text("Séria: \(currentSeries)/\(totalSeries)")
                    .font(.title)
                    .padding()
                Button("Uprav časovač") {
                    showSettings.toggle()
                }
            }
            .frame(minWidth: 300)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(totalSeconds: $totalSeconds, totalSeries: $totalSeries, onSave: {
                resetTimer()
            })
        }
    }

    func startTimer() {
        guard !timerRunning else { return }
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            tick()
        }
    }

    func stopTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil
    }

    func tick() {
        if currentSecond > 0 {
            currentSecond -= 1
        } else {
            // Dokončená séria
            AudioServicesPlaySystemSound(1005) // Zvuk

            currentSeries += 1
            if currentSeries > totalSeries {
                stopTimer()
            } else {
                currentSecond = totalSeconds
            }
        }
    }

    func resetTimer() {
        stopTimer()
        currentSeries = 1
        currentSecond = totalSeconds
    }
}

struct SettingsView: View {
    @Binding var totalSeconds: Int
    @Binding var totalSeries: Int
    var onSave: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var sliderSeconds: Double
    @State private var sliderSeries: Double

    init(totalSeconds: Binding<Int>, totalSeries: Binding<Int>, onSave: @escaping () -> Void) {
        self._totalSeconds = totalSeconds
        self._totalSeries = totalSeries
        self.onSave = onSave
        _sliderSeconds = State(initialValue: Double(totalSeconds.wrappedValue))
        _sliderSeries = State(initialValue: Double(totalSeries.wrappedValue))
    }

    var body: some View {
        VStack {
            Text("Nastavenia")
                .font(.title)
            
            Text("Počet sekúnd: \(totalSeconds)")
            Slider(value: $sliderSeconds, in: 10...120)
                .onChange(of: sliderSeconds) { oldValue, newValue in
                    let roundedVal = (newValue / 5).rounded() * 5
                    totalSeconds = Int(roundedVal)
                    sliderSeconds = roundedVal
                }
                .padding(.vertical)

            Text("Počet sérií: \(totalSeries)")
            Slider(value: $sliderSeries, in: 1...10)
                .onChange(of: sliderSeries) { oldValue, newValue in
                    let roundedVal = round(newValue)
                    totalSeries = Int(roundedVal)
                    sliderSeries = roundedVal
                }
                .padding(.vertical)

            Button("Uložiť") {
                onSave()
                dismiss()
            }
            .padding()
        }
        .padding()
    }
}
