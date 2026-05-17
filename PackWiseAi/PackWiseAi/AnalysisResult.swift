import Foundation

struct AnalysisResult {
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
    let productCategory: String

    // MARK: - MVP+ AI Intelligence

    let scoreExplanation: [String]
    let categoryExpertise: [String]
    let uniqueInsights: [String]

    // MARK: - Mock

    static let mock = AnalysisResult(
        overallRiskScore: 72,
        returnRisk: "Yüksek",
        damageRisk: "Yüksek",
        material: "Cam / Kırılgan Materyal",
        fragilityLevel: "Yüksek",

        packagingRecommendation:
            "Çift katmanlı balonlu naylon, köpük destek ve sert dış koli kullanılması önerilir.",

        aiInsights:
            "Ürün kırılgan görünüyor. Kargo sırasında köşe darbesi ve basınç kaynaklı hasar riski yüksek olabilir.",

        descriptionImprovement:
            "Ürün açıklamasında ölçü, materyal ve kullanım alanı daha net belirtilirse iade riski azalabilir.",

        possibleReturnReasons: [
            "Ürünün beklenenden küçük algılanması",
            "Kırılma veya kargo hasarı",
            "Materyal bilgisinin eksik olması"
        ],

        generatedTitle:
            "Dekoratif Cam Vazo Modern Tasarım Şeffaf Ev Dekorasyonu",

        generatedDescription:
            "Modern tasarıma sahip dekoratif cam vazo ev ve ofis kullanımına uygundur. Şeffaf yapısı sayesinde farklı dekor stilleriyle uyum sağlar. Kırılabilir cam materyal nedeniyle korumalı şekilde paketlenerek gönderilir. Dekoratif kullanım için şık ve minimal bir tercih sunar.",

        productCategory: "Ev & Mutfak",

        // MARK: - Explainable Scoring

        scoreExplanation: [
            "Cam materyal hasar riskini artırdı",
            "Kırılabilir yapı nedeniyle kargo riski yükseldi",
            "Ürün ölçü bilgilerinin eksik olması iade riskini artırdı",
            "Çoklu açı eksikliği güven skorunu düşürdü"
        ],

        // MARK: - Category Expertise

        categoryExpertise: [
            "Cam dekor ürünlerinde köşe darbesi riski yüksektir",
            "Dekor kategorisinde ölçü beklentisi iadeyi etkiler",
            "Şeffaf ürünlerde detay fotoğrafı güveni artırır",
            "Koruyucu köpük destek müşteri memnuniyetini artırabilir"
        ],

        // MARK: - Unique AI Insights

        uniqueInsights: [
            "Ürün premium dekor hissi veriyor",
            "Beyaz arka plan satış güvenini artırabilir",
            "Yakın çekim detay fotoğrafı dönüşümü yükseltebilir",
            "Minimal açıklama yerine kullanım alanı eklenebilir"
        ]
    )
}
