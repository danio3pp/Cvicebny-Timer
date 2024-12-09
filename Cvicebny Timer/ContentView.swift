import SwiftUI
import AudioToolbox
import UIKit // Pre prístup k UIApplication

struct ContentView: View {
    @State private var totalSeconds = 60
    @State private var totalSeries = 5
    @State private var restSeconds = 15

    @State private var currentSecond = 60
    @State private var currentSeries = 1

    @State private var timerRunning = false
    @State private var showSettings = false
    @State private var timer: Timer? = nil

    @State private var inRestPeriod = false
    @State private var ended = false // Indikátor, či sme dokončili všetky série

    var body: some View {
        Group {
            if ended {
                // Všetko dokončené, zobraz len "Koniec cviku" a tlačidlo Reset
                VStack {
                    Text("Koniec cviku")
                        .font(.system(size: 50))
                        .padding()
                    Button("Reset") {
                        resetTimer()
                    }
                    .font(.title)
                    .padding()
                }
            } else {
                // Bežné UI
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
                        // Ak sme v prestávke, zobraz "Prestávka" inak zobrazi sériu
                        if inRestPeriod {
                            Text("Prestávka")
                                .font(.system(size: 40))
                                .padding()
                        } else {
                            Text("Séria: \(currentSeries)/\(totalSeries)")
                                .font(.system(size: 40))
                                .padding()
                        }

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
        }
    }

    func startTimer() {
        guard !timerRunning else { return }
        timerRunning = true
        ended = false
        inRestPeriod = false
        currentSecond = totalSeconds
        UIApplication.shared.isIdleTimerDisabled = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            tick()
        }
    }

    func stopTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func tick() {
        if ended {
            return
        }

        if inRestPeriod {
            // Prestávka: počítame od 0 nahor
            if currentSecond < restSeconds {
                currentSecond += 1
            } else {
                // Prestávka ukončená
                AudioServicesPlaySystemSound(1005)
                inRestPeriod = false
                currentSecond = totalSeconds
            }
        } else {
            // Séria: odpočítavame smerom dole
            if currentSecond > 0 {
                currentSecond -= 1
            } else {
                // Dokončená séria
                AudioServicesPlaySystemSound(1005)
                currentSeries += 1
                if currentSeries > totalSeries {
                    // Všetky série dokončené
                    stopTimer()
                    ended = true
                } else {
                    // Začneme prestávku
                    inRestPeriod = true
                    currentSecond = 0
                }
            }
        }
    }

    func resetTimer() {
        stopTimer()
        currentSeries = 1
        inRestPeriod = false
        currentSecond = totalSeconds
        ended = false
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
                .onChange(of: sliderSeconds) { _, newValue in
                    let roundedVal = (newValue / 5).rounded() * 5
                    totalSeconds = Int(roundedVal)
                    sliderSeconds = roundedVal
                }
                .padding(.vertical)

            Text("Počet sérií: \(totalSeries)")
            Slider(value: $sliderSeries, in: 1...10)
                .onChange(of: sliderSeries) { _, newValue in
                    let roundedVal = round(newValue)
                    totalSeries = Int(roundedVal)
                    sliderSeries = roundedVal
                }
                .padding(.vertical)

            Text("Dĺžka prestávky: \(restSeconds)s")
            Slider(value: $sliderRest, in: 0...60)
                .onChange(of: sliderRest) { _, newValue in
                    let roundedVal = (newValue / 5).rounded() * 5
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
