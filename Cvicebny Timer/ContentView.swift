import SwiftUI
import AudioToolbox
import UIKit // Pre prístup k UIApplication

struct ContentView: View {
    @State private var totalSeconds = 30
    @State private var totalSeries = 8
    @State private var restSeconds = 15

    @State private var currentSecond = 30
    @State private var currentSeries = 1

    @State private var timerRunning = false
    @State private var showSettings = false
    @State private var timer: Timer? = nil

    @State private var inRestPeriod = false
    @State private var ended = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Pastelový gradient pozadie
                LinearGradient(gradient: Gradient(colors: [
                    Color.pink.opacity(0.4),
                    Color.purple.opacity(0.4)
                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

                if ended {
                    // Celá obrazovka: Koniec cviku
                    VStack(spacing: 40) {
                        Text("👏 Koniec cviku 👏")
                            .font(.system(size: 100, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(25)

                        Button("Reset") {
                            totalSeconds = 30
                            totalSeries = 8
                            restSeconds = 15
                            resetTimer()
                        }
                        .font(.title)
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                        .cornerRadius(10)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    // Rozloženie na 50:50 obrazovky horizontálne
                    HStack(spacing: 0) {
                        // Ľavá 1/4 šírky pre časovač a ovládacie prvky
                        ZStack {
                            VStack(spacing: 20) {
                                Text("\(currentSecond) s")
                                    .font(.system(size: 380, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding()
                                    //.background(.ultraThinMaterial)
                                    .cornerRadius(20)

                                HStack(spacing: 40) {
                                    Button(timerRunning ? "Pauza" : "Štart") {
                                        if timerRunning {
                                            stopTimer()
                                        } else {
                                            startTimer()
                                        }
                                    }
                                    .font(.system(size: 50, weight: .bold))
                                    .frame(width: 200, height: 80)
                                    .padding()
                                    .buttonStyle(.bordered)
                                    .cornerRadius(20)
                                    .tint(timerRunning ? .green : .pink)

                                    Button("Reset") {
                                        totalSeconds = 30
                                        totalSeries = 8
                                        restSeconds = 15
                                        resetTimer()
                                    }
                                    .font(.system(size: 50, weight: .bold))
                                    .frame(width: 200, height: 80)
                                    .padding()
                                    .buttonStyle(.bordered)
                                    .tint(.purple)
                                    .cornerRadius(20)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        }
                        .frame(width: geo.size.width * 0.6)

                        // Pravá 3/4 šírky pre sériu/prestávku a nastavenia
                        ZStack {
                            VStack(spacing: 40) {
                                if inRestPeriod {
                                    Text("Prestávka")
                                        .font(.system(size: 100, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(20)
                                } else {
                                    Text("Séria: \(currentSeries)/\(totalSeries)")
                                        .font(.system(size: 60, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(20)
                                }

                                Button("Uprav časovač") {
                                    showSettings.toggle()
                                }
                                .font(.system(size: 30, weight: .bold))
                                .frame(height: 80)
                                .padding()
                                .buttonStyle(.bordered)
                                .tint(.purple)
                                .cornerRadius(20)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        }
                        .frame(width: geo.size.width * 0.4)
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
                    Slider(value: $sliderSeconds, in: 10...60)
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
            .font(.system(size: 30, weight: .bold))
            .frame(height: 80)
            .padding()
            .buttonStyle(.bordered)
            .tint(.pink)
            .cornerRadius(20)
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [
                Color.pink.opacity(0.3),
                Color.purple.opacity(0.3)
            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        )
    }
}
