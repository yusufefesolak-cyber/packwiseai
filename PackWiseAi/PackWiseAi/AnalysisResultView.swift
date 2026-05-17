import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct AnalysisResultView: View {
    let productTitle: String
    let productImage: UIImage?
    let productImages: [UIImage]
    let result: AnalysisResult
    let showsBackButton: Bool

    init(
        productTitle: String,
        productImage: UIImage?,
        productImages: [UIImage] = [],
        result: AnalysisResult,
        showsBackButton: Bool = false
    ) {
        self.productTitle = productTitle
        self.productImage = productImage
        self.productImages = productImages
        self.result = result
        self.showsBackButton = showsBackButton
    }
    @State private var copiedToastText = ""
    @State private var showCopiedToast = false
    @State private var selectedRiskInfo: RiskInfo?
    @State private var exportURL: URL?
    @State private var showExportSheet = false
    @State private var selectedPreviewImageIndex = 0
    @AppStorage("packwise_is_light_theme") private var isLightTheme = false
    @Environment(\.dismiss) private var dismiss

    var displayTitle: String {
        let manualTitle = productTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let aiTitle = result.generatedTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        if !manualTitle.isEmpty {
            return manualTitle
        }

        if !aiTitle.isEmpty {
            return aiTitle
        }

        return "Analiz Edilen Ürün"
    }

    var riskColor: Color {
        if result.overallRiskScore >= 75 {
            return .red
        } else if result.overallRiskScore >= 45 {
            return .orange
        } else {
            return .green
        }
    }

    var riskLevelText: String {
        if result.overallRiskScore >= 75 {
            return "Yüksek Risk"
        } else if result.overallRiskScore >= 45 {
            return "Orta Risk"
        } else {
            return "Düşük Risk"
        }
    }

    var sellerReadinessScore: Int {
        max(0, 100 - result.overallRiskScore)
    }

    var marketplaceStatus: String {
        sellerReadinessScore >= 70 ? "Satışa Hazır" : "İyileştirme Gerekli"
    }

    private var previewImages: [UIImage] {
        if !productImages.isEmpty {
            return productImages
        }

        if let productImage {
            return [productImage]
        }

        return []
    }

    private var activePreviewImage: UIImage? {
        let images = previewImages
        guard !images.isEmpty else { return nil }
        let safeIndex = min(max(selectedPreviewImageIndex, 0), images.count - 1)
        return images[safeIndex]
    }


    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 22) {

                    VStack(spacing: 10) {
                        Text("AI Analiz Sonucu")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(primaryTextColor)

                        Text("AI tarafından oluşturulan ürün analizi")
                            .foregroundStyle(secondaryTextColor)
                    }
                    .padding(.top, 10)

                    productPreviewCard

                    VStack(spacing: 16) {
                        scoreCard(
                            title: "Genel Risk Skoru",
                            score: "\(result.overallRiskScore) / 100",
                            subtitle: riskLevelText,
                            color: riskColor,
                            info: generalRiskInfo
                        )

                        scoreCard(
                            title: "Satışa Hazırlık Skoru",
                            score: "\(sellerReadinessScore) / 100",
                            subtitle: marketplaceStatus,
                            color: sellerReadinessScore >= 70 ? .green : .orange,
                            info: sellerReadinessInfo
                        )

                        HStack(spacing: 10) {
                            miniCard(
                                icon: "arrow.uturn.backward.circle.fill",
                                title: "İade Riski",
                                value: result.returnRisk,
                                info: returnRiskInfo
                            )

                            miniCard(
                                icon: "shippingbox.fill",
                                title: "Hasar Riski",
                                value: result.damageRisk,
                                info: damageRiskInfo
                            )
                        }

                        HStack(spacing: 10) {
                            miniCard(
                                icon: "cube.fill",
                                title: "Materyal",
                                value: result.material
                            )

                            miniCard(
                                icon: "square.grid.2x2.fill",
                                title: "Ürün Kategorisi",
                                value: result.productCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Genel Ürün" : result.productCategory
                            )
                        }

                        copyableInfoCard(
                            icon: "tag.fill",
                            title: "AI İlan Başlığı",
                            content: result.generatedTitle.isEmpty ? displayTitle : result.generatedTitle,
                            copiedMessage: "İlan başlığı kopyalandı"
                        )

                        copyableInfoCard(
                            icon: "text.alignleft",
                            title: "AI Satış Açıklaması",
                            content: result.generatedDescription.isEmpty ? "AI tarafından oluşturulan satış açıklaması bulunamadı." : result.generatedDescription,
                            copiedMessage: "Satış açıklaması kopyalandı"
                        )

                        infoCard(
                            icon: "sparkles",
                            title: "Paketleme Önerisi",
                            content: result.packagingRecommendation
                        )


                        infoCard(
                            icon: "text.badge.checkmark",
                            title: "İlan İyileştirme Önerisi",
                            content: result.descriptionImprovement
                        )

                        photoGuideCard

                        customerReviewSimulationCard

                        riskReductionSimulationCard
                    }
                    .padding(.horizontal, 20)

                    shareReportButton

                    newAnalysisButton

                    Spacer(minLength: 30)
                }
            }

            copiedToast
        }
        .navigationTitle("Analiz Sonucu")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!showsBackButton)
        .toolbar {
            if showsBackButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.bold())
                            .foregroundStyle(primaryTextColor)
                            .frame(width: 34, height: 34)
                            .background(cardBackgroundColor)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(cardStrokeColor, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .alert(item: $selectedRiskInfo) { info in
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("Anladım"))
            )
        }
        .sheet(isPresented: $showExportSheet) {
            if let exportURL {
                ActivityViewController(activityItems: [exportURL])
            }
        }
    }

    private struct ActivityViewController: UIViewControllerRepresentable {
        let activityItems: [Any]

        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil
            )
        }

        func updateUIViewController(
            _ uiViewController: UIActivityViewController,
            context: Context
        ) {
        }
    }

    private var aiIntelligenceCard: some View {
        mvpInsightCard(
            icon: "chart.line.uptrend.xyaxis.circle.fill",
            title: "Skoru Ne Etkiledi?",
            subtitle: "Risk skorunun arkasındaki ana nedenler",
            badge: "Explainable",
            color: riskColor,
            items: normalizedScoreExplanations
        )
    }

    private var categoryExpertiseCard: some View {
        mvpInsightCard(
            icon: "graduationcap.fill",
            title: "Kategori Uzmanı Notları",
            subtitle: "Bu ürün kategorisine özel satış içgörüleri",
            badge: "Uzman",
            color: .purple,
            items: normalizedCategoryExpertise
        )
    }

    private var uniqueInsightsCard: some View {
        mvpInsightCard(
            icon: "sparkles.rectangle.stack.fill",
            title: "Ürüne Özel AI İçgörüleri",
            subtitle: "Görsel ve ürün bilgilerine göre özgün yorumlar",
            badge: "Özgün",
            color: .mint,
            items: normalizedUniqueInsights
        )
    }

    private var normalizedScoreExplanations: [String] {
        let cleaned = result.scoreExplanation
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !cleaned.isEmpty {
            return Array(cleaned.prefix(4))
        }

        var fallback: [String] = []

        if result.returnRisk.lowercased().contains("yüksek") || result.returnRisk.lowercased().contains("orta") {
            fallback.append("İade beklentisi skoru yukarı çekti")
        } else {
            fallback.append("İade riski düşük seviyede kaldı")
        }

        if result.damageRisk.lowercased().contains("yüksek") || result.damageRisk.lowercased().contains("orta") {
            fallback.append("Kargo hasarı riski skoru etkiledi")
        } else {
            fallback.append("Hasar riski sınırlı görünüyor")
        }

        if result.fragilityLevel.lowercased().contains("yüksek") || result.fragilityLevel.lowercased().contains("orta") {
            fallback.append("Materyal hassasiyeti risk puanını artırdı")
        }

        fallback.append("Açıklama ve görsel kalitesi satış hazırlığını etkiledi")

        return Array(fallback.prefix(4))
    }

    private var normalizedCategoryExpertise: [String] {
        let cleaned = result.categoryExpertise
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !cleaned.isEmpty {
            return Array(cleaned.prefix(4))
        }

        let category = result.productCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        let visibleCategory = category.isEmpty ? "Bu kategori" : category

        return [
            "\(visibleCategory) için net ölçü bilgisi önemlidir",
            "Kategoriye uygun paketleme güveni artırır",
            "Detay fotoğrafları iade ihtimalini azaltır",
            "Alıcı beklentisi açıklamayla net yönetilmelidir"
        ]
    }

    private var normalizedUniqueInsights: [String] {
        let cleaned = result.uniqueInsights
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !cleaned.isEmpty {
            return Array(cleaned.prefix(4))
        }

        return [
            "Ürün bilgileri satış açıklamasına dönüştürülebilir",
            "Ana görsel ilan performansını doğrudan etkiler",
            "Ek detaylar alıcı güvenini artırabilir",
            "Paketleme dili satış sonrası memnuniyeti destekler"
        ]
    }

    private func mvpInsightCard(
        icon: String,
        title: String,
        subtitle: String,
        badge: String,
        color: Color,
        items: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.16))
                        .frame(width: 42, height: 42)

                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(mutedTextColor)
                }

                Spacer()

                Text(badge)
                    .font(.caption2.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(color)
                    .clipShape(Capsule())
            }

            VStack(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    mvpInsightRow(number: index + 1, text: item, color: color)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: isLightTheme
                ? [Color.white.opacity(0.86), color.opacity(0.10)]
                : [color.opacity(0.11), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(color.opacity(isLightTheme ? 0.18 : 0.12), lineWidth: 1)
        )
    }

    private func mvpInsightRow(number: Int, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.16))
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundStyle(color)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(isLightTheme ? Color.white.opacity(0.66) : Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var photoGuideCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.16))
                        .frame(width: 42, height: 42)

                    Image(systemName: "camera.viewfinder")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Fotoğraf Rehberi")
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)

                    Text(photoGuideSubtitle)
                        .font(.caption)
                        .foregroundStyle(mutedTextColor)
                }

                Spacer()

                Text(photoGuideBadgeText)
                    .font(.caption2.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(photoGuideBadgeColor)
                    .clipShape(Capsule())
            }

            VStack(spacing: 12) {
                ForEach(dynamicPhotoGuidePlan, id: \.title) { item in
                    photoGuideRow(title: item.title, text: item.text, icon: item.icon)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: isLightTheme
                ? [
                    Color.white.opacity(0.86),
                    Color.blue.opacity(0.10)
                ]
                : [
                    Color.blue.opacity(0.10),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.blue.opacity(isLightTheme ? 0.18 : 0.12), lineWidth: 1)
        )
    }
    private var dynamicPhotoGuidePlan: [(title: String, text: String, icon: String)] {
        let suggestions = dynamicPhotoGuideSuggestions

        let titles = photoGuideIsStrongEnough
        ? ["Kapak Görseli", "Tutarlılık", "Güven Detayı"]
        : ["Eksik Açı", "Detay Çekimi", "Güven Fotoğrafı"]

        let icons = photoGuideIsStrongEnough
        ? ["star.fill", "camera.filters", "checkmark.seal.fill"]
        : ["camera.viewfinder", "magnifyingglass", "shield.checkered"]

        return suggestions.enumerated().map { index, suggestion in
            (
                title: index < titles.count ? titles[index] : "Fotoğraf Önerisi",
                text: suggestion,
                icon: index < icons.count ? icons[index] : "camera.fill"
            )
        }
    }

    private var photoGuideBadgeText: String {
        if photoGuideIsStrongEnough {
            return "Gayet İyi"
        }

        if result.returnRisk.lowercased().contains("yüksek") || result.damageRisk.lowercased().contains("yüksek") || result.fragilityLevel.lowercased().contains("yüksek") {
            return "Kritik"
        }

        if result.returnRisk.lowercased().contains("orta") || result.damageRisk.lowercased().contains("orta") {
            return "Öneri"
        }

        return "MVP+"
    }

    private var photoGuideBadgeColor: Color {
        if photoGuideIsStrongEnough {
            return .green
        }

        if photoGuideBadgeText == "Kritik" {
            return .orange
        }

        return .blue
    }

    private var photoGuideSubtitle: String {
        if photoGuideIsStrongEnough {
            return "Fotoğraf seti yeterli görünüyor, küçük iyileştirmeler önerildi"
        }

        return "Ürün tipine göre eksik açı ve detay önerileri"
    }

    private var photoGuideIsStrongEnough: Bool {
        let riskIsLow = result.returnRisk.lowercased().contains("düşük") && result.damageRisk.lowercased().contains("düşük")
        let scoreIsSafe = result.overallRiskScore < 45
        let hasClearListing = !result.generatedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !result.generatedDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return riskIsLow && scoreIsSafe && hasClearListing
    }

    private var dynamicPhotoGuideSuggestions: [String] {
        var suggestions: [String] = []

        let category = result.productCategory.lowercased()
        let material = result.material.lowercased()
        let title = displayTitle.lowercased()
        let description = result.generatedDescription.lowercased()
        let combined = "\(category) \(material) \(title) \(description)"
        let returnRisk = result.returnRisk.lowercased()
        let damageRisk = result.damageRisk.lowercased()
        let fragility = result.fragilityLevel.lowercased()

        if photoGuideIsStrongEnough {
            suggestions.append("Fotoğraf seti yeterli görünüyor; aynı ışıkta tutarlı çekim kullan")
            suggestions.append("İlan kapağı için en net ve sade açıyı ana görsel yap")
            suggestions.append("Güven için paketli veya ölçekli tek ek detay fotoğrafı ekle")
            return suggestions
        }

        if combined.contains("cam") || combined.contains("seramik") || combined.contains("kupa") || combined.contains("bardak") || combined.contains("vazo") || category.contains("mutfak") {
            suggestions.append("Yansımayı azaltmak için ürünü 45° yan açıdan çek")
            suggestions.append("Ağız, kulp, taban ve yüzeyde çatlak olmadığını yakın çek")
            suggestions.append("Boyutu anlatmak için elde veya masada ölçekli fotoğraf ekle")
        }

        if combined.contains("plastik") || combined.contains("kova") || combined.contains("kap") || combined.contains("saklama") || combined.contains("balık") || combined.contains("yem") {
            suggestions.append("Kapak, iç hacim ve taşıma sapını ayrı ayrı göster")
            suggestions.append("İç kısmı boş ve dolu kullanım senaryosu gibi çek")
            suggestions.append("Boyutu belli olsun diye yanında ölçek oluşturacak obje kullan")
        }

        if combined.contains("elektronik") || combined.contains("telefon") || combined.contains("kulaklık") || combined.contains("mouse") || combined.contains("bilgisayar") || combined.contains("şarj") {
            suggestions.append("Port, tuş, bağlantı noktası ve varsa model etiketini yakın çek")
            suggestions.append("Kutu içeriğini aksesuarlarla birlikte ayrı fotoğrafta göster")
            suggestions.append("Çalışır durumda ekran/ışık göstergesi varsa net şekilde çek")
        }

        if combined.contains("ayakkabı") || combined.contains("giyim") || combined.contains("tekstil") || combined.contains("kıyafet") || category.contains("moda") {
            suggestions.append("Ön, arka, yan ve taban açılarını ayrı fotoğraf yap")
            suggestions.append("Doku, renk ve kumaş kalınlığı için doğal ışıkta yakın çek")
            suggestions.append("Beden etiketi ve ölçü bilgisini okunabilir şekilde göster")
        }

        if combined.contains("çanta") || combined.contains("cüzdan") {
            suggestions.append("İç hacim, bölmeler ve fermuar detayını açık şekilde çek")
            suggestions.append("Askı, köşe ve dikiş kalitesini yakın detayla göster")
            suggestions.append("Boyutu göstermek için elde veya omuzda kullanım fotoğrafı ekle")
        }

        if combined.contains("kozmetik") || combined.contains("parfüm") || combined.contains("krem") || combined.contains("şampuan") || category.contains("kozmetik") {
            suggestions.append("İçerik, hacim ve son kullanma bilgisi olan etiketi net çek")
            suggestions.append("Kapak, pompa veya sızdırmazlık kısmını yakın göster")
            suggestions.append("Ürünün mühürlü/kapalı halini güven için fotoğrafa ekle")
        }

        if combined.contains("bitki") || combined.contains("çiçek") || combined.contains("fidan") || category.contains("canlı") {
            suggestions.append("Yaprak, gövde ve genel sağlık durumunu yakın çekimle göster")
            suggestions.append("Saksı, toprak ve kök bölgesini ayrı fotoğrafla belirt")
            suggestions.append("Boyutu anlamak için yanına ölçek oluşturacak obje koy")
        }

        if combined.contains("mobilya") || combined.contains("masa") || combined.contains("sandalye") || combined.contains("raf") {
            suggestions.append("Kurulu kullanım halini geniş açıyla net çek")
            suggestions.append("Köşe, vida, birleşim ve yüzey çiziklerini yakın göster")
            suggestions.append("Ölçü algısı için odada veya yanında referans obje ile çek")
        }

        if combined.contains("kitap") || combined.contains("defter") || combined.contains("kağıt") || combined.contains("kırtasiye") {
            suggestions.append("Ön kapak, arka kapak ve sayfa kenarlarını ayrı göster")
            suggestions.append("Yıpranma, ezik veya leke varsa yakın detay fotoğrafı ekle")
            suggestions.append("Boyut ve sayfa durumu için açık sayfa çekimi kullan")
        }

        if combined.contains("oyuncak") || combined.contains("figür") || combined.contains("lego") {
            suggestions.append("Parça sayısı ve kutu içeriğini toplu şekilde göster")
            suggestions.append("Yaş etiketi, güvenlik uyarısı veya marka bilgisini net çek")
            suggestions.append("Küçük parçaları kayıp algısı olmaması için yakın göster")
        }

        if returnRisk.contains("yüksek") || returnRisk.contains("orta") {
            suggestions.append("Yanlış beklentiyi azaltmak için kullanım senaryosu fotoğrafı ekle")
        }

        if damageRisk.contains("yüksek") || fragility.contains("yüksek") {
            suggestions.append("Paketlenmiş halini göstererek kargo güveni oluştur")
        }

        if suggestions.isEmpty {
            suggestions = [
                "Ürün fotoğrafı genel olarak yeterli; ana görseli sade tut",
                "Ön, arka ve yan açıdan net ışıkta ek fotoğraflar ekle",
                "Ölçü ve materyal algısı için yakın detay çekimi kullan"
            ]
        }

        var seen = Set<String>()
        let uniqueSuggestions = suggestions.filter { suggestion in
            if seen.contains(suggestion) { return false }
            seen.insert(suggestion)
            return true
        }

        return Array(uniqueSuggestions.prefix(3))
    }

    private func photoGuideRow(title: String, text: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.16))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(primaryTextColor)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(isLightTheme ? Color.white.opacity(0.66) : Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // --- Customer Review Simulation Card & helpers (moved here) ---
    private var customerReviewSimulationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.16))
                        .frame(width: 42, height: 42)

                    Image(systemName: "text.bubble.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Müşteri Yorumu Simülasyonu")
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)

                    Text("Olası alıcı yorumu, şikayet ve beklenti sinyalleri")
                        .font(.caption)
                        .foregroundStyle(mutedTextColor)
                }

                Spacer()

                Text("AI Simülasyon")
                    .font(.caption2.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }

            VStack(spacing: 12) {
                ForEach(dynamicCustomerReviewPlan, id: \.title) { review in
                    simulatedReviewBubble(title: review.title, text: review.text, sentiment: review.sentiment)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: isLightTheme
                ? [
                    Color.white.opacity(0.86),
                    Color.orange.opacity(0.10)
                ]
                : [
                    Color.orange.opacity(0.10),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.orange.opacity(isLightTheme ? 0.18 : 0.12), lineWidth: 1)
        )
    }

    private var dynamicCustomerReviewPlan: [(title: String, text: String, sentiment: Color)] {
        let reviews = dynamicCustomerReviewSimulations

        let titles = [
            "Olası Olumlu Yorum",
            "Olası Şikayet",
            "Beklenti Riski"
        ]

        let colors: [Color] = [.green, .orange, .red]

        return reviews.enumerated().map { index, review in
            (
                title: index < titles.count ? titles[index] : "Müşteri Yorumu",
                text: review,
                sentiment: index < colors.count ? colors[index] : .orange
            )
        }
    }

    private var dynamicCustomerReviewSimulations: [String] {
        var positive = "Ürün görseldeki gibi ve açıklamayla uyumlu görünüyor."
        var complaint = "Açıklamada birkaç detay daha olsaydı daha güven verirdi."
        var expectation = "Boyut, kullanım alanı veya kutu içeriği netleşirse beklenti daha iyi yönetilir."

        let category = result.productCategory.lowercased()
        let material = result.material.lowercased()
        let title = displayTitle.lowercased()
        let description = result.generatedDescription.lowercased()
        let combined = "\(category) \(material) \(title) \(description)"

        let returnRisk = result.returnRisk.lowercased()
        let damageRisk = result.damageRisk.lowercased()
        let fragility = result.fragilityLevel.lowercased()

        if combined.contains("cam") || combined.contains("seramik") || combined.contains("bardak") || combined.contains("kupa") || combined.contains("vazo") {
            positive = "Ürün şık duruyor, dekor veya kullanım için güzel görünüyor."
            complaint = "Kargo koruması zayıf olursa kırılma endişesi oluşabilir."
            expectation = "Ölçü ve kalınlık bilgisi yazılırsa alıcı beklentisi netleşir."
        } else if combined.contains("telefon") || combined.contains("kulaklık") || combined.contains("elektronik") || combined.contains("mouse") || combined.contains("bilgisayar") || combined.contains("şarj") {
            positive = "Model ve görünüm netse ürün güven verici algılanır."
            complaint = "Kutu içeriği veya uyumluluk eksikse alıcı soru sorabilir."
            expectation = "Garanti, aksesuar ve çalışma durumu açık yazılmalı."
        } else if combined.contains("ayakkabı") || combined.contains("giyim") || combined.contains("tekstil") || combined.contains("kıyafet") {
            positive = "Renk ve kumaş doğru görünürse ilan daha güven verir."
            complaint = "Beden veya kalıp farklı gelirse iade riski artabilir."
            expectation = "Ölçü, kalıp ve gerçek renk bilgisi net verilmelidir."
        } else if combined.contains("çanta") || combined.contains("cüzdan") {
            positive = "Dış görünüm ve kullanım tarzı alıcı için çekici olabilir."
            complaint = "İç hacim görünmezse beklenenden küçük algılanabilir."
            expectation = "İç bölme, fermuar ve ölçü fotoğrafları güven artırır."
        } else if combined.contains("kozmetik") || combined.contains("parfüm") || combined.contains("şampuan") || combined.contains("krem") {
            positive = "Ürün temiz ve kapalı görünürse güven hissi artar."
            complaint = "İçerik, hacim veya son kullanma bilgisi eksik kalabilir."
            expectation = "Mühür, kapak ve kullanım bilgisi net gösterilmelidir."
        } else if combined.contains("mobilya") || combined.contains("masa") || combined.contains("sandalye") || combined.contains("raf") {
            positive = "Kurulu kullanım fotoğrafı ürünü daha değerli gösterir."
            complaint = "Ölçü eksikse ürün alana uygun değilmiş gibi algılanabilir."
            expectation = "Ölçü, kurulum ve yüzey durumu açık belirtilmelidir."
        } else if combined.contains("bitki") || combined.contains("çiçek") || combined.contains("fidan") {
            positive = "Canlı ve sağlıklı görünüm alıcı güvenini artırır."
            complaint = "Taşımada ezilme veya solma endişesi oluşabilir."
            expectation = "Bakım, boyut ve teslimat hassasiyeti açıklanmalıdır."
        } else if combined.contains("kitap") || combined.contains("defter") || combined.contains("kırtasiye") {
            positive = "Kapak ve sayfa durumu netse güvenli ilan algısı oluşur."
            complaint = "Yıpranma, sayfa hasarı veya baskı bilgisi eksik kalabilir."
            expectation = "Kapak, sayfa kenarı ve baskı bilgisi gösterilmelidir."
        }

        if returnRisk.contains("yüksek") {
            expectation = "Açıklama beklentiyi net karşılamazsa iade ihtimali artabilir."
        } else if returnRisk.contains("orta") {
            expectation = "Ek ölçü ve detay bilgisi iade riskini azaltabilir."
        }

        if damageRisk.contains("yüksek") || fragility.contains("yüksek") {
            complaint = "Kargo güveni yeterince verilmezse hasar endişesi doğabilir."
        }

        if let firstReason = result.possibleReturnReasons.first,
           !firstReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            expectation = "Özellikle şu beklenti yönetilmeli: \(firstReason)"
        }

        return [positive, complaint, expectation]
    }

    private func simulatedReviewBubble(title: String, text: String, sentiment: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(sentiment.opacity(0.16))
                    .frame(width: 36, height: 36)

                Image(systemName: sentiment == .green ? "hand.thumbsup.fill" : (sentiment == .red ? "exclamationmark.triangle.fill" : "text.bubble.fill"))
                    .font(.caption.bold())
                    .foregroundStyle(sentiment)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(primaryTextColor)

                Text("\"\(text)\"")
                    .font(.subheadline)
                    .foregroundStyle(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(isLightTheme ? Color.white.opacity(0.66) : Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // --- End Customer Review Simulation Card & helpers ---

    private var productPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayTitle)
                        .font(.title2.bold())
                        .foregroundStyle(primaryTextColor)

                    Text("AI tarafından oluşturulan ürün analizi")
                        .font(.subheadline)
                        .foregroundStyle(secondaryTextColor)
                }

                Spacer()

                Text(riskLevelText)
                    .font(.caption.bold())
                    .foregroundStyle(riskColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(riskColor.opacity(0.18))
                    .clipShape(Capsule())
            }

            if let activePreviewImage {
                VStack(spacing: 12) {
                    Image(uiImage: activePreviewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 230)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay(alignment: .topTrailing) {
                            if previewImages.count > 1 {
                                Text("\(selectedPreviewImageIndex + 1)/\(previewImages.count)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.46))
                                    .clipShape(Capsule())
                                    .padding(10)
                            }
                        }

                    if previewImages.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(previewImages.enumerated()), id: \.offset) { index, image in
                                    Button {
                                        selectedPreviewImageIndex = index
                                    } label: {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 62, height: 62)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(index == selectedPreviewImageIndex ? Color.cyan : Color.white.opacity(0.16), lineWidth: index == selectedPreviewImageIndex ? 2.5 : 1)
                                            )
                                            .overlay(alignment: .bottomTrailing) {
                                                Text("\(index + 1)")
                                                    .font(.caption2.bold())
                                                    .foregroundStyle(.black)
                                                    .frame(width: 18, height: 18)
                                                    .background(index == selectedPreviewImageIndex ? Color.cyan : Color.white.opacity(0.82))
                                                    .clipShape(Circle())
                                                    .padding(4)
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 2)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption.bold())
                                .foregroundStyle(.cyan)

                            Text("AI analizi \(previewImages.count) görsel üzerinden desteklendi")
                                .font(.caption)
                                .foregroundStyle(mutedTextColor)

                            Spacer(minLength: 0)
                        }
                    }
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(isLightTheme ? Color.black.opacity(0.06) : Color.white.opacity(0.08))
                        .frame(height: 170)

                    VStack(spacing: 10) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundStyle(primaryTextColor.opacity(0.80))

                        Text("Ürün görseli eklenmedi")
                            .foregroundStyle(secondaryTextColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 20)
    }

    private func scoreCard(title: String, score: String, subtitle: String, color: Color, info: RiskInfo? = nil) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(secondaryTextColor)

                    if let info {
                        Button {
                            selectedRiskInfo = info
                        } label: {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white.opacity(0.92))
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.13))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(subtitle)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.16))
                    .clipShape(Capsule())
            }

            Spacer()

            Text(score)
                .font(.system(size: 29, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func miniCard(icon: String, title: String, value: String, info: RiskInfo? = nil) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(primaryTextColor.opacity(0.84))
                    .frame(maxWidth: .infinity)

                if let info {
                    Button {
                        selectedRiskInfo = info
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.92))
                            .frame(width: 22, height: 22)
                            .background(Color.white.opacity(0.13))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .offset(x: 2, y: -4)
                }
            }

            Text(title)
                .font(.caption2)
                .foregroundStyle(mutedTextColor)
                .lineLimit(1)

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(primaryTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
        }
        .frame(maxWidth: .infinity, minHeight: 68)
        .padding(.horizontal, 8)
        .padding(.vertical, 9)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
    private var generalRiskInfo: RiskInfo {
        RiskInfo(
            title: "Genel Risk Skoru: \(riskLevelText)",
            message: "AI Kararı\n\(overallRiskExplanation)\n\nAgent Analizi\n• Visual Agent: \(visualAgentSignal)\n• Return Risk Agent: \(returnAgentSignal)\n• Damage Agent: \(damageAgentSignal)\n\nAI Güven Seviyesi\n%\(explainabilityConfidence)\n\nSkoru Düşürmek İçin\n\(formattedRiskActions)"
        )
    }

    private var sellerReadinessInfo: RiskInfo {
        RiskInfo(
            title: "Satışa Hazırlık: \(marketplaceStatus)",
            message: "AI Kararı\n\(sellerReadinessExplanation)\n\nHazırlığı Etkileyen Sinyaller\n• Başlık ve açıklama netliği\n• Fotoğraf güveni\n• Kategoriye özel beklenti yönetimi\n• Kargo ve iade riskleri\n\nListing Agent Yorumu\n\(listingAgentSignal)\n\nİyileştirme Aksiyonları\n\(formattedRiskActions)"
        )
    }

    private var returnRiskInfo: RiskInfo {
        RiskInfo(
            title: "İade Riski: \(result.returnRisk)",
            message: "AI Kararı\n\(returnRiskExplanation)\n\nReturn Risk Agent\n\(returnAgentSignal)\n\nOlası İade Sebepleri\n\(formattedReturnReasons)\n\nRiski Azaltmak İçin\n\(formattedRiskActions)"
        )
    }

    private var damageRiskInfo: RiskInfo {
        RiskInfo(
            title: "Hasar Riski: \(result.damageRisk)",
            message: "AI Kararı\n\(damageRiskExplanation)\n\nDamage Agent\n\(damageAgentSignal)\n\nPaketleme Yorumu\n\(result.packagingRecommendation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Ürün tipine uygun koruyucu paketleme önerilir." : result.packagingRecommendation)\n\nRiski Azaltmak İçin\n\(formattedRiskActions)"
        )
    }

    private var explainabilityConfidence: Int {
        var score = 62

        if productImage != nil { score += 12 }
        if !result.productCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += 8 }
        if !result.material.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += 8 }
        if result.generatedDescription.trimmingCharacters(in: .whitespacesAndNewlines).count > 160 { score += 6 }
        if result.returnRisk.lowercased().contains("yüksek") || result.damageRisk.lowercased().contains("yüksek") { score -= 5 }

        return min(94, max(45, score))
    }

    private var overallRiskExplanation: String {
        if result.overallRiskScore >= 75 {
            return "Bu ürün yüksek risk bandında. AI; iade beklentisi, hasar ihtimali, materyal hassasiyeti ve açıklama netliğini birlikte değerlendirdi."
        }

        if result.overallRiskScore >= 45 {
            return "Bu ürün orta risk bandında. AI, ürünün satılabilir olduğunu fakat bazı detaylar netleşmezse iade veya hasar ihtimalinin artabileceğini gördü."
        }

        return "Bu ürün düşük risk bandında. AI, kategori ve açıklama sinyallerinin genel olarak güvenli olduğunu değerlendirdi."
    }

    private var sellerReadinessExplanation: String {
        if sellerReadinessScore >= 70 {
            return "İlan satışa yakın görünüyor. Başlık, açıklama ve risk sinyalleri pazaryeri için yeterli seviyede."
        }

        if sellerReadinessScore >= 45 {
            return "İlan geliştirilebilir durumda. Eksik detaylar tamamlanırsa alıcı güveni ve satışa hazırlık artar."
        }

        return "İlan satışa tam hazır görünmüyor. AI, açıklama netliği, fotoğraf güveni veya risk yönetimi tarafında güçlü iyileştirme ihtiyacı tespit etti."
    }

    private var returnRiskExplanation: String {
        let risk = result.returnRisk.lowercased()
        if risk.contains("yüksek") {
            return "İade riski yüksek çünkü alıcı beklentisi ile ürünün gerçek durumu arasında belirsizlik oluşabilecek sinyaller var."
        }
        if risk.contains("orta") {
            return "İade riski orta çünkü ürün satılabilir görünse de ölçü, kullanım alanı veya detay bilgisi eksik kalırsa beklenti farkı oluşabilir."
        }
        return "İade riski düşük çünkü ürün bilgileri ve kategori sinyalleri alıcı beklentisini daha net yönetiyor."
    }

    private var damageRiskExplanation: String {
        let risk = result.damageRisk.lowercased()
        if risk.contains("yüksek") {
            return "Hasar riski yüksek çünkü AI, materyal veya kategori açısından kargoda zarar görebilecek sinyaller tespit etti."
        }
        if risk.contains("orta") {
            return "Hasar riski orta çünkü ürün doğru paketlenmezse taşıma sırasında zarar görme ihtimali bulunuyor."
        }
        return "Hasar riski düşük çünkü ürünün kategori ve materyal sinyalleri kargo açısından daha güvenli görünüyor."
    }

    private var visualAgentSignal: String {
        productImage == nil
        ? "Görsel olmadığı için karar metin ve kategori sinyalleriyle desteklendi."
        : "Ürün görselinden kategori, materyal ve güven sinyalleri okundu."
    }

    private var returnAgentSignal: String {
        if result.returnRisk.lowercased().contains("yüksek") {
            return "Eksik bilgi veya beklenti uyuşmazlığı iade riskini yukarı taşıyor."
        }
        if result.returnRisk.lowercased().contains("orta") {
            return "Bazı ürün detayları netleşirse iade riski düşebilir."
        }
        return "Alıcı beklentisi şu an daha dengeli görünüyor."
    }

    private var damageAgentSignal: String {
        if result.damageRisk.lowercased().contains("yüksek") || result.fragilityLevel.lowercased().contains("yüksek") {
            return "Materyal veya kırılganlık kargo hasarı açısından kritik sinyal oluşturuyor."
        }
        if result.damageRisk.lowercased().contains("orta") {
            return "Standart paketleme yeterli olmayabilir; destekleyici koruma önerilir."
        }
        return "Kargo hasarı sinyali düşük; standart koruma yeterli olabilir."
    }

    private var listingAgentSignal: String {
        let descriptionIsShort = result.generatedDescription.trimmingCharacters(in: .whitespacesAndNewlines).count < 180
        if descriptionIsShort {
            return "Açıklama kısa görünüyor. Ölçü, materyal, kullanım alanı ve kutu içeriği gibi bilgiler eklenirse satışa hazırlık artar."
        }
        return "Açıklama pazaryeri için kullanılabilir seviyede; detay fotoğraf ve net paketleme diliyle daha güçlü hale gelir."
    }

    private var formattedReturnReasons: String {
        let cleaned = result.possibleReturnReasons
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if cleaned.isEmpty {
            return "• Ölçü veya kullanım beklentisi belirsizliği\n• Ürün detaylarının yeterince açık olmaması\n• Kargo veya paketleme beklentisi"
        }

        return cleaned.prefix(3).map { "• \($0)" }.joined(separator: "\n")
    }

    private var formattedRiskActions: String {
        dynamicRiskReductionActions.prefix(3).map { "• \($0)" }.joined(separator: "\n")
    }

    private var simulatedReducedRiskScore: Int {
        let score = result.overallRiskScore

        if score >= 80 {
            return max(35, score - 32)
        } else if score >= 65 {
            return max(32, score - 25)
        } else if score >= 45 {
            return max(24, score - 18)
        } else {
            return max(12, score - 8)
        }
    }

    private var simulatedRiskDelta: Int {
        max(0, result.overallRiskScore - simulatedReducedRiskScore)
    }

    private var simulationImpactText: String {
        if simulatedRiskDelta >= 28 {
            return "Güçlü İyileşme"
        } else if simulatedRiskDelta >= 18 {
            return "Net İyileşme"
        } else if simulatedRiskDelta >= 10 {
            return "Orta İyileşme"
        } else {
            return "Küçük İyileşme"
        }
    }

    private var simulationSummaryText: String {
        let category = result.productCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "ürün" : result.productCategory

        if simulatedRiskDelta >= 18 {
            return "Bu \(category) için en büyük kazanç; paketleme, detay fotoğrafı ve açıklama netliğiyle alıcı beklentisini daha iyi yönetmekten geliyor."
        }

        if result.overallRiskScore < 45 {
            return "Ürün zaten düşük riskli görünüyor. Küçük dokunuşlarla ilan güveni ve satışa hazırlık hissi artırılabilir."
        }

        return "Bu simülasyon, kategoriye özel eksik bilgileri tamamlayıp kargo riskini azaltınca oluşabilecek tahmini iyileşmeyi gösterir."
    }

    private var simulatedReadinessGain: Int {
        min(100, max(0, simulatedRiskDelta))
    }

    private var simulatedReadinessAfter: Int {
        min(100, sellerReadinessScore + simulatedReadinessGain)
    }

    private var riskReductionSimulationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.16))
                        .frame(width: 42, height: 42)

                    Image(systemName: "wand.and.stars.inverse")
                        .font(.headline)
                        .foregroundStyle(.cyan)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Risk Düşürme Simülasyonu")
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)

                    Text("Kategori, fotoğraf ve açıklama kalitesine göre tahmini iyileşme")
                        .font(.caption)
                        .foregroundStyle(mutedTextColor)
                }

                Spacer()

                Text(simulationImpactText)
                    .font(.caption2.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.cyan)
                    .clipShape(Capsule())
            }

            HStack(alignment: .center, spacing: 14) {
                simulationScoreBox(
                    title: "Mevcut Risk",
                    score: result.overallRiskScore,
                    color: riskColor
                )

                Image(systemName: "arrow.right")
                    .font(.headline.bold())
                    .foregroundStyle(mutedTextColor)

                simulationScoreBox(
                    title: "Aksiyon Sonrası",
                    score: simulatedReducedRiskScore,
                    color: simulatedReducedRiskScore >= 75 ? .red : (simulatedReducedRiskScore >= 45 ? .orange : .green)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("AI Yorumu")
                    .font(.caption.bold())
                    .foregroundStyle(mutedTextColor)

                Text(simulationSummaryText)
                    .font(.subheadline)
                    .foregroundStyle(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(isLightTheme ? Color.white.opacity(0.66) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            HStack(spacing: 10) {
                simulationMetricPill(
                    icon: "arrow.down.forward.circle.fill",
                    title: "Risk Azalımı",
                    value: "-\(simulatedRiskDelta) puan",
                    color: .cyan
                )

                simulationMetricPill(
                    icon: "checkmark.seal.fill",
                    title: "Hazırlık",
                    value: "\(simulatedReadinessAfter)/100",
                    color: simulatedReadinessAfter >= 70 ? .green : .orange
                )
            }

            Text("Öncelikli Aksiyonlar")
                .font(.caption.bold())
                .foregroundStyle(mutedTextColor)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(dynamicRiskReductionActions, id: \.self) { action in
                    simulationChecklistRow(text: action)
                }
            }

            Text("Bu simülasyon kesin sonuç değil; kategori, görsel kalite, açıklama netliği ve kargo hassasiyetine göre tahmini yol haritası sunar.")
                .font(.caption)
                .foregroundStyle(mutedTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: isLightTheme
                ? [
                    Color.white.opacity(0.84),
                    Color.cyan.opacity(0.12)
                ]
                : [
                    Color.cyan.opacity(0.12),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.cyan.opacity(isLightTheme ? 0.20 : 0.14), lineWidth: 1)
        )
    }

    private func simulationScoreBox(title: String, score: Int, color: Color) -> some View {
        VStack(spacing: 7) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(mutedTextColor)
                .multilineTextAlignment(.center)

            Text("\(score)")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(color)

            Text("/100")
                .font(.caption2.bold())
                .foregroundStyle(mutedTextColor)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .background(isLightTheme ? Color.white.opacity(0.68) : Color.black.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(color.opacity(0.16), lineWidth: 1)
        )
    }

    private func simulationMetricPill(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.bold())
                    .foregroundStyle(mutedTextColor)

                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(primaryTextColor)
            }

            Spacer(minLength: 0)
        }
        .padding(11)
        .frame(maxWidth: .infinity)
        .background(isLightTheme ? Color.white.opacity(0.66) : Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.16), lineWidth: 1)
        )
    }

    private var dynamicRiskReductionActions: [String] {
        var actions: [String] = []

        let category = result.productCategory.lowercased()
        let material = result.material.lowercased()
        let title = displayTitle.lowercased()
        let description = result.generatedDescription.lowercased()
        let combined = "\(category) \(material) \(title) \(description)"
        let returnRisk = result.returnRisk.lowercased()
        let damageRisk = result.damageRisk.lowercased()

        if combined.contains("cam") || combined.contains("seramik") || combined.contains("kupa") || combined.contains("bardak") || combined.contains("vazo") || category.contains("mutfak") {
            actions.append("Çift katman balonlu koruma ve sert dış koli kullan")
            actions.append("Koli içi boşluğu köpük veya karton destekle sabitle")
        }

        if combined.contains("elektronik") || combined.contains("telefon") || combined.contains("kulaklık") || combined.contains("mouse") || combined.contains("bilgisayar") || combined.contains("şarj") {
            actions.append("Model, uyumluluk ve kutu içeriğini net yaz")
            actions.append("Cihazı darbeye karşı sabitleyip aksesuarları ayrı paketle")
        }

        if combined.contains("ayakkabı") || combined.contains("giyim") || combined.contains("tekstil") || combined.contains("kıyafet") || combined.contains("çanta") || category.contains("moda") {
            actions.append("Beden, kalıp ve gerçek ölçü bilgisini ekle")
            actions.append("Renk farkını azaltmak için doğal ışıkta fotoğraf kullan")
        }

        if combined.contains("kozmetik") || combined.contains("parfüm") || combined.contains("krem") || combined.contains("şampuan") || category.contains("kozmetik") {
            actions.append("Hacim, içerik ve kullanım amacını kısa yaz")
            actions.append("Sızdırmayı önlemek için kapak ve dış ambalajı sabitle")
        }

        if combined.contains("bitki") || combined.contains("çiçek") || combined.contains("fidan") || category.contains("canlı") {
            actions.append("Bakım talimatı ve teslimat süresini açıklamaya ekle")
            actions.append("Taşıma sırasında ezilmeyi önleyen hava alan paket kullan")
        }

        if returnRisk.contains("yüksek") || returnRisk.contains("orta") {
            actions.append("Alıcı beklentisini ölçü, kullanım alanı ve net fotoğrafla yönet")
        }

        if damageRisk.contains("yüksek") || damageRisk.contains("orta") {
            actions.append("Hasar riskini azaltmak için koruyucu katmanı artır")
        }

        if let firstReason = result.possibleReturnReasons.first,
           !firstReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            actions.append("İlk iade sebebini azalt: \(firstReason)")
        }

        if actions.isEmpty {
            actions = [
                "Ürün açıklamasına materyal ve ölçü bilgisi ekle",
                "Ürüne uygun koruyucu paketleme kullan",
                "Gerçek ürün fotoğraflarıyla beklentiyi netleştir"
            ]
        }

        var seen = Set<String>()
        let uniqueActions = actions.filter { action in
            if seen.contains(action) { return false }
            seen.insert(action)
            return true
        }

        return Array(uniqueActions.prefix(3))
    }

    private func simulationChecklistRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.16))
                    .frame(width: 28, height: 28)

                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(.cyan)
            }
            .padding(.top, 1)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(isLightTheme ? Color.white.opacity(0.66) : Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var actionPlanCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "checklist.checked")
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Satıcı Aksiyon Planı")
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)

                    Text("Ürün tipine ve risk seviyesine göre önerildi")
                        .font(.caption)
                        .foregroundStyle(mutedTextColor)
                }

                Spacer()

                Text("Önemli!")
                    .font(.caption2.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.green)
                    .clipShape(Capsule())
            }

            VStack(spacing: 12) {
                ForEach(dynamicActionPlans, id: \.text) { action in
                    actionRow(icon: action.icon, text: action.text)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.green.opacity(0.14),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.green.opacity(0.12), lineWidth: 1)
        )
    }

    private var dynamicActionPlans: [(icon: String, text: String)] {
        var plans: [(icon: String, text: String)] = []

        let material = result.material.lowercased()
        let generatedTitle = result.generatedTitle.lowercased()
        let visibleTitle = displayTitle.lowercased()
        let generatedDescription = result.generatedDescription.lowercased()
        let combined = "\(material) \(generatedTitle) \(visibleTitle) \(generatedDescription)"

        let returnRisk = result.returnRisk.lowercased()
        let damageRisk = result.damageRisk.lowercased()
        let fragility = result.fragilityLevel.lowercased()

        if combined.contains("cam") || combined.contains("seramik") || combined.contains("kupa") || combined.contains("bardak") || combined.contains("vazo") {
            plans.append((
                icon: "shippingbox.fill",
                text: "Kırılma riskine karşı çift katmanlı balonlu koruma ve sert dış koli kullan"
            ))
            plans.append((
                icon: "cube.transparent.fill",
                text: "Ürünün koli içinde hareket etmemesi için köpük, karton veya hava yastığı desteği ekle"
            ))
        }

        if combined.contains("elektronik") || combined.contains("mouse") || combined.contains("kulaklık") || combined.contains("telefon") || combined.contains("bilgisayar") || combined.contains("şarj") {
            plans.append((
                icon: "cpu.fill",
                text: "Model, bağlantı tipi, uyumluluk ve teknik özellikleri ilan açıklamasında net belirt"
            ))
            plans.append((
                icon: "battery.100.bolt",
                text: "Kutu içeriği, garanti, pil/şarj durumu ve aksesuar bilgisini açıkça yaz"
            ))
        }

        if combined.contains("ayakkabı") || combined.contains("tekstil") || combined.contains("giyim") || combined.contains("kıyafet") || combined.contains("çanta") {
            plans.append((
                icon: "ruler.fill",
                text: "Beden, kalıp, ölçü ve materyal bilgisini açıklamaya ekle"
            ))
            plans.append((
                icon: "camera.fill",
                text: "Renk ve doku beklentisini doğru yönetmek için doğal ışıkta gerçek fotoğraflar kullan"
            ))
        }

        if combined.contains("bitki") || combined.contains("çiçek") || combined.contains("canlı") || combined.contains("fidan") {
            plans.append((
                icon: "leaf.fill",
                text: "Canlı ürün olduğu için bakım talimatı, teslimat süresi ve mevsimsel görünüm bilgisini belirt"
            ))
            plans.append((
                icon: "thermometer.sun.fill",
                text: "Sıcaklık, nem ve taşıma hassasiyeti varsa kargo açıklamasında özellikle vurgula"
            ))
        }

        if combined.contains("kozmetik") || combined.contains("krem") || combined.contains("parfüm") || combined.contains("şampuan") {
            plans.append((
                icon: "drop.fill",
                text: "İçerik, hacim, kullanım amacı ve alerjen uyarılarını açıklamada net belirt"
            ))
            plans.append((
                icon: "seal.fill",
                text: "Kapak sızdırmazlığı ve koruyucu ambalaj kontrolünü kargodan önce yap"
            ))
        }

        if returnRisk.contains("yüksek") || returnRisk.contains("orta") {
            plans.append((
                icon: "arrow.uturn.backward.circle.fill",
                text: "İade riskini azaltmak için ölçü, kullanım senaryosu ve beklenti oluşturan detayları netleştir"
            ))
        }

        if damageRisk.contains("yüksek") || fragility.contains("yüksek") {
            plans.append((
                icon: "exclamationmark.triangle.fill",
                text: "Hasar riskine karşı pakete ek koruyucu katman ve uyarı etiketi ekle"
            ))
        }

        if let firstReason = result.possibleReturnReasons.first,
           !firstReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            plans.append((
                icon: "lightbulb.fill",
                text: "Öncelikli iade sebebini azalt: \(firstReason)"
            ))
        }

        if plans.isEmpty {
            plans = [
                (icon: "checkmark.seal.fill", text: "Ürün açıklamasına materyal, ölçü ve kullanım alanı bilgilerini net ekle"),
                (icon: "shippingbox.fill", text: "Ürün tipine uygun koruyucu paketleme tercih et"),
                (icon: "camera.fill", text: "Gerçek ürün fotoğraflarıyla alıcı beklentisini doğru yönet")
            ]
        }

        var seen = Set<String>()
        let uniquePlans = plans.filter { plan in
            if seen.contains(plan.text) { return false }
            seen.insert(plan.text)
            return true
        }

        return Array(uniquePlans.prefix(4))
    }

    private func actionRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.18))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }


    private var shareReportButton: some View {
        ShareLink(item: shareReportText) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up.fill")
                Text("Raporu Paylaş")
            }
            .font(.headline)
            .foregroundStyle(primaryTextColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(cardStrokeColor, lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private var shareReportText: String {
        let category = result.productCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Genel Ürün" : result.productCategory
        let title = result.generatedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? displayTitle : result.generatedTitle
        let description = result.generatedDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "AI satış açıklaması bulunamadı." : result.generatedDescription

        let photoGuide = dynamicPhotoGuidePlan.isEmpty
        ? "• Fotoğraf önerisi bulunamadı"
        : dynamicPhotoGuidePlan
            .map { "• \($0.title): \($0.text)" }
            .joined(separator: "\n")

        let customerSimulation = dynamicCustomerReviewPlan.isEmpty
        ? "• Müşteri yorumu simülasyonu bulunamadı"
        : dynamicCustomerReviewPlan
            .map { "• \($0.title): \($0.text)" }
            .joined(separator: "\n")

        let riskActions = dynamicRiskReductionActions.isEmpty
        ? "• Öncelikli aksiyon bulunamadı"
        : dynamicRiskReductionActions
            .map { "• \($0)" }
            .joined(separator: "\n")

        let returnReasons = result.possibleReturnReasons.isEmpty
        ? "• Belirtilmedi"
        : result.possibleReturnReasons
            .map { "• \($0)" }
            .joined(separator: "\n")

        return """
        PackWise AI MVP+ Analiz Raporu

        Ürün: \(displayTitle)
        Kategori: \(category)
        Materyal: \(result.material)

        Özet Skorlar
        Genel Risk: \(result.overallRiskScore)/100 - \(riskLevelText)
        Satışa Hazırlık: \(sellerReadinessScore)/100 - \(marketplaceStatus)
        İade Riski: \(result.returnRisk)
        Hasar Riski: \(result.damageRisk)

        Risk Düşürme Simülasyonu
        Mevcut Risk: \(result.overallRiskScore)/100
        Aksiyon Sonrası Risk: \(simulatedReducedRiskScore)/100
        Tahmini Risk Azalımı: -\(simulatedRiskDelta) puan
        Aksiyon Sonrası Hazırlık: \(simulatedReadinessAfter)/100
        AI Yorumu: \(simulationSummaryText)

        Öncelikli Aksiyonlar
        \(riskActions)

        AI İlan Başlığı
        \(title)

        AI Satış Açıklaması
        \(description)

        AI Fotoğraf Rehberi
        \(photoGuide)

        Müşteri Yorumu Simülasyonu
        \(customerSimulation)

        Muhtemel İade Sebepleri
        \(returnReasons)

        Not: Bu rapor AI destekli tahmini analizdir. Kesin sonuç değil; kategori, görsel kalite, açıklama netliği ve kargo hassasiyetine göre yol haritası sunar.
        """
    }

    private var newAnalysisButton: some View {
        NavigationLink {
            ProductInputView()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                Text("Yeni Ürün Analiz Et")
            }
            .font(.headline)
            .foregroundStyle(isLightTheme ? Color.black : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .white.opacity(0.14), radius: 16, x: 0, y: 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private var copiedToast: some View {
        VStack {
            Spacer()

            if showCopiedToast {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text(copiedToastText)
                        .font(.subheadline.bold())
                        .foregroundStyle(isLightTheme ? Color.black : .white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isLightTheme ? Color.white.opacity(0.92) : .black.opacity(0.72))
                .clipShape(Capsule())
                .padding(.bottom, 22)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showCopiedToast)
    }

    func copyableInfoCard(icon: String, title: String, content: String, copiedMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(primaryTextColor)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(primaryTextColor)

                Spacer()

                Button {
                    copyToClipboard(content, message: copiedMessage)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Kopyala")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.white)
                    .clipShape(Capsule())
                }
            }

            Text(content)
                .foregroundStyle(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: isLightTheme
                ? [
                    Color.white.opacity(0.82),
                    Color.white.opacity(0.64)
                ]
                : [
                    Color.white.opacity(0.10),
                    Color.white.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(cardStrokeColor, lineWidth: 1)
        )
    }

    private func copyToClipboard(_ text: String, message: String) {
        UIPasteboard.general.string = text

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        copiedToastText = message
        showCopiedToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            showCopiedToast = false
        }
    }

    func infoCard(icon: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(primaryTextColor)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(primaryTextColor)
            }

            Text(content)
                .foregroundStyle(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
                    Color(red: 0.08, green: 0.10, blue: 0.18)
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
        isLightTheme ? Color(red: 0.04, green: 0.08, blue: 0.16) : .white
    }

    private var secondaryTextColor: Color {
        isLightTheme ? Color(red: 0.22, green: 0.30, blue: 0.40) : .white.opacity(0.72)
    }

    private var mutedTextColor: Color {
        isLightTheme ? Color(red: 0.40, green: 0.47, blue: 0.57) : .white.opacity(0.60)
    }

    private var cardBackgroundColor: Color {
        isLightTheme ? Color.white.opacity(0.76) : Color.white.opacity(0.08)
    }

    private var cardStrokeColor: Color {
        isLightTheme ? Color.black.opacity(0.06) : Color.white.opacity(0.08)
    }
}

#Preview {
    NavigationStack {
        AnalysisResultView(productTitle: "Cam Kahve Kupası", productImage: nil, result: .mock)
    }
}

#if swift(>=5.7)
private struct RiskInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
#else
private struct RiskInfo: Identifiable {
    var id: UUID { UUID() }
    let title: String
    let message: String
}
#endif
