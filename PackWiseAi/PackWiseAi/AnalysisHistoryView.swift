import SwiftUI
import UIKit

struct AnalysisHistoryView: View {
    @State private var historyItems: [AnalysisHistoryItem] = []
    @State private var showClearAlert = false
    @State private var itemPendingDelete: AnalysisHistoryItem?
    @AppStorage("packwise_is_light_theme") private var isLightTheme = false

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    summaryCard

                    if historyItems.isEmpty {
                        emptyStateCard
                    } else {
                        historyList
                    }

                    footerNote
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 34)
            }
        }
        .navigationTitle("Önceki Analizler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !historyItems.isEmpty {
                    Button {
                        showClearAlert = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Temizle")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(isLightTheme ? Color.red.opacity(0.10) : Color.red.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .alert("Geçmiş temizlensin mi?", isPresented: $showClearAlert) {
            Button("Vazgeç", role: .cancel) {}
            Button("Tümünü Temizle", role: .destructive) {
                AnalysisHistoryStore.shared.clearAll()
                historyItems = []
            }
        } message: {
            Text("Son 5 analiz kaydı bu cihazdan silinecek.")
        }
        .alert("Analiz silinsin mi?", isPresented: Binding(
            get: { itemPendingDelete != nil },
            set: { newValue in
                if !newValue {
                    itemPendingDelete = nil
                }
            }
        )) {
            Button("Vazgeç", role: .cancel) {
                itemPendingDelete = nil
            }
            Button("Sil", role: .destructive) {
                if let itemPendingDelete {
                    AnalysisHistoryStore.shared.delete(id: itemPendingDelete.id)
                    historyItems = AnalysisHistoryStore.shared.loadLastFive()
                }
                itemPendingDelete = nil
            }
        } message: {
            Text("Bu analiz geçmişten kaldırılacak.")
        }
        .onAppear {
            historyItems = AnalysisHistoryStore.shared.loadLastFive()
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
                    Color(red: 0.02, green: 0.05, blue: 0.13),
                    Color(red: 0.03, green: 0.12, blue: 0.27),
                    Color(red: 0.05, green: 0.08, blue: 0.18)
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
                    Color.cyan.opacity(0.22),
                    Color.blue.opacity(0.10),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 420
            )

            Circle()
                .fill(isLightTheme ? Color.yellow.opacity(0.18) : Color.blue.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: -130, y: -150)
        }
        .ignoresSafeArea()
    }

    private var primaryTextColor: Color {
        isLightTheme ? Color(red: 0.04, green: 0.08, blue: 0.16) : .white
    }

    private var secondaryTextColor: Color {
        isLightTheme ? Color(red: 0.22, green: 0.30, blue: 0.40) : .white.opacity(0.68)
    }

    private var mutedTextColor: Color {
        isLightTheme ? Color(red: 0.40, green: 0.47, blue: 0.57) : .white.opacity(0.55)
    }

    private var cardBackgroundColor: Color {
        isLightTheme ? Color.white.opacity(0.76) : Color.white.opacity(0.07)
    }

    private var cardStrokeColor: Color {
        isLightTheme ? Color.black.opacity(0.06) : Color.white.opacity(0.07)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 86, height: 86)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.cyan)
            }

            VStack(spacing: 8) {
                Text("Son Analizler")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Gerçek analiz geçmişindeki son 5 ürünü hızlıca incele ve risk geçmişini takip et.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 10) {
            summaryMiniCard(
                title: "Toplam",
                value: "\(historyItems.count)",
                icon: "doc.text.magnifyingglass",
                color: .cyan
            )

            summaryMiniCard(
                title: "Düşük",
                value: "\(lowRiskCount)",
                icon: "checkmark.seal.fill",
                color: .green
            )

            summaryMiniCard(
                title: "Orta",
                value: "\(mediumRiskCount)",
                icon: "gauge.medium",
                color: .orange
            )

            summaryMiniCard(
                title: "Yüksek",
                value: "\(highRiskCount)",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
        }
    }

    private func summaryMiniCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 9) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 104)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private var historyList: some View {
        VStack(spacing: 14) {
            ForEach(historyItems) { item in
                historyCard(item)
            }
        }
    }

    private func historyCard(_ item: AnalysisHistoryItem) -> some View {
        NavigationLink {
            AnalysisResultView(
                productTitle: item.title,
                productImage: item.uiImage,
                productImages: item.uiImage != nil ? [item.uiImage!] : [],
                result: item.result,
                showsBackButton: true
            )
        } label: {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 14) {
                    historyThumbnail(for: item)

                    VStack(alignment: .leading, spacing: 7) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(item.dateText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.48))

                        HStack(spacing: 8) {
                            riskBadge(text: item.riskLevel, color: item.riskColor)

                            Text("Skor: \(item.riskScore)/100")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.62))
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.38))
                        .padding(.trailing, 34)
                }
                .padding(16)
                .background(Color.white.opacity(0.075))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )

                Button {
                    itemPendingDelete = item
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                        .frame(width: 30, height: 30)
                        .background(Color.red.opacity(0.14))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .padding(.trailing, 10)
            }
        }
        .buttonStyle(.plain)
    }

    private func historyThumbnail(for item: AnalysisHistoryItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(item.riskColor.opacity(0.16))
                .frame(width: 68, height: 68)

            if let image = item.uiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(item.riskColor.opacity(0.28), lineWidth: 1)
                    )
            } else {
                Image(systemName: item.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(item.riskColor)
            }
        }
    }

    private func riskBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.16))
            .clipShape(Capsule())
    }

    private var emptyStateCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 78, height: 78)

                Image(systemName: "tray")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
            }

            VStack(spacing: 8) {
                Text("Henüz analiz yok")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Yeni bir ürün analiz ettiğinde sonuçlar otomatik olarak burada listelenecek.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private var footerNote: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.white.opacity(0.36))

            Text("Yalnızca son 5 analiz cihazında tutulur.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.42))
        }
        .padding(.top, 6)
    }


    private var lowRiskCount: Int {
        historyItems.filter { $0.riskScore < 45 }.count
    }

    private var mediumRiskCount: Int {
        historyItems.filter { $0.riskScore >= 45 && $0.riskScore < 75 }.count
    }

    private var highRiskCount: Int {
        historyItems.filter { $0.riskScore >= 75 }.count
    }
}

