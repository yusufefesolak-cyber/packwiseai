import Foundation
import UIKit

final class GeminiService {
    static let shared = GeminiService()

    private init() {}

    // TODO: Buraya Google AI Studio üzerinden aldığın Gemini API key gelecek.
    // Hackathon demosu için geçici olarak burada tutabiliriz.
    // Finalde güvenlik için backend/proxy üzerinden çağırmak daha doğru olur.
    private let apiKey = "AIzaSyB8HIJnBvbUgAGnvgaj7hXwBP2kdlbnpiM"
    private let primaryModel = "gemini-2.5-flash"
    private let fallbackModel = "gemini-2.5-flash-lite"
    private let secondFallbackModel = "gemini-2.0-flash"
    private let thirdFallbackModel = "gemini-2.0-flash-lite"
    private let retryDelaysNanoseconds: [UInt64] = [1_500_000_000, 3_000_000_000]

    func analyzeProduct(
        title: String,
        description: String,
        weight: String,
        size: String,
        image: UIImage?,
        images: [UIImage] = []
    ) async throws -> AnalysisResult {
        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let analysisImages = images.isEmpty ? image.map { [$0] } ?? [] : images

        let prompt = makePrompt(
            title: finalTitle,
            description: finalDescription,
            weight: weight,
            size: size
        )

        var parts: [[String: Any]] = [
            ["text": prompt]
        ]

        for image in analysisImages.prefix(4).reversed() {
            if let imageData = image.jpegData(compressionQuality: 0.58) {
                let base64Image = imageData.base64EncodedString()
                parts.insert(
                    [
                        "inline_data": [
                            "mime_type": "image/jpeg",
                            "data": base64Image
                        ]
                    ],
                    at: 0
                )
            }
        }

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": parts
                ]
            ],
            "generationConfig": [
                "temperature": 0.2,
                "response_mime_type": "application/json"
            ]
        ]

        let data = try await performGenerateContentRequest(body: body)

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw GeminiError.emptyResponse
        }

        let cleanedJSON = cleanJSONText(text)
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw GeminiError.invalidJSON
        }

        let decoded = try JSONDecoder().decode(GeminiAnalysisDTO.self, from: jsonData)

        return AnalysisResult(
            overallRiskScore: decoded.overallRiskScore,
            returnRisk: decoded.returnRisk,
            damageRisk: decoded.damageRisk,
            material: decoded.material,
            fragilityLevel: decoded.fragilityLevel,
            packagingRecommendation: decoded.packagingRecommendation,
            aiInsights: decoded.aiInsights,
            descriptionImprovement: decoded.descriptionImprovement,
            possibleReturnReasons: decoded.possibleReturnReasons,
            generatedTitle: decoded.generatedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? finalTitle : decoded.generatedTitle,
            generatedDescription: decoded.generatedDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? finalDescription : decoded.generatedDescription,
            productCategory: decoded.productCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Genel Ürün" : decoded.productCategory,
            scoreExplanation: decoded.scoreExplanation,
            categoryExpertise: decoded.categoryExpertise,
            uniqueInsights: decoded.uniqueInsights
        )
    }

    private func makePrompt(
        title: String,
        description: String,
        weight: String,
        size: String
    ) -> String {
        """
        You are PackWise AI, an AI powered seller intelligence system for ALL e-commerce sellers.

        Your job is to analyze any e-commerce product using the image and seller-provided listing information.
        The product can be from any category: electronics, glassware, fashion, shoes, cosmetics, toys, books, home decor, kitchen items, plants, food packaging, accessories, furniture, handmade products, or other online marketplace items.

        Product title: \(title.isEmpty ? "Not provided" : title)
        Product description and seller-provided details: \(description.isEmpty ? "Not provided" : description)
        Weight: \(weight.isEmpty ? "Not provided" : weight)
        Size: \(size.isEmpty ? "Not provided" : size)

        Seller-provided details may include labeled lines such as Marka, Model/Seri, Renk/Ölçü, Durum, and Kutu İçeriği/Ek Bilgi.
        Treat these as important supporting context for generatedTitle, generatedDescription and risk analysis, but still verify against visible image evidence.

        Analyze like a marketplace seller assistant, not like a generic chatbot.

        If multiple images are provided, treat them as the same product from different angles.
        Use the first image as the main product image, and use the additional images to verify details, missing angles, visible defects, ports, labels, packaging, size clues and material confidence.
        If seller-provided details conflict with visible image evidence, prefer the image and mention the uncertainty briefly in aiInsights.

        Step 1 - Identify the product:
        - likely product type
        - likely e-commerce category
        - choose one clear marketplace category and return it in productCategory
        - likely material or composition
        - use additional photos to improve category and material confidence
        - use seller-provided brand, model, color, size, condition and box contents as supporting context to improve generatedTitle, generatedDescription and analysis accuracy

        Step 2 - Evaluate category-specific risks with realistic marketplace logic:
        - Electronics: compatibility ambiguity, battery/safety concern, screen/body damage, missing model, missing warranty/box/accessory info.
        - Fashion/Shoes: size/fit mismatch, color expectation, fabric/material expectation, missing measurements, used-condition uncertainty.
        - Glass/Ceramic/Decor: breakage during shipping, edge/corner impact, surface scratches, insufficient protective packaging.
        - Cosmetics/Personal care: leakage, seal status, expiry/ingredient uncertainty, hygiene expectation, allergy/skin sensitivity risk.
        - Books/Paper goods: bent corners, water damage, missing edition info, page condition uncertainty.
        - Toys: missing parts, age suitability, safety expectation, box condition, small part risk.
        - Food/Packaged goods: expiry date, leakage, temperature sensitivity, package integrity, quantity/weight clarity.
        - Plants/Flowers: heat/cold sensitivity, crushing, freshness expectation, soil leakage, ventilation and delivery speed.
        - Furniture/Home items: scratches/dents, missing dimensions, assembly expectation, color/material mismatch, shipping damage.
        - Plastic/storage/kitchen containers: size/capacity ambiguity, lid fit, handle durability, odor/stain expectation, shipping deformation.
        - Other products: infer the most relevant buyer expectation, return and cargo risks from images and listing details.

        Step 2.5 - Score realistically:
        - overallRiskScore must be realistic, not random, and must match the product/category risks.
        - 0-24: Very safe product, clear listing, low cargo risk.
        - 25-44: Low risk, minor missing info or minor photo/detail uncertainty.
        - 45-64: Medium risk, important buyer expectation or packaging/detail uncertainty exists.
        - 65-79: High risk, fragile/sensitive product or multiple missing details.
        - 80-100: Very high risk only for clearly fragile, leak-prone, expensive, sensitive, live, or badly documented products.
        - Do not give high scores to ordinary low-risk items unless there is visible damage, missing key info, or serious packaging/expectation risk.
        - Missing brand/model/size/condition/photos should increase return risk, but should not automatically make the score high.
        - Fragile or leak-prone products should increase damageRisk more than returnRisk.
        - Size/fit/color/compatibility uncertainty should increase returnRisk more than damageRisk.
        - generatedTitle and generatedDescription quality should affect seller readiness indirectly through descriptionImprovement and aiInsights.

        Step 3 - Produce seller-focused outputs:
        - overallRiskScore: one realistic numeric score from 0-100 based on product category, visual evidence, listing completeness and cargo sensitivity.
        - returnRisk: Düşük / Orta / Yüksek based mainly on buyer expectation mismatch, missing info, size/color/model/condition ambiguity.
        - damageRisk: Düşük / Orta / Yüksek based mainly on cargo breakage, leakage, crushing, bending, scratching or temperature sensitivity.
        - fragilityLevel: Düşük / Orta / Yüksek based on visible material, structure and category.
        - packagingRecommendation: category-specific and actionable, maximum 2 short sentences.
        - possibleReturnReasons: exactly 3 short, category-specific reasons, each max 8 words.
        - aiInsights: explain briefly why the AI scored it this way, max 2 short sentences.
        - descriptionImprovement: say the most important listing improvement, max 2 short sentences.
        - generatedTitle: Generate a real marketplace-style product title in Turkish. Use brand, model, product type, color, size/capacity and key feature when available. Keep it clear, searchable and sales-ready. Target 70-110 characters.
        - generatedDescription: Generate a real e-commerce listing description in Turkish. It should be buyer-friendly, trust-building and practical. Target 250-500 characters, 1 short intro + 2-4 benefit/detail sentences. Use condition, box contents, material, usage area, compatibility, size/capacity and care/shipping details when available.
        - scoreExplanation: exactly 4 short Turkish explanations for what increased or decreased the score. Each item max 12 words.
        - categoryExpertise: exactly 4 Turkish category-specific expert notes. Each item max 12 words.
        - uniqueInsights: exactly 4 Turkish product-specific insights based on image/details. Each item max 12 words.
        - mention missing photo angles or unclear visual details inside aiInsights when relevant

        Rules:
        - All outputs must be clean, readable and marketplace-style as described above.
        - Do not invent brand, model, warranty, size, color or box contents if not provided or visible.
        - If seller provides brand/model/condition/contents, include the most useful ones in generatedTitle or generatedDescription.
        - generatedTitle should look like Trendyol / Hepsiburada / Dolap style product titles: searchable, clear and not robotic.
        - generatedDescription should sound like a real e-commerce seller listing, not a technical report.
        - generatedDescription must not be too short. It should include useful buyer-facing details, but avoid filler.
        - generatedDescription should be around 250-500 characters. Do not exceed 550 characters.
        - generatedDescription format: one natural intro sentence, then short benefit/detail sentences. No markdown, no bullet characters.
        - generatedTitle: target 70-110 characters, max 120 characters.
        - packagingRecommendation: max 2 short sentences.
        - aiInsights: max 2 short sentences.
        - descriptionImprovement: max 2 short sentences.
        - possibleReturnReasons: each entry max 8 words.
        - scoreExplanation must explain the actual score, not generic advice.
        - categoryExpertise must be category-specific, not generic seller tips.
        - uniqueInsights must mention visible/product-specific details when possible.
        - Do not repeat the same idea across scoreExplanation, categoryExpertise and uniqueInsights.
        - Be conservative and realistic. Do not mark everything as high risk.
        - Use Yüksek only when the category or visible evidence truly supports it.
        - Use Orta for common e-commerce uncertainty such as missing dimensions, unclear condition, color/size expectation, limited photos or packaging uncertainty.
        - Use Düşük when the item is simple, durable, well-described, and has low cargo sensitivity.
        - If information is missing, mention it, but keep the score proportional to the actual category risk.
        - overallRiskScore must align with returnRisk, damageRisk and fragilityLevel.
        - If returnRisk is Düşük and damageRisk is Düşük, overallRiskScore should usually stay below 45.
        - If either returnRisk or damageRisk is Orta, overallRiskScore should usually be between 35 and 65.
        - If either returnRisk or damageRisk is Yüksek, overallRiskScore should usually be above 60.
        - Answer in Turkish.
        - Return ONLY valid JSON. Do not write markdown. Do not add explanations outside JSON.

        JSON format:
        {
          "overallRiskScore": 42,
          "returnRisk": "Düşük / Orta / Yüksek",
          "damageRisk": "Düşük / Orta / Yüksek",
          "material": "Ürün türü + materyal bilgisi Türkçe",
          "productCategory": "Net e-ticaret kategorisi Türkçe. Örn: Elektronik, Ev & Mutfak, Moda & Giyim, Kozmetik, Oyuncak, Kırtasiye, Canlı Ürün, Mobilya, Aksesuar, Spor & Outdoor, Genel Ürün",
          "fragilityLevel": "Düşük / Orta / Yüksek",
          "packagingRecommendation": "Kısa ve kategoriye özel Türkçe paketleme önerisi (en fazla 2 kısa cümle)",
          "aiInsights": "Satıcıya özel kısa Türkçe içgörü (en fazla 2 kısa cümle)",
          "descriptionImprovement": "İlan başlığı/açıklaması için kısa Türkçe iyileştirme önerisi (en fazla 2 kısa cümle)",
          "possibleReturnReasons": [
            "Kısa iade sebebi 1 (en fazla 8 kelime)",
            "Kısa iade sebebi 2 (en fazla 8 kelime)",
            "Kısa iade sebebi 3 (en fazla 8 kelime)"
          ],
          "generatedTitle": "Pazaryeri tarzı, aranabilir ve satışa hazır başlık (70-110 karakter)",
          "generatedDescription": "E-ticaret pazaryeri tarzı, güven veren, 250-500 karakterlik gerçekçi satış açıklaması",
          "scoreExplanation": [
            "Skoru etkileyen kısa sebep 1",
            "Skoru etkileyen kısa sebep 2",
            "Skoru etkileyen kısa sebep 3",
            "Skoru etkileyen kısa sebep 4"
          ],
          "categoryExpertise": [
            "Kategoriye özel uzman notu 1",
            "Kategoriye özel uzman notu 2",
            "Kategoriye özel uzman notu 3",
            "Kategoriye özel uzman notu 4"
          ],
          "uniqueInsights": [
            "Ürüne özel kısa içgörü 1",
            "Ürüne özel kısa içgörü 2",
            "Ürüne özel kısa içgörü 3",
            "Ürüne özel kısa içgörü 4"
          ]
        }
        """
    }

    private func cleanJSONText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func performGenerateContentRequest(body: [String: Any]) async throws -> Data {
        let modelsToTry = uniqueModels()
        var lastError: Error?

        for (index, modelName) in modelsToTry.enumerated() {
            do {
                return try await sendGenerateContentRequest(body: body, modelName: modelName)
            } catch let error as GeminiError {
                lastError = error

                if error.isTemporaryOrLimitError {
                    for delay in retryDelaysNanoseconds {
                        try? await Task.sleep(nanoseconds: delay)
                        do {
                            return try await sendGenerateContentRequest(body: body, modelName: modelName)
                        } catch let retryError as GeminiError {
                            lastError = retryError
                            if retryError.isQuotaError || retryError.isInvalidAPIKeyError {
                                break
                            }
                        } catch {
                            lastError = error
                        }
                    }
                }

                if index < modelsToTry.count - 1,
                   error.isTemporaryOrLimitError || error.isQuotaError {
                    continue
                }
            } catch {
                lastError = error
            }

            if index < modelsToTry.count - 1 {
                continue
            }
        }

        throw lastError ?? GeminiError.serviceUnavailable
    }

    private func sendGenerateContentRequest(body: [String: Any], modelName: String) async throws -> Data {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidHTTPResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Bilinmeyen Gemini API hatası"

            if httpResponse.statusCode == 429 {
                throw GeminiError.rateLimited
            }

            if [500, 502, 503, 504].contains(httpResponse.statusCode) {
                throw GeminiError.serviceUnavailable
            }

            if httpResponse.statusCode == 400,
               errorText.lowercased().contains("api key") {
                throw GeminiError.invalidAPIKey
            }

            throw GeminiError.apiError(errorText)
        }

        return data
    }

    private func uniqueModels() -> [String] {
        let candidates = [primaryModel, fallbackModel, secondFallbackModel, thirdFallbackModel]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var seen = Set<String>()
        var result: [String] = []

        for model in candidates where !seen.contains(model) {
            seen.insert(model)
            result.append(model)
        }

        return result
    }

    func recognizeProduct(image: UIImage?) async throws -> ProductRecognitionResult {
        guard let image,
              let imageData = image.jpegData(compressionQuality: 0.65) else {
            throw GeminiError.emptyResponse
        }

        let base64Image = imageData.base64EncodedString()

        let prompt = """
        You are PackWise AI Vision Recognition.

        Analyze the uploaded image as a general e-commerce product recognition step.
        The image can contain any product category: electronics, clothing, shoes, cosmetics, glassware, kitchen items, books, toys, plants, handmade goods, furniture, accessories, food packaging, or other marketplace products.

        Your goal is to identify the product before the user confirms or edits it, and also generate a marketplace-ready draft title and draft product description based on the visual evidence.

        Return ONLY valid JSON. Do not write markdown. Do not add explanations outside JSON.

        Rules:
        - Be conservative. Do not guess glass, metal, electronics, or high fragility unless visible evidence supports it.
        - If the image shows a plant or flower, material should describe it as live plant/flower, not glass or decor.
        - If the product category is uncertain, write the most likely category and make the wording cautious.
        - Fragility should be based on visible material and structure, not on generic assumptions.
        - Use Düşük fragility for durable plastic, textile, paper packaging or simple solid items unless visible evidence suggests otherwise.
        - Use Orta for items that may bend, scratch, leak, dent or have small parts.
        - Use Yüksek only for visibly breakable, glass/ceramic, live, liquid, delicate electronics, or clearly damage-sensitive products.
        - Answer in Turkish.
        - suggestedTitle must look like a real marketplace listing title, not a technical label. Use product type, visible color/material, key feature and category wording when useful.
        - suggestedDescription must be a seller-ready e-commerce marketplace description. It should be neither too short nor too long, around 250-500 characters, and mention likely use case, material/category, visible details, care or usage notes when relevant, and a short packaging/shipping confidence note.
        - Do not invent exact dimensions, weight, brand, model, warranty, medical claims, or certifications unless visible in the image.

        JSON format:
        {
          "productName": "Kısa ürün adı Türkçe",
          "material": "Tahmini materyal veya yapı Türkçe",
          "category": "E-ticaret kategorisi Türkçe",
          "fragilityLevel": "Düşük / Orta / Yüksek",
          "suggestedTitle": "Pazaryerine uygun ilan başlığı Türkçe",
          "suggestedDescription": "Pazaryerine uygun ürün açıklaması Türkçe"
        }
        """

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "response_mime_type": "application/json"
            ]
        ]

        let data = try await performGenerateContentRequest(body: body)

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw GeminiError.emptyResponse
        }

        let cleanedJSON = cleanJSONText(text)
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw GeminiError.invalidJSON
        }

        return try JSONDecoder().decode(ProductRecognitionResult.self, from: jsonData)
    }
}

