import SwiftUI

struct SplashScreenView: View {
    @AppStorage("packwise_is_light_theme") private var isLightTheme = false
    @State private var logoScale: CGFloat = 0.68
    @State private var logoOpacity = 0.0
    @State private var textOpacity = 0.0
    @State private var badgeOpacity = 0.0
    @State private var glowOpacity = 0.18
    @State private var glowScale: CGFloat = 0.8
    @State private var progress: Double = 0.0
    @State private var showMainView = false

    var body: some View {
        ZStack {
            if showMainView {
                NavigationStack {
                    ProductInputView()
                }
                .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                splashContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: showMainView)
    }

    private var splashContent: some View {
        ZStack {
            background
            ambientGlow

            VStack(spacing: 34) {
                Spacer()

                logoSection
                brandSection
                featureBadges

                Spacer()

                bottomSection
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 34)
        }
        .onAppear {
            startSplashAnimation()
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: isLightTheme
                ? [
                    Color(red: 0.91, green: 0.97, blue: 1.00),
                    Color(red: 0.82, green: 0.93, blue: 1.00),
                    Color(red: 0.96, green: 0.98, blue: 1.00)
                ]
                : [
                    Color.black,
                    Color(red: 0.03, green: 0.06, blue: 0.14),
                    Color(red: 0.02, green: 0.13, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: isLightTheme
                ? [
                    Color.yellow.opacity(0.20),
                    Color.cyan.opacity(0.12),
                    Color.clear
                ]
                : [
                    Color.cyan.opacity(0.18),
                    Color.blue.opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }

    private var ambientGlow: some View {
        ZStack {
            Circle()
                .fill(isLightTheme ? Color.yellow.opacity(0.22) : Color.blue.opacity(0.25))
                .frame(width: 260, height: 260)
                .blur(radius: 75)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)
                .offset(y: -120)

            Circle()
                .fill(isLightTheme ? Color.cyan.opacity(0.14) : Color.cyan.opacity(0.16))
                .frame(width: 180, height: 180)
                .blur(radius: 65)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)
                .offset(x: 110, y: 90)
        }
    }

    private var logoSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 38)
                .fill(
                    LinearGradient(
                        colors: [
                            isLightTheme ? Color.white.opacity(0.88) : Color.white.opacity(0.14),
                            isLightTheme ? Color.white.opacity(0.62) : Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 168, height: 168)
                .overlay(
                    RoundedRectangle(cornerRadius: 38)
                        .stroke(isLightTheme ? Color.black.opacity(0.05) : Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .cyan.opacity(0.22), radius: 30, x: 0, y: 18)

            RoundedRectangle(cornerRadius: 30)
                .fill(isLightTheme ? Color.white.opacity(0.72) : Color.black.opacity(0.18))
                .frame(width: 132, height: 132)

            Image("packwise_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 108)
                .shadow(color: .blue.opacity(0.45), radius: 22, x: 0, y: 10)
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
    }

    private var brandSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Text("PackWise")
                    .foregroundStyle(isLightTheme ? Color(red: 0.04, green: 0.08, blue: 0.16) : .white)

                Text(" AI")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .font(.system(size: 42, weight: .heavy, design: .rounded))
            .minimumScaleFactor(0.8)

            Text("Akıllı Analiz, Güvenli Teslimat")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isLightTheme ? Color(red: 0.22, green: 0.30, blue: 0.40) : .white.opacity(0.78))

            Text("E-ticaret satıcıları için yapay zeka destekli ürün risk analizi")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isLightTheme ? Color(red: 0.38, green: 0.45, blue: 0.56) : .white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .opacity(textOpacity)
    }

    private var featureBadges: some View {
        HStack(spacing: 10) {
            splashBadge(icon: "photo.badge.magnifyingglass", text: "Görsel Tanıma")
            splashBadge(icon: "shippingbox.fill", text: "Paketleme")
            splashBadge(icon: "arrow.uturn.backward.circle.fill", text: "İade Riski")
        }
        .opacity(badgeOpacity)
    }

    private func splashBadge(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())

            Text(text)
                .font(.caption2.bold())
        }
        .foregroundStyle(isLightTheme ? Color(red: 0.08, green: 0.12, blue: 0.20) : .white.opacity(0.84))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isLightTheme ? Color.white.opacity(0.72) : Color.white.opacity(0.09))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isLightTheme ? Color.black.opacity(0.05) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var bottomSection: some View {
        VStack(spacing: 14) {
            ProgressView(value: progress)
                .tint(.cyan)
                .frame(maxWidth: 210)

            Text("Satıcı asistanı hazırlanıyor...")
                .font(.caption)
                .foregroundStyle(isLightTheme ? Color(red: 0.40, green: 0.47, blue: 0.57) : .white.opacity(0.52))
        }
        .opacity(textOpacity)
    }

    private func startSplashAnimation() {
        withAnimation(.spring(response: 0.9, dampingFraction: 0.72)) {
            logoScale = 1
            logoOpacity = 1
        }

        withAnimation(.easeIn(duration: 0.7).delay(0.22)) {
            textOpacity = 1
        }

        withAnimation(.easeIn(duration: 0.7).delay(0.55)) {
            badgeOpacity = 1
        }

        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            glowOpacity = 0.55
            glowScale = 1.15
        }

        withAnimation(.easeInOut(duration: 3.0)) {
            progress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                showMainView = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