struct AnalysisHistoryItem: Identifiable {
    let id: UUID
    let title: String
    let createdAt: Date
    let riskScore: Int
    let riskLevel: String
    let icon: String
    let result: AnalysisResult
    let imageData: Data?

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        riskScore: Int,
        riskLevel: String,
        icon: String,
        result: AnalysisResult,
        imageData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.riskScore = riskScore
        self.riskLevel = riskLevel
        self.icon = icon
        self.result = result
        self.imageData = imageData
    }

    var uiImage: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }

    var dateText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .short

        let relative = formatter.localizedString(for: createdAt, relativeTo: Date())

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "tr_TR")
        timeFormatter.dateFormat = "HH:mm"

        return "\(relative) • \(timeFormatter.string(from: createdAt))"
    }

    var riskColor: Color {
        if riskScore >= 75 {
            return .red
        } else if riskScore >= 45 {
            return .orange
        } else {
            return .green
        }
    }

    static func make(title: String, result: AnalysisResult, imageData: Data? = nil) -> AnalysisHistoryItem {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let aiTitle = result.generatedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = !cleanedTitle.isEmpty ? cleanedTitle : (!aiTitle.isEmpty ? aiTitle : "Analiz Edilen Ürün")

        return AnalysisHistoryItem(
            title: finalTitle,
            riskScore: result.overallRiskScore,
            riskLevel: riskLevelText(for: result.overallRiskScore),
            icon: iconName(for: result.material, title: finalTitle),
            result: result,
            imageData: imageData
        )
    }

    private static func riskLevelText(for score: Int) -> String {
        if score >= 75 {
            return "Yüksek Risk"
        } else if score >= 45 {
            return "Orta Risk"
        } else {
            return "Düşük Risk"
        }
    }

    private static func iconName(for material: String, title: String) -> String {
        let combined = "\(material) \(title)".lowercased()

        if combined.contains("elektronik") || combined.contains("mouse") || combined.contains("telefon") {
            return "desktopcomputer"
        }

        if combined.contains("cam") || combined.contains("seramik") || combined.contains("kupa") {
            return "shippingbox.fill"
        }

        if combined.contains("ayakkabı") || combined.contains("tekstil") {
            return "shoeprints.fill"
        }

        if combined.contains("bitki") || combined.contains("çiçek") {
            return "leaf.fill"
        }

        return "cube.box.fill"
    }
}

