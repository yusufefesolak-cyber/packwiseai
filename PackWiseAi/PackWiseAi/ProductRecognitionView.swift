import SwiftUI

struct ProductRecognitionView: View {
    let productImage: UIImage?

    @Environment(\.dismiss) private var dismiss

    @State private var productName = "Analiz ediliyor..."
    @State private var material = "Analiz ediliyor..."
    @State private var category = "Analiz ediliyor..."
    @State private var fragilityLevel = "Analiz ediliyor..."
    @State private var suggestedTitle = ""
    @State private var suggestedDescription = ""
    @State private var isEditing = false
    @State private var isRecognizing = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var canRetry = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.10, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    headerSection
                    imageSection
                    recognitionCard
                    actionButtons

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
        }
        .navigationTitle("Yapay Zeka Ön Tanıma")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await recognizeProduct()
        }
        .alert("Ön Tanıma Hatası", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            if isRecognizing {
                ProgressView()
                    .tint(.green)
                    .scaleEffect(1.4)
                    .padding(.bottom, 8)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 54))
                    .foregroundStyle(.green)
            }

            Text(isRecognizing ? "Gemini Ürünü Tanıyor" : "Ürünü Tanıdım")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(isRecognizing ? "Görsel analiz ediliyor. Lütfen bekle." : "Yapay zeka ürünü analiz etti. Bilgiler doğruysa devam et, yanlışsa düzenle ve kaydet.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private var imageSection: some View {
        Group {
            if let productImage {
                Image(uiImage: productImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 230)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 180)

                    VStack(spacing: 10) {
                        Image(systemName: "photo")
                            .font(.system(size: 42))
                            .foregroundStyle(.white.opacity(0.8))

                        Text("Ürün görseli bulunamadı")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }

    private var recognitionCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Yapay Zeka Ön Analizi")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    isEditing.toggle()
                } label: {
                    Text(isEditing ? "Bitti" : "Düzenle")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.green.opacity(0.16))
                        .clipShape(Capsule())
                }
                .disabled(isRecognizing)
                .opacity(isRecognizing ? 0.45 : 1)
            }

            if isEditing {
                editableField(title: "İlan Başlığı", text: $suggestedTitle)
                editableMultilineField(title: "İlan Açıklaması", text: $suggestedDescription)
                editableField(title: "Ürün", text: $productName)
                editableField(title: "Materyal", text: $material)
                editableField(title: "Kategori", text: $category)
                editableField(title: "Kırılganlık", text: $fragilityLevel)
            } else {
                infoRow(icon: "text.badge.checkmark", title: "Önerilen Başlık", value: displayTitle)
                infoRow(icon: "doc.text.fill", title: "Önerilen Açıklama", value: displayDescription)
                infoRow(icon: "cube.fill", title: "Ürün", value: productName)
                infoRow(icon: "square.stack.3d.up.fill", title: "Materyal", value: material)
                infoRow(icon: "tag.fill", title: "Kategori", value: category)
                infoRow(icon: "exclamationmark.triangle.fill", title: "Kırılganlık", value: fragilityLevel)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            NavigationLink {
                ProductInputView(
                    initialTitle: displayTitle,
                    initialDescription: displayDescription,
                    initialImage: productImage
                )
            } label: {
                Text(isEditing ? "Düzeltmeyi Kaydet ve Devam Et" : "Doğru, Devam Et")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .disabled(isRecognizing)
            .opacity(isRecognizing ? 0.45 : 1)

            if !isEditing {
                Button {
                    isEditing = true
                } label: {
                    Text("Bilgide Yanlışlık Var")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .disabled(isRecognizing)
                .opacity(isRecognizing ? 0.45 : 1)
            } else {
                Button {
                    isEditing = false
                } label: {
                    Text("Düzenlemeyi Bitir")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }

            if canRetry {
                Button {
                    Task {
                        await retryRecognition()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                        Text("Analizi Tekrar Dene")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }

            Button {
                dismiss()
            } label: {
                Text("Tekrar Fotoğraf Seç")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }

    private var displayTitle: String {
        let trimmed = suggestedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? productName : trimmed
    }

    private var displayDescription: String {
        let trimmed = suggestedDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmed.isEmpty {
            return trimmed
        }

        return """
        Ürün: \(productName)
        Materyal: \(material)
        Kategori: \(category)
        Kırılganlık: \(fragilityLevel)
        Paketleme Notu: Ürünün kategorisine göre güvenli ve koruyucu paketleme önerilir.
        """
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                Text(value)
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func editableField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))

            TextField(title, text: text)
                .padding()
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
        }
    }

    private func editableMultilineField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))

            TextEditor(text: text)
                .frame(height: 150)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
        }
    }

    private func recognizeProduct() async {
        guard isRecognizing else { return }

        do {
            let result = try await GeminiService.shared.recognizeProduct(image: productImage)

            await MainActor.run {
                self.productName = result.productName
                self.material = result.material
                self.category = result.category
                self.fragilityLevel = result.fragilityLevel
                self.suggestedTitle = result.suggestedTitle
                self.suggestedDescription = result.suggestedDescription
                self.isRecognizing = false
                self.canRetry = false
            }
        } catch {
            await MainActor.run {
                self.productName = "Ürün tanımlanamadı"
                self.material = "Bilinmiyor"
                self.category = "Bilinmiyor"
                self.fragilityLevel = "Orta"
                self.suggestedTitle = ""
                self.suggestedDescription = ""
                self.isRecognizing = false
                self.errorMessage = friendlyErrorMessage(from: error)
                self.canRetry = true
                self.showError = true
            }
        }
    }
    

    private func retryRecognition() async {
        await MainActor.run {
            self.productName = "Analiz ediliyor..."
            self.material = "Analiz ediliyor..."
            self.category = "Analiz ediliyor..."
            self.fragilityLevel = "Analiz ediliyor..."
            self.suggestedTitle = ""
            self.suggestedDescription = ""
            self.isEditing = false
            self.isRecognizing = true
            self.showError = false
            self.errorMessage = ""
            self.canRetry = false
        }

        await recognizeProduct()
    }

    private func friendlyErrorMessage(from error: Error) -> String {
        let message = error.localizedDescription.lowercased()

        if message.contains("503") || message.contains("unavailable") || message.contains("high demand") {
            return "Gemini şu anda yoğun. Birkaç saniye sonra tekrar deneyebilirsin."
        }

        if message.contains("api key") || message.contains("invalid") {
            return "Gemini API anahtarı geçersiz görünüyor. API key bilgisini kontrol et."
        }

        if message.contains("network") || message.contains("internet") || message.contains("connection") {
            return "İnternet bağlantısı veya Gemini erişimiyle ilgili geçici bir sorun oluştu."
        }

        return "Ön tanıma sırasında geçici bir sorun oluştu. Tekrar deneyebilirsin."
    }
}

#Preview {
    NavigationStack {
        ProductRecognitionView(productImage: nil)
    }
}
