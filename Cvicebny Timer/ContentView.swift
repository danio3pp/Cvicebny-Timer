import SwiftUI
import AudioToolbox // Pre zvuk

struct ContentView: View {
    @State private var totalSeconds = 60
    @State private var totalSeries = 5
    @State private var restSeconds = 15

    @State private var currentSecond = 60
    @State private var currentSeries = 1

    @State private var timerRunning = false
    @State private var showSettings = false
    @State private var timer: Timer? = nil

    // Určuje, či sme v prestávke alebo sérii
    @State private var inRestPeriod = false

    var body: some View {
        HStack {
            VStack {
                Text("\(currentSecond) s")
                    .font(.system(size: 100))
                    .padding()
                Button(timerRunning ? "Pauza" : "Štart") {
                    if timerRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }
                .padding(.bottom, 20)
                .font(.title)

                Button("Reset") {
                    totalSeconds = 60
                    totalSeries = 5
                    restSeconds = 15
                    resetTimer()
                }
                .font(.title)
            }
            .frame(minWidth: 300)

            VStack {
                Text("Séria: \(currentSeries)/\(totalSeries)")
                    .font(.system(size: 40))
                    .padding()
                Button("Uprav časovač") {
                    showSettings.toggle()
                }
                .font(.title)
            }
            .frame(minWidth: 300)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(totalSeconds: $totalSeconds,
                         totalSeries: $totalSeries,
                         restSeconds: $restSeconds,
                         onSave: {
                resetTimer()
            })
        }
    }

    func startTimer() {
        guard !timerRunning else { return }
        timerRunning = true
        inRestPeriod = false
        currentSecond = totalSeconds
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
            // Čas vypršal
            if inRestPeriod {
                // Skončila prestávka, začíname novú sériu
                inRestPeriod = false
                currentSecond = totalSeconds
            } else {
                // Dokončená séria
                AudioServicesPlaySystemSound(1005)

                currentSeries += 1
                if currentSeries > totalSeries {
                    // Všetky série dokončené
                    stopTimer()
                } else {
                    // Začneme prestávku
                    inRestPeriod = true
                    currentSecond = restSeconds
                }
            }
        }
    }

    func resetTimer() {
        stopTimer()
        currentSeries = 1
        currentSecond = totalSeconds
        inRestPeriod = false
    }
}

struct SettingsView: View {
    @Binding var totalSeconds: Int
    @Binding var totalSeries: Int
    @Binding var restSeconds: Int
    var onSave: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var sliderSeconds: Double
    @State private var sliderSeries: Double
    @State private var sliderRest: Double

    init(totalSeconds: Binding<Int>, totalSeries: Binding<Int>, restSeconds: Binding<Int>, onSave: @escaping () -> Void) {
        self._totalSeconds = totalSeconds
        self._totalSeries = totalSeries
        self._restSeconds = restSeconds
        self.onSave = onSave

        _sliderSeconds = State(initialValue: Double(totalSeconds.wrappedValue))
        _sliderSeries = State(initialValue: Double(totalSeries.wrappedValue))
        _sliderRest = State(initialValue: Double(restSeconds.wrappedValue))
    }

    var body: some View {
        VStack {
            Text("Nastavenia")
                .font(.title)

            Text("Počet sekúnd (séria): \(totalSeconds)")
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

            Text("Dĺžka prestávky: \(restSeconds)s")
            Slider(value: $sliderRest, in: 0...60)
                .onChange(of: sliderRest) { oldValue, newValue in
                    // Zaokrúhlenie na celé čísla (1 sek. intervaly stačia)
                    let roundedVal = round(newValue / 5).rounded() * 5
                    restSeconds = Int(roundedVal)
                    sliderRest = roundedVal
                }
                .padding(.vertical)

            Button("Uložiť") {
                onSave()
                dismiss()
            }
            .font(.title2)
            .padding()
        }
        .padding()
    }
}