final class AnalysisHistoryStore {
    static let shared = AnalysisHistoryStore()

    private let storageKey = "packwise_last_analysis_history_v1"
    private let maxCount = 5

    private init() {}

    func loadLastFive() -> [AnalysisHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }

        do {
            let records = try JSONDecoder().decode([AnalysisHistoryRecord].self, from: data)
            return records.map { $0.toHistoryItem() }
        } catch {
            return []
        }
    }

    func save(title: String, result: AnalysisResult, image: UIImage? = nil) {
        var items = loadLastFive()
        let imageData = image?.resizedForHistoryThumbnail(maxDimension: 420).jpegData(compressionQuality: 0.72)
        let newItem = AnalysisHistoryItem.make(title: title, result: result, imageData: imageData)
        items.insert(newItem, at: 0)
        items = Array(items.prefix(maxCount))

        let records = items.map { AnalysisHistoryRecord(from: $0) }
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    func delete(id: UUID) {
        let filtered = loadLastFive().filter { $0.id != id }
        let records = filtered.map { AnalysisHistoryRecord(from: $0) }

        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

private struct AnalysisHistoryRecord: Codable {
    let id: UUID
    let title: String
    let createdAt: Date
    let riskScore: Int
    let riskLevel: String
    let icon: String
    let overallRiskScore: Int
    let returnRisk: String
    let damageRisk: String
    let material: String
    let fragilityLevel: String
    let packagingRecommendation: String
    let aiInsights: String
    let descriptionImprovement: String
    let possibleReturnReasons: [String]
    let generatedTitle: String
    let generatedDescription: String
    let productCategory: String?
    let scoreExplanation: [String]?
    let categoryExpertise: [String]?
    let uniqueInsights: [String]?
    let imageData: Data?

    init(from item: AnalysisHistoryItem) {
        self.id = item.id
        self.title = item.title
        self.createdAt = item.createdAt
        self.riskScore = item.riskScore
        self.riskLevel = item.riskLevel
        self.icon = item.icon
        self.overallRiskScore = item.result.overallRiskScore
        self.returnRisk = item.result.returnRisk
        self.damageRisk = item.result.damageRisk
        self.material = item.result.material
        self.fragilityLevel = item.result.fragilityLevel
        self.packagingRecommendation = item.result.packagingRecommendation
        self.aiInsights = item.result.aiInsights
        self.descriptionImprovement = item.result.descriptionImprovement
        self.possibleReturnReasons = item.result.possibleReturnReasons
        self.generatedTitle = item.result.generatedTitle
        self.generatedDescription = item.result.generatedDescription
        self.productCategory = item.result.productCategory
        self.scoreExplanation = item.result.scoreExplanation
        self.categoryExpertise = item.result.categoryExpertise
        self.uniqueInsights = item.result.uniqueInsights
        self.imageData = item.imageData
    }

    func toHistoryItem() -> AnalysisHistoryItem {
        AnalysisHistoryItem(
            id: id,
            title: title,
            createdAt: createdAt,
            riskScore: riskScore,
            riskLevel: riskLevel,
            icon: icon,
            result: AnalysisResult(
                overallRiskScore: overallRiskScore,
                returnRisk: returnRisk,
                damageRisk: damageRisk,
                material: material,
                fragilityLevel: fragilityLevel,
                packagingRecommendation: packagingRecommendation,
                aiInsights: aiInsights,
                descriptionImprovement: descriptionImprovement,
                possibleReturnReasons: possibleReturnReasons,
                generatedTitle: generatedTitle,
                generatedDescription: generatedDescription,
                productCategory: productCategory ?? "Genel Ürün",
                scoreExplanation: scoreExplanation ?? [],
                categoryExpertise: categoryExpertise ?? [],
                uniqueInsights: uniqueInsights ?? []
            ),
            imageData: imageData
        )
    }
}

#Preview {
    NavigationStack {
        AnalysisHistoryView()
    }
}

private extension UIImage {
    func resizedForHistoryThumbnail(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension, maxDimension > 0 else { return self }

        let scale = maxDimension / maxSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
