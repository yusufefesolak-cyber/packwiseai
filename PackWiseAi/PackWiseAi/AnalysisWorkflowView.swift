import SwiftUI

struct AnalysisWorkflowView: View {
    let productTitle: String
    let productDescription: String
    let productImage: UIImage?
    let productImages: [UIImage]
    let weight: String
    let size: String

    @AppStorage("packwise_is_light_theme") private var isLightTheme = false

    @State private var currentStep = 0
    @State private var navigateToResults = false
    @State private var analysisResult: AnalysisResult?
    @State private var isAnalyzing = true
    @State private var showError = false
    @State private var errorMessage = ""

    init(
        productTitle: String,
        productDescription: String,
        productImage: UIImage?,
        productImages: [UIImage] = [],
        weight: String,
        size: String
    ) {
        self.productTitle = productTitle
        self.productDescription = productDescription
        self.productImage = productImage
        self.productImages = productImages.isEmpty ? productImage.map { [$0] } ?? [] : productImages
        self.weight = weight
        self.size = size
    }

    private let workflowSteps = [
        WorkflowStep(
            icon: "eye.fill",
            title: "Visual Agent",
            description: "Görsellerden ürün tipi ve materyal sinyalleri okunuyor."
        ),
        WorkflowStep(
            icon: "arrow.uturn.backward.circle.fill",
            title: "Return Risk Agent",
            description: "İade ihtimali ve beklenti uyuşmazlığı kontrol ediliyor."
        ),
        WorkflowStep(
            icon: "shippingbox.fill",
            title: "Damage Agent",
            description: "Kırılganlık ve kargo hasarı riski değerlendiriliyor."
        ),
        WorkflowStep(
            icon: "wand.and.stars.inverse",
            title: "Listing Agent",
            description: "Başlık, açıklama ve aksiyon önerileri hazırlanıyor."
        )
    ]

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    topHeroSection

                    if let primaryImage {
                        productPreviewCard(image: primaryImage)
                    }

                    if orderedAnalysisImages.count > 1 {
                        multiImageSummaryCard
                    }

                    aiStatusCard

                    agentThinkingCard

