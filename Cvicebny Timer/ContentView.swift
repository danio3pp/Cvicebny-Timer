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
    @State private var ended = false

    var body: some View {
        ZStack {
            // Pastelový gradient pozadie
            LinearGradient(gradient: Gradient(colors: [
                Color.pink.opacity(0.4),
                Color.purple.opacity(0.4)
            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            Group {
                if ended {
                    // Obrazovka po skončení cviku
                    VStack(spacing: 40) {
                        Text("👏 Koniec cviku 👏")
                            .font(.system(size: 60, weight: .bold))
                            .padding()
                            .foregroundColor(.white)
                            .background(.ultraThinMaterial)
                            .cornerRadius(25)

                        Button("Reset") {
                            totalSeconds = 60
                            totalSeries = 5
                            restSeconds = 15
                            resetTimer()
                        }
                        .font(.title)
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                        .cornerRadius(10)
                    }
                } else {
                    HStack(spacing: 40) {
                        // Časovač a tlačidlá
                        VStack(spacing: 20) {
                            Text("\(currentSecond) s")
                                .font(.system(size: 160, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)

                            Button(timerRunning ? "Pauza" : "Štart") {
                                if timerRunning {
                                    stopTimer()
                                } else {
                                    startTimer()
                                }
                            }
                            .font(.title2)
                            .buttonStyle(.borderedProminent)
                            .tint(timerRunning ? .purple : .pink)
                            .cornerRadius(10)

                            Button("Reset") {
                                totalSeconds = 60
                                totalSeries = 5
                                restSeconds = 15
                                resetTimer()
                            }
                            .font(.title2)
                            .buttonStyle(.bordered)
                            .tint(.purple)
                            .cornerRadius(10)
                        }

                        // Séria / Prestávka a nastavenia
                        VStack(spacing: 20) {
                            if inRestPeriod {
                                Text("Prestávka")
                                    .font(.system(size: 100, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(20)
                            } else {
                                Text("Séria: \(currentSeries)/\(totalSeries)")
                                    .font(.system(size: 100, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(20)
                            }

                            Button("Uprav časovač") {
                                showSettings.toggle()
                            }
                            .font(.title2)
                            .buttonStyle(.borderedProminent)
                            .tint(.pink)
                            .cornerRadius(10)
                        }
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
            .padding()
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
        if ended { return }

        if inRestPeriod {
            if currentSecond < restSeconds {
                currentSecond += 1
            } else {
                AudioServicesPlaySystemSound(1005)
                inRestPeriod = false
                currentSecond = totalSeconds
            }
        } else {
            if currentSecond > 0 {
                currentSecond -= 1
            } else {
                AudioServicesPlaySystemSound(1005)
                currentSeries += 1
                if currentSeries > totalSeries {
                    stopTimer()
                    ended = true
                } else {
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
        VStack(spacing: 30) {
            Text("Nastavenia")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(10)
                .background(.ultraThinMaterial)
                .cornerRadius(10)

            Group {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Počet sekúnd (séria): \(totalSeconds)")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Slider(value: $sliderSeconds, in: 10...120)
                        .onChange(of: sliderSeconds) { _, newValue in
                            let roundedVal = (newValue / 5).rounded() * 5
                            totalSeconds = Int(roundedVal)
                            sliderSeconds = roundedVal
                        }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Počet sérií: \(totalSeries)")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Slider(value: $sliderSeries, in: 1...10)
                        .onChange(of: sliderSeries) { _, newValue in
                            let roundedVal = round(newValue)
                            totalSeries = Int(roundedVal)
                            sliderSeries = roundedVal
                        }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Dĺžka prestávky: \(restSeconds)s")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Slider(value: $sliderRest, in: 0...60)
                        .onChange(of: sliderRest) { _, newValue in
                            let roundedVal = (newValue / 5).rounded() * 5
                            restSeconds = Int(roundedVal)
                            sliderRest = roundedVal
                        }
                }
            }

            Button("Uložiť") {
                onSave()
                dismiss()
            }
            .font(.title3)
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            .cornerRadius(10)
            .padding(.top, 20)
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding()
        // Pridáme pozadie pre nastavenia, aby ladilo so zvyškom
        .background(
            LinearGradient(gradient: Gradient(colors: [
                Color.pink.opacity(0.3),
                Color.purple.opacity(0.3)
            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        )
    }
}