enum GeminiError: LocalizedError {
    case invalidURL
    case invalidHTTPResponse
    case emptyResponse
    case invalidJSON
    case invalidAPIKey
    case rateLimited
    case serviceUnavailable
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Gemini API URL oluşturulamadı."
        case .invalidHTTPResponse:
            return "Gemini servisinden geçersiz yanıt alındı."
        case .emptyResponse:
            return "Gemini boş yanıt döndürdü."
        case .invalidJSON:
            return "Gemini yanıtı JSON formatına çevrilemedi."
        case .invalidAPIKey:
            return "Gemini API anahtarı geçersiz görünüyor."
        case .rateLimited:
            return "Gemini kullanım kotası veya istek limiti doldu. Alternatif modele geçiliyor veya biraz sonra tekrar denenebilir."
        case .serviceUnavailable:
            return "Gemini şu anda yoğun. Birkaç saniye sonra tekrar deneyebilirsin."
        case .apiError(let message):
            let lowercased = message.lowercased()
            if lowercased.contains("503") || lowercased.contains("unavailable") || lowercased.contains("high demand") {
                return "Gemini şu anda yoğun. Birkaç saniye sonra tekrar deneyebilirsin."
            }
            if lowercased.contains("429") || lowercased.contains("quota") || lowercased.contains("rate") {
                return "Gemini kullanım kotası veya istek limiti doldu. Biraz sonra tekrar deneyebilirsin."
            }
            if lowercased.contains("api key") || lowercased.contains("api_key_invalid") {
                return "Gemini API anahtarı geçersiz görünüyor."
            }
            return "Gemini analizi sırasında geçici bir sorun oluştu."
        }
    }

    var isTemporaryOrLimitError: Bool {
        switch self {
        case .serviceUnavailable, .rateLimited:
            return true
        case .apiError(let message):
            let lowercased = message.lowercased()
            return lowercased.contains("503")
                || lowercased.contains("unavailable")
                || lowercased.contains("high demand")
                || lowercased.contains("429")
                || lowercased.contains("quota")
                || lowercased.contains("rate")
        default:
            return false
        }
    }

    var isQuotaError: Bool {
        switch self {
        case .rateLimited:
            return true
        case .apiError(let message):
            let lowercased = message.lowercased()
            return lowercased.contains("429") || lowercased.contains("quota") || lowercased.contains("rate")
        default:
            return false
        }
    }

    var isInvalidAPIKeyError: Bool {
        switch self {
        case .invalidAPIKey:
            return true
        case .apiError(let message):
            let lowercased = message.lowercased()
            return lowercased.contains("api key") || lowercased.contains("api_key_invalid")
        default:
            return false
        }
    }
}

struct ProductRecognitionResult: Codable {
    let productName: String
    let material: String
    let category: String
    let fragilityLevel: String
    let suggestedTitle: String
    let suggestedDescription: String
}

struct GeminiAnalysisDTO: Codable {
    let overallRiskScore: Int
    let returnRisk: String
    let damageRisk: String
    let material: String
    let productCategory: String
    let fragilityLevel: String
    let packagingRecommendation: String
    let aiInsights: String
    let descriptionImprovement: String
    let possibleReturnReasons: [String]
    let generatedTitle: String
    let generatedDescription: String
    let scoreExplanation: [String]
    let categoryExpertise: [String]
    let uniqueInsights: [String]
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String?
}