                    workflowCard
                    footerSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 34)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await runWorkflow()
        }
        .navigationDestination(isPresented: $navigateToResults) {
            if let analysisResult {
                AnalysisResultView(
                    productTitle: productTitle,
                    productImage: primaryImage,
                    productImages: orderedAnalysisImages,
                    result: analysisResult
                )
            }
        }
        .alert("Analiz Hatası", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Image Ordering

    private var primaryImage: UIImage? {
        productImage ?? productImages.first
    }

    private var orderedAnalysisImages: [UIImage] {
        guard let productImage else {
            return Array(productImages.prefix(4))
        }

        let remainingImages = productImages.filter { $0 !== productImage }

        return Array(([productImage] + remainingImages).prefix(4))
    }

    // MARK: - Theme

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
                center: .topTrailing,
                startRadius: 40,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }

    private var primaryTextColor: Color {
        isLightTheme
        ? Color(red: 0.04, green: 0.08, blue: 0.16)
        : .white
    }

    private var secondaryTextColor: Color {
        isLightTheme
        ? Color(red: 0.22, green: 0.30, blue: 0.40)
        : .white.opacity(0.70)
    }

    private var mutedTextColor: Color {
        isLightTheme
        ? Color(red: 0.40, green: 0.47, blue: 0.57)
        : .white.opacity(0.55)
    }

    private var cardBackgroundColor: Color {
        isLightTheme
        ? Color.white.opacity(0.76)
        : Color.white.opacity(0.08)
    }

    private var cardStrokeColor: Color {
        isLightTheme
        ? Color.black.opacity(0.06)
        : Color.white.opacity(0.08)
    }

    private var inactiveIconColor: Color {
        isLightTheme
        ? Color.black.opacity(0.35)
        : Color.white.opacity(0.45)
    }

    private var inactiveTextColor: Color {
        isLightTheme
        ? Color.black.opacity(0.42)
        : Color.white.opacity(0.48)
    }

    // MARK: - Header

    private var topHeroSection: some View {
        VStack(spacing: 9) {
            HStack(spacing: 12) {
                compactAIIcon

                Text("PackWise AI Analiz Motoru")
                    .font(.system(size: 27, weight: .heavy, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.78)
                    .lineLimit(2)

                compactAIIcon
            }
            .frame(maxWidth: .infinity)

            Text(
                productTitle.isEmpty
                ? "E-ticaret ürününe özel risk analizi hazırlanıyor."
                : productTitle
            )
            .font(.subheadline)
            .foregroundStyle(secondaryTextColor)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.horizontal, 12)
        }
        .padding(.top, 2)
    }

    private var compactAIIcon: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.14))
                .frame(width: 44, height: 44)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.green.opacity(0.70), .cyan.opacity(0.42)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: 48, height: 48)

            Circle()
                .fill(
                    isLightTheme
                    ? Color.white.opacity(0.74)
                    : Color.black.opacity(0.24)
                )
                .frame(width: 38, height: 38)

            Image(systemName: "sparkles")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    // MARK: - Product Preview

    private func productPreviewCard(image: UIImage) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 28))

            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))

            VStack(alignment: .leading, spacing: 6) {
                Text("AI Görsel Analizi")
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                Text("Gemini Vision ürün görselini işliyor")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(18)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(cardStrokeColor, lineWidth: 1)
        )
    }

    // MARK: - Multi Image Card

    private var multiImageSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "photo.stack.fill")
                        .foregroundStyle(.cyan)

                    Text("Çoklu Görsel Analizi")
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)
                }

                Spacer()

                Text("\(orderedAnalysisImages.count) foto")
                    .font(.caption.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.cyan)
                    .clipShape(Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(orderedAnalysisImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 66, height: 66)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            index == 0
                                            ? Color.cyan
                                            : cardStrokeColor,
                                            lineWidth: index == 0 ? 2 : 1
                                        )
                                )

                            if index == 0 {
                                Text("Ana")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.cyan)
                                    .clipShape(Capsule())
                                    .padding(5)
                            }
                        }
                    }
                }
            }

            Text("AI analizde Ana fotoğraf ilk görsel olarak gönderilir; ek fotoğraflar ürün açısı, detay, etiket ve güven kontrolü için kullanılır.")
                .font(.caption)
                .foregroundStyle(mutedTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(cardStrokeColor, lineWidth: 1)
        )
    }

    private var agentThinkingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.mint.opacity(0.16))
                        .frame(width: 38, height: 38)

                    Image(systemName: "brain.head.profile")
                        .font(.headline)
                        .foregroundStyle(.mint)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("AI Düşünme Katmanı")
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)

                    Text(activeAgentReasoning)
                        .font(.caption)
                        .foregroundStyle(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text("Agentic")
                    .font(.caption2.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.mint)
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                ForEach(workflowSteps.indices, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? Color.mint : (isLightTheme ? Color.black.opacity(0.10) : Color.white.opacity(0.10)))
                        .frame(height: 6)
                        .animation(.easeInOut(duration: 0.25), value: currentStep)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: isLightTheme
                ? [Color.white.opacity(0.82), Color.mint.opacity(0.10)]
                : [Color.white.opacity(0.07), Color.mint.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.mint.opacity(isLightTheme ? 0.18 : 0.12), lineWidth: 1)
        )
    }

    // MARK: - AI Status

    private var aiStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)

                    Text("AI Motoru Aktif")
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)
                }

                Spacer()

                Text("%\(Int(progressValue * 100))")
                    .font(.title3.bold())
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 999)
                            .fill(
                                isLightTheme
                                ? Color.black.opacity(0.08)
                                : Color.white.opacity(0.08)
                            )
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 999)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geo.size.width * progressValue,
                                height: 12
                            )
                    }
                }
                .frame(height: 12)

                Text(dynamicStatusText)
                    .font(.subheadline)
                    .foregroundStyle(secondaryTextColor)
            }
        }
        .padding(20)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(
                    isLightTheme
                    ? Color.black.opacity(0.05)
                    : Color.green.opacity(0.10),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Workflow Card

    private var workflowCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Canlı AI İşlem Akışı")
                    .font(.title3.bold())
                    .foregroundStyle(primaryTextColor)

                Spacer()

                Text("\(currentStep + 1)/\(workflowSteps.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }

            VStack(spacing: 16) {
                ForEach(Array(workflowSteps.enumerated()), id: \.offset) { index, step in
                    workflowRow(step: step, index: index)
                }
            }
        }
        .padding(22)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(cardStrokeColor, lineWidth: 1)
        )
    }

    private func workflowRow(step: WorkflowStep, index: Int) -> some View {
        let isCompleted = index < currentStep
        let isActive = index == currentStep

        return HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(
                            isCompleted || isActive
                            ? Color.green.opacity(0.16)
                            : (
                                isLightTheme
                                ? Color.black.opacity(0.06)
                                : Color.white.opacity(0.06)
                            )
                        )
                        .frame(width: 58, height: 58)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.headline.bold())
                            .foregroundStyle(.green)
                    } else if isActive {
                        ProgressView()
                            .tint(.green)
                    } else {
                        Image(systemName: step.icon)
                            .foregroundStyle(inactiveIconColor)
                    }
                }

                if index != workflowSteps.count - 1 {
                    Rectangle()
                        .fill(
                            isCompleted
                            ? Color.green.opacity(0.5)
                            : (
                                isLightTheme
                                ? Color.black.opacity(0.08)
                                : Color.white.opacity(0.08)
                            )
                        )
                        .frame(width: 2, height: 38)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(step.title)
                        .font(.headline)
                        .foregroundStyle(
                            isCompleted || isActive
                            ? primaryTextColor
                            : inactiveTextColor
                        )

                    if isActive {
                        Text("AKTİF")
                            .font(.caption2.bold())
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green)
                            .clipShape(Capsule())
                    }
                }

                Text(step.description)
                    .font(.subheadline)
                    .foregroundStyle(
                        isCompleted || isActive
                        ? secondaryTextColor
                        : mutedTextColor.opacity(0.70)
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    isActive
                    ? Color.green.opacity(0.08)
                    : (
                        isLightTheme
                        ? Color.white.opacity(0.50)
                        : Color.white.opacity(0.03)
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    isActive
                    ? Color.green.opacity(0.18)
                    : Color.clear,
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.25), value: currentStep)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 16) {
            if isAnalyzing {
                Text("PackWise AI raporu hazırlanıyor...")
                    .font(.footnote)
                    .foregroundStyle(mutedTextColor)

                Text("Gemini destekli analiz motoru aktif")
                    .font(.caption)
                    .foregroundStyle(.green.opacity(0.85))
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Status

    private var progressValue: Double {
        Double(currentStep + 1) / Double(workflowSteps.count)
    }

    private var dynamicStatusText: String {
        switch currentStep {
        case 0:
            return "Visual Agent görselleri okuyor"
        case 1:
            return "Return Risk Agent iade sinyallerini değerlendiriyor"
        case 2:
            return "Damage Agent kargo hasarı riskini hesaplıyor"
        default:
            return "Listing Agent final raporu hazırlıyor"
        }
    }

    private var activeAgentReasoning: String {
        switch currentStep {
        case 0:
            return orderedAnalysisImages.count > 1
            ? "Ana görsel ve ek açılar birlikte okunuyor."
            : "Ana görselden ürün tipi çıkarılıyor."
        case 1:
            return "Eksik bilgi ve beklenti farkı aranıyor."
        case 2:
            return "Materyal, kırılganlık ve paketleme ihtiyacı kontrol ediliyor."
        default:
            return "Skorlar, öneriler ve satış metni birleştiriliyor."
        }
    }

    // MARK: - Workflow

    private func runWorkflow() async {
        do {
            for index in workflowSteps.indices {
                await MainActor.run {
                    currentStep = index
                }

                try? await Task.sleep(nanoseconds: 700_000_000)
            }

            let result = try await GeminiService.shared.analyzeProduct(
                title: productTitle,
                description: productDescription,
                weight: weight,
                size: size,
                image: primaryImage,
                images: orderedAnalysisImages
            )

            await MainActor.run {
                AnalysisHistoryStore.shared.save(
                    title: productTitle,
                    result: result,
                    image: primaryImage
                )

                self.analysisResult = result
                self.isAnalyzing = false
            }

            try? await Task.sleep(nanoseconds: 800_000_000)

            await MainActor.run {
                navigateToResults = true
            }

        } catch {
            await MainActor.run {
                self.isAnalyzing = false
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
}

// MARK: - Workflow Step

struct WorkflowStep {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AnalysisWorkflowView(
            productTitle: "Kablosuz Bluetooth Kulaklık",
            productDescription: "Yapay zeka destekli örnek ürün açıklaması",
            productImage: nil,
            weight: "300g",
            size: "20x10"
        )
    }
}
